/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2008-12-20 00:35:25
 */

/**
 * Copyright (C) 2008  Lance Fetters (aka. ashikase)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */


#include <substrate.h>

#import <CoreFoundation/CFPreferences.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>

#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBIconModel.h>

#define APP_ID "jp.ashikase.springjumps"

#define MAX_PAGES 9


static BOOL showPageTitles = YES;
static BOOL shortcutStates[MAX_PAGES];
static NSString *shortcutNames[MAX_PAGES] = {nil};

// NOTE: This variable is used to prevent multiple title updates on page scroll
static int currentPage = 0;

//______________________________________________________________________________
//______________________________________________________________________________

static void loadPreferences()
{
    // Register default values
    // NOTE: This is only necessary for the shortcut enabled states
    for (int i = 0; i < MAX_PAGES; i++)
        shortcutStates[i] = YES;

    // Load preferences from preferences file (if it exists)
    Boolean valid;
    Boolean flag = CFPreferencesGetAppBooleanValue(CFSTR("showPageTitles"), CFSTR(APP_ID), &valid);
    if (valid)
        showPageTitles = flag;

    CFPropertyListRef array = CFPreferencesCopyAppValue(CFSTR("shortcuts"), CFSTR(APP_ID));
    if (array) {
        for (int i = 0; i < MAX_PAGES; i++) {
            NSDictionary *dict = [(NSArray *)array objectAtIndex:i];
            if (dict) {
                id obj = [dict objectForKey:@"enabled"];
                if ([obj isKindOfClass:[NSNumber class]])
                    shortcutStates[i] = [obj boolValue];
                obj = [dict objectForKey:@"name"];
                if ([obj isKindOfClass:[NSString class]])
                    shortcutNames[i] = [obj copy];
            }
        }

        CFRelease(array);
    }
}

//______________________________________________________________________________
//______________________________________________________________________________

static IMP _SBIconModel$init = nil;
static id $SBIconModel$init(SBIconModel *self, SEL sel)
{
    loadPreferences();
    self = _SBIconModel$init(self, sel);
    if (self) {
        for (int i = 0; i < MAX_PAGES; i++) {
            SBApplicationIcon *icon = [self iconForDisplayIdentifier:
                [NSString stringWithFormat:@APP_ID".%d", i]];
            if (icon) {
                // If shortcut is disabled, hide the icon
                if (shortcutStates[i] == NO) {
                    NSMutableArray *tags = [NSMutableArray arrayWithArray:[[icon application] tags]];
                    [tags addObject:@"hidden"];
                    [[icon application] setTags:tags];
                }

                // NOTE: In case the preferences file is missing or corrupt, take
                //       shorcut names from the shorcut folders' Info.plist files
                if (shortcutNames[i] == nil)
                    shortcutNames[i] = [[icon displayName] copy];
            }
        }
    }
    return self;
}

static IMP _SBIconModel$dealloc = nil;
static void $SBIconModel$dealloc(SBIconModel *self, SEL sel)
{
    for (int i = 0; i < MAX_PAGES; i++)
        [shortcutNames[i] release];
    _SBIconModel$dealloc(self, sel);
}

//______________________________________________________________________________
//______________________________________________________________________________

static IMP _SBIconController$clickedIcon$ = nil;
static void $SBIconController$clickedIcon$(SBIconController *self, SEL sel, SBIcon *icon)
{
    NSString *ident = [icon displayIdentifier];
    if ([ident hasPrefix:@APP_ID]) {
        // Use identifier with format: APP_ID.pagenumber
        // (e.g. jp.ashikase.springjumps.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] != 4)
            // SpringJumps preferences application
            _SBIconController$clickedIcon$(self, sel, icon);
        int pageNumber = [[parts objectAtIndex:3] intValue];

        // Get the current page index
        int currentIndex;
        object_getInstanceVariable(self, "_currentIconListIndex",
            reinterpret_cast<void **>(&currentIndex));

        Class $SBIconModel(objc_getClass("SBIconModel"));
        SBIconModel *iconModel = [$SBIconModel sharedInstance];
        if ((pageNumber != currentIndex) &&
                (pageNumber < (int)[[iconModel iconLists] count])) {
            // Switch to requested page
            [self scrollToIconListAtIndex:pageNumber animate:NO];
        }
    } else {
        // Regular application icon
        _SBIconController$clickedIcon$(self, sel, icon);
    }
}

