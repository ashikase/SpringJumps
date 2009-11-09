/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2009-09-07 00:39:52
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


#import "Common.h"

#import <CoreFoundation/CFPreferences.h>

#import <GraphicsServices/GraphicsServices.h>
extern "C" GSEventRecord * _GSEventGetGSEventRecord(struct __GSEvent *);

#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBIconModel.h>
//#import <SpringBoard/SBTouchPageIndicator.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SpringBoard.h>

#import "Dock.h"


static BOOL showPageTitles = YES;
static BOOL shortcutStates[MAX_PAGES];
static NSString *shortcutNames[MAX_PAGES] = {nil};

// NOTE: This variable is used to prevent multiple title updates on page scroll
static int currentPage = -1;

static BOOL jumpDockIsEnabled = NO;
static SpringJumpsDock *jumpDock = nil;

//______________________________________________________________________________
//______________________________________________________________________________

static void dismissJumpDock()
{
    [jumpDock removeFromSuperview];
    [jumpDock release];
    jumpDock = nil;
}

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

HOOK(SBIconModel, init, id)
{
    loadPreferences();
    self = CALL_ORIG(SBIconModel, init);
    if (self) {
        for (int i = 0; i < MAX_PAGES; i++) {
            SBApplicationIcon *icon = [self iconForDisplayIdentifier:
                [NSString stringWithFormat:@APP_ID".%d", i]];
            if (icon) {
                // If shortcut is disabled, hide the icon
                if (jumpDockIsEnabled || shortcutStates[i] == NO) {
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

HOOK(SBIconModel, dealloc, void)
{
    for (int i = 0; i < MAX_PAGES; i++)
        [shortcutNames[i] release];
    CALL_ORIG(SBIconModel, dealloc);
}

//______________________________________________________________________________
//______________________________________________________________________________

HOOK(SBIconController, clickedIcon$, void, SBIcon *icon)
{
    // If the jump dock is enabled, destroy it
    // NOTE: This code is safe to use even if jump dock is not enabled.
    dismissJumpDock();

    NSString *ident = [icon displayIdentifier];
    if ([ident hasPrefix:@APP_ID]) {
        // Use identifier with format: APP_ID.pagenumber
        // (e.g. jp.ashikase.springjumps.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] == 4) {
            int pageNumber = [[parts objectAtIndex:3] intValue];

            // Get the current page index
            int _currentIconListIndex = MSHookIvar<int>(self, "_currentIconListIndex");

            Class $SBIconModel(objc_getClass("SBIconModel"));
            SBIconModel *iconModel = [$SBIconModel sharedInstance];
            if ((pageNumber != _currentIconListIndex) &&
                    (pageNumber < (int)[[iconModel iconLists] count])) {
                // Switch to requested page
                [self scrollToIconListAtIndex:pageNumber animate:NO];
            }
            return;
        }
        // Fall-through
    }

    // Regular application icon or SpringJumps settings app
    CALL_ORIG(SBIconController, clickedIcon$, icon);
}

// NOTE: It would be more efficient to have this function called via
//       SBTouchPageIndicator::setCurrentPage:(int); however, the page title
//       would not be updated until scrolling has stopped (and thus titles of
//       "in-between" pages would not be shown).
static void updatePageTitle()
{
    Class $SBIconController(objc_getClass("SBIconController"));
    SBIconController *iconController = [$SBIconController sharedInstance];

    if (iconController) {
        // NOTE: The column index denotes which column of icons is currently
        //       furthest to the left of the screen
        int &_currentColumnIndex = MSHookIvar<int>(iconController, "_currentColumnIndex");

        if (&_currentColumnIndex == NULL || _currentColumnIndex == 0) {
            int _currentIconListIndex = MSHookIvar<int>(iconController, "_currentIconListIndex");

            if (currentPage != _currentIconListIndex) {
                // Update page title-bar
                if (jumpDockIsEnabled || shortcutStates[_currentIconListIndex])
                    [iconController setIdleModeText:shortcutNames[_currentIconListIndex]];
                else
                    [iconController setIdleModeText:nil];

                // Store the current page index
                currentPage = _currentIconListIndex;
            }
        }
    }
}

// NOTE: The following method is for firmware 2.0.x
HOOK(SBIconController, updateCurrentIconListIndexUpdatingPageIndicator$, void, BOOL update)
{
    CALL_ORIG(SBIconController, updateCurrentIconListIndexUpdatingPageIndicator$, update);
    if (showPageTitles)
        updatePageTitle();
}

// NOTE: The following method is for firmware 2.1+
HOOK(SBIconController, updateCurrentIconListIndex, void)
{
    CALL_ORIG(SBIconController, updateCurrentIconListIndex);
    if (showPageTitles)
        updatePageTitle();
}

//______________________________________________________________________________
//______________________________________________________________________________

HOOK(SBApplicationIcon, displayName, NSString *)
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

    return CALL_ORIG(SBApplicationIcon, displayName);
}

HOOK(SBApplicationIcon, mouseDown$, void, struct __GSEvent *event)
{
    CALL_ORIG(SBApplicationIcon, mouseDown$, event);
    NSString *ident = [self displayIdentifier];
    if ([ident hasPrefix:@APP_ID]) {
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] == 4) {
            // Is a shortcut icon; disallow grabbing
            [self cancelGrabTimer];
        }
    }
}

//______________________________________________________________________________
//______________________________________________________________________________

#if 0
HOOK(SBTouchPageIndicator, mouseDown$, void, struct __GSEvent *event)
{
    GSEventRecord *record = _GSEventGetGSEventRecord(event);
    if (record) {
        CGRect frame = [self frame];
        CGSize size = [self sizeForNumberOfPages:[self numberOfPages]];
        float originX = frame.origin.x + ((frame.size.width - size.width) / 2.0f);
        if (record->locationInWindow.x >= originX
                && record->locationInWindow.x < originX + size.width) {
            Class $SBUIController = objc_getClass("SBUIController");
            SBUIController *uiCont = [$SBUIController sharedInstance];
            UIWindow *window = [uiCont window];
            UIView *dock = MSHookIvar<UIView *>(uiCont, "_buttonBarContainerView");

            if (!jumpDock) {
                jumpDock = [[SpringJumpsDock alloc] initWithDefaultSize];
                CGRect frame = [jumpDock frame];
                frame.origin.y =
                    [[UIScreen mainScreen] bounds].size.height - [dock frame].size.height - frame.size.height;
                [jumpDock setFrame:frame];
                [window addSubview:jumpDock];
            }
            return;
        }
    }

    CALL_ORIG(SBTouchPageIndicator, mouseDown$, event);
}

HOOK(SBTouchPageIndicator, mouseUp$, void, struct __GSEvent *event)
{
    if (jumpDock) {
        // FIXME: Is there a simpler way to do this? (Slide to tap)
        GSEventRecord *record = _GSEventGetGSEventRecord(event);
        if (record) {
            id obj = [jumpDock hitTest:CGPointMake(record->locationInWindow.x,
                record->locationInWindow.y - [jumpDock frame].origin.y) forEvent:event];
            Class $SBApplicationIcon(objc_getClass("SBApplicationIcon"));
            if ([obj isMemberOfClass:$SBApplicationIcon]) {
                SBApplicationIcon *icon = obj;
                [icon mouseDown:event];
                [icon mouseUp:event];
            }
        }
    } else {
        CALL_ORIG(SBTouchPageIndicator, mouseUp$, event);
    }
}
#endif

//______________________________________________________________________________
//______________________________________________________________________________

HOOK(SpringBoard, lockButtonUp$, void, struct __GSEvent *event)
{
    CALL_ORIG(SpringBoard, lockButtonUp$, event);

    // If the jump dock is enabled, destroy it
    // NOTE: This code is safe to use even if jump dock is not enabled.
    dismissJumpDock();
}

HOOK(SpringBoard, menuButtonUp$, void, struct __GSEvent *event)
{
    CALL_ORIG(SpringBoard, menuButtonUp$, event);

    // If the jump dock is enabled, destroy it
    // NOTE: This code is safe to use even if jump dock is not enabled.
    dismissJumpDock();
}

//______________________________________________________________________________
//______________________________________________________________________________

extern "C" void SpringJumpsInitialize()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // NOTE: This library should only be loaded for SpringBoard
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    if (![identifier isEqualToString:@"com.apple.springboard"])
        return;

    // Setup hooks
    Class $SBIconModel(objc_getClass("SBIconModel"));
    LOAD_HOOK($SBIconModel, @selector(init), SBIconModel$init);
    LOAD_HOOK($SBIconModel, @selector(dealloc), SBIconModel$dealloc);

    Class $SBIconController(objc_getClass("SBIconController"));
    LOAD_HOOK($SBIconController, @selector(clickedIcon:), SBIconController$clickedIcon$);

    if (class_getInstanceMethod($SBIconController, @selector(updateCurrentIconListIndex)))
        LOAD_HOOK($SBIconController, @selector(updateCurrentIconListIndex),
                SBIconController$updateCurrentIconListIndex);
    else
        LOAD_HOOK($SBIconController, @selector(updateCurrentIconListIndexUpdatingPageIndicator:),
            SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$);

    Class $SBApplicationIcon(objc_getClass("SBApplicationIcon"));
    LOAD_HOOK($SBApplicationIcon, @selector(displayName), SBApplicationIcon$displayName);

    // FIXME: Need to rethink where and when preferences are loaded
    Boolean valid;
    Boolean flag = CFPreferencesGetAppBooleanValue(CFSTR("enableJumpDock"), CFSTR(APP_ID), &valid);
    if (valid)
        jumpDockIsEnabled = flag;

    if (jumpDockIsEnabled) {
        LOAD_HOOK($SBApplicationIcon, @selector(mouseDown:), SBApplicationIcon$mouseDown$);

#if 0
        Class $SBTouchPageIndicator = objc_getClass("SBTouchPageIndicator");
        LOAD_HOOK($SBTouchPageIndicator, @selector(mouseDown:), SBTouchPageIndicator$mouseDown$);
        LOAD_HOOK($SBTouchPageIndicator, @selector(mouseUp:), SBTouchPageIndicator$mouseUp$);
#endif

        Class $SpringBoard(objc_getClass("SpringBoard"));
        LOAD_HOOK($SpringBoard, @selector(lockButtonUp:), SpringBoard$lockButtonUp$);
        LOAD_HOOK($SpringBoard, @selector(menuButtonUp:), SpringBoard$menuButtonUp$);
    }

    [pool release];
}

/* vim: set syntax=objcpp sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
