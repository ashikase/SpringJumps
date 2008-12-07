/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2008-12-07 21:23:49
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

#define MAX_DOCK_ICONS 5
#define MAX_PAGES 9


static BOOL showPageTitles = YES;
static BOOL shortcutStates[MAX_PAGES] = {nil};
static NSString *shortcutNames[MAX_PAGES] = {nil};

//______________________________________________________________________________
//______________________________________________________________________________

static void loadPreferences()
{
    // NOTE: It appears that preferences are cached; must sync to refresh
    CFPreferencesAppSynchronize(CFSTR(APP_ID));

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

@interface SBIconModel (SpringJumps)
- (id)sjmp_init;
- (void)sjmp_dealloc;
@end

static id $SBIconModel$init(SBIconModel *self, SEL sel)
{
    loadPreferences();
    self = [self sjmp_init];
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

static void $SBIconModel$dealloc(SBIconModel *self, SEL sel)
{
    for (int i = 0; i < MAX_PAGES; i++)
        [shortcutNames[i] release];
    [self sjmp_dealloc];
}

//______________________________________________________________________________
//______________________________________________________________________________

@interface SBIconController (SpringJumps)
- (void)sjmp_clickedIcon:(SBIcon *)icon;
- (void)sjmp_updateCurrentIconListIndexUpdatingPageIndicator:(BOOL)update;
- (void)sjmp_updateCurrentIconListIndex;
@end

static void $SBIconController$clickedIcon$(SBIconController *self, SEL sel, SBIcon *icon)
{
    NSString *ident = [icon displayIdentifier];
    if ([ident hasPrefix:@APP_ID]) {
        // Use identifier with format: APP_ID.pagenumber
        // (e.g. jp.ashikase.springjumps.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] != 4)
            // SpringJumps preferences application
            return [self sjmp_clickedIcon:icon];
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
        } else if (pageNumber == 0) {
            // Tapped page 0 icon while on page 0 screen
            // FIXME: this is for multiDock; attempt to find a better method
            //        (for example, an option to "pass-through" icon clicks)
            [self sjmp_clickedIcon:icon];
        }
    } else {
        // Regular application icon
        [self sjmp_clickedIcon:icon];
    }
}

static void updatePageTitle()
{
    Class $SBIconController(objc_getClass("SBIconController"));
    SBIconController *iconController = [$SBIconController sharedInstance];

    if (iconController) {
        // Update page title-bar
        Ivar ivar = class_getInstanceVariable($SBIconController, "_currentIconListIndex");
        int *_currentIconListIndex = (int *)((char *)iconController + ivar_getOffset(ivar));

        if (shortcutStates[*_currentIconListIndex])
            [iconController setIdleModeText:shortcutNames[*_currentIconListIndex]];
        else
            [iconController setIdleModeText:nil];
    }
}

// NOTE: The following method is for firmware 2.0.x
static void $SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$(SBIconController *self, SEL sel, BOOL update)
{
    [self sjmp_updateCurrentIconListIndexUpdatingPageIndicator:update];
    if (showPageTitles)
        updatePageTitle();
}

// NOTE: The following method is for firmware 2.1+
static void $SBIconController$updateCurrentIconListIndex(SBIconController *self, SEL sel)
{
    [self sjmp_updateCurrentIconListIndex];
    if (showPageTitles)
        updatePageTitle();
}

//______________________________________________________________________________
//______________________________________________________________________________

@interface SBApplicationIcon (SpringJumps)
- (NSString *)sjmp_displayName;
@end

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

    return [self sjmp_displayName];
}

//______________________________________________________________________________
//______________________________________________________________________________

extern "C" void SpringJumpsInitialize()
{
    if (objc_getClass("SpringBoard") == nil)
        return;

    // Setup hooks
    Class $SBIconModel(objc_getClass("SBIconModel"));
    MSHookMessage($SBIconModel, @selector(init), (IMP) &$SBIconModel$init, "sjmp_");
    MSHookMessage($SBIconModel, @selector(dealloc), (IMP) &$SBIconModel$dealloc, "sjmp_");

    Class $SBIconController(objc_getClass("SBIconController"));
    MSHookMessage($SBIconController, @selector(clickedIcon:), (IMP) &$SBIconController$clickedIcon$, "sjmp_");

    if (class_getInstanceMethod($SBIconController, @selector(updateCurrentIconListIndex)))
        MSHookMessage($SBIconController, @selector(updateCurrentIconListIndex),
                (IMP) &$SBIconController$updateCurrentIconListIndex, "sjmp_");
    else
        MSHookMessage($SBIconController, @selector(updateCurrentIconListIndexUpdatingPageIndicator:),
                (IMP) &$SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$, "sjmp_");

    Class $SBApplicationIcon(objc_getClass("SBApplicationIcon"));
    MSHookMessage($SBApplicationIcon, @selector(displayName), (IMP) &$SBApplicationIcon$displayName, "sjmp_");

}