static void updatePageTitle()
{
    Class $SBIconController(objc_getClass("SBIconController"));
    SBIconController *iconController = [$SBIconController sharedInstance];

    if (iconController) {
        Ivar ivar = class_getInstanceVariable($SBIconController, "_currentColumnIndex");
        int *_currentColumnIndex = (int *)((char *)iconController + ivar_getOffset(ivar));

        if (*_currentColumnIndex == 0) {
            // NOTE: The column index denotes which column of icons is currently
            //       furthest to the left of the screen
            ivar = class_getInstanceVariable($SBIconController, "_currentIconListIndex");
            int *_currentIconListIndex = (int *)((char *)iconController + ivar_getOffset(ivar));

            if (currentPage != *_currentIconListIndex) {
                // Update page title-bar
                if (shortcutStates[*_currentIconListIndex])
                    [iconController setIdleModeText:shortcutNames[*_currentIconListIndex]];
                else
                    [iconController setIdleModeText:nil];

                // Store the current page index
                currentPage = *_currentIconListIndex;
            }
        }
    }
}

// NOTE: The following method is for firmware 2.0.x
static IMP _SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$ = nil;
static void $SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$(SBIconController *self, SEL sel, BOOL update)
{
    _SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$(self, sel, update);
    if (showPageTitles)
        updatePageTitle();
}

// NOTE: The following method is for firmware 2.1+
static IMP _SBIconController$updateCurrentIconListIndex = nil;
static void $SBIconController$updateCurrentIconListIndex(SBIconController *self, SEL sel)
{
    _SBIconController$updateCurrentIconListIndex(self, sel);
    if (showPageTitles)
        updatePageTitle();
}

//______________________________________________________________________________
//______________________________________________________________________________

static IMP _SBApplicationIcon$displayName = nil;
static NSString * $SBApplicationIcon$displayName(SBApplicationIcon *self, SEL sel)
{
    NSString *ident = [self displayIdentifier];
    if ([ident hasPrefix:@APP_ID]) {
        // Use identifier with format: APP_ID.pagenumber
        // (e.g. jp.ashikase.springjumps.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] == 4) {
            int pageNumber = [[parts objectAtIndex:3] intValue];
            if (shortcutNames[pageNumber])
                return shortcutNames[pageNumber];
        }
    }

    return _SBApplicationIcon$displayName(self, sel);
}

//______________________________________________________________________________
//______________________________________________________________________________

extern "C" void SpringJumpsInitialize()
{
    if (objc_getClass("SpringBoard") == nil)
        return;

    // Setup hooks
    Class $SBIconModel(objc_getClass("SBIconModel"));
    _SBIconModel$init =
        MSHookMessage($SBIconModel, @selector(init), (IMP) &$SBIconModel$init, NULL);
    _SBIconModel$dealloc =
        MSHookMessage($SBIconModel, @selector(dealloc), (IMP) &$SBIconModel$dealloc, NULL);

    Class $SBIconController(objc_getClass("SBIconController"));
    _SBIconController$clickedIcon$ =
        MSHookMessage($SBIconController, @selector(clickedIcon:), (IMP) &$SBIconController$clickedIcon$, NULL);

    if (class_getInstanceMethod($SBIconController, @selector(updateCurrentIconListIndex)))
        _SBIconController$updateCurrentIconListIndex = 
            MSHookMessage($SBIconController, @selector(updateCurrentIconListIndex),
                    (IMP) &$SBIconController$updateCurrentIconListIndex, NULL);
    else
        _SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$ = 
            MSHookMessage($SBIconController, @selector(updateCurrentIconListIndexUpdatingPageIndicator:),
                    (IMP) &$SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$, NULL);

    Class $SBApplicationIcon(objc_getClass("SBApplicationIcon"));
    _SBApplicationIcon$displayName =
        MSHookMessage($SBApplicationIcon, @selector(displayName), (IMP) &$SBApplicationIcon$displayName, NULL);

}
