/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2008-12-06 18:26:13
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

#import <CoreGraphics/CGGeometry.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBIconModel.h>

#import <UIKit/UIView-Animation.h>

@interface SBIconController (SpringJumps)
- (id)sj_init;
- (void)sj_dealloc;
- (void)sj_clickedIcon:(SBIcon *)icon;
- (void)sj_updateCurrentIconListIndexUpdatingPageIndicator:(BOOL)update;
- (void)sj_updateCurrentIconListIndex;
@end

#define MAX_DOCK_ICONS 5
#define MAX_PAGES 9
#define SHORTCUT_PREFIX "jp.ashikase.springjumps"


static SBIconModel *iconModel = nil;

static BOOL showPageTitles = YES;
static NSString *shortcutNames[MAX_PAGES] = {nil};

static id $SBIconController$init(SBIconController *self, SEL sel)
{
    self = [self sj_init];
    if (self) {
        Class $SBIconModel(objc_getClass("SBIconModel"));
        iconModel = [$SBIconModel sharedInstance];

        // Load and cache page names
        for (int i = 0; i < MAX_PAGES; i++) {
            SBIcon *icon = [iconModel iconForDisplayIdentifier:
                [NSString stringWithFormat:@SHORTCUT_PREFIX".%d", i]];
            if (icon)
                shortcutNames[i] = [[icon displayName] copy];
        }
    }
    return self;
}

static void $SBIconController$dealloc(SBIconController *self, SEL sel)
{
    for (int i = 0; i < MAX_PAGES; i++)
        [shortcutNames[i] release];
    [self sj_dealloc];
}

static void $SBIconController$clickedIcon$(SBIconController *self, SEL sel, SBIcon *icon)
{
    NSString *ident = [icon displayIdentifier];
    if ([ident hasPrefix:@SHORTCUT_PREFIX]) {
        // Use identifier with format: SHORTCUT_PREFIX.pagenumber
        // (e.g. jp.ashikase.springjumps.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] != 4)
            // SpringJumps preferences application
            return [self sj_clickedIcon:icon];
        int pageNumber = [[parts objectAtIndex:3] intValue];

        // Get the current page index
        int currentIndex;
        object_getInstanceVariable(self, "_currentIconListIndex",
            reinterpret_cast<void **>(&currentIndex));

        if ((pageNumber != currentIndex) &&
                (pageNumber < (int)[[iconModel iconLists] count])) {
            // Switch to requested page
            [self scrollToIconListAtIndex:pageNumber animate:NO];
        } else if (pageNumber == 0) {
            // Tapped page 0 icon while on page 0 screen
            // FIXME: this is for multiDock; attempt to find a better method
            //        (for example, an option to "pass-through" icon clicks)
            [self sj_clickedIcon:icon];
        }
    } else {
        // Regular application icon
        [self sj_clickedIcon:icon];
    }
}

static void setPageTitlesEnabled(BOOL enabled)
{
    Class $SBIconController(objc_getClass("SBIconController"));
    SBIconController *iconController = [$SBIconController sharedInstance];

    if (iconController) {
        if (enabled) {
            // Update page title-bar
            Ivar ivar = class_getInstanceVariable($SBIconController, "_currentIconListIndex");
            int *_currentIconListIndex = (int *)((char *)iconController + ivar_getOffset(ivar));

            [iconController setIdleModeText:shortcutNames[*_currentIconListIndex]];
        } else {
            [iconController setIdleModeText:nil];
        }
    }
}

// NOTE: The following method is for firmware 2.0.x
static void $SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$(SBIconController *self, SEL sel, BOOL update)
{
    [self sj_updateCurrentIconListIndexUpdatingPageIndicator:update];
    setPageTitlesEnabled(showPageTitles);
}

// NOTE: The following method is for firmware 2.1+
static void $SBIconController$updateCurrentIconListIndex(SBIconController *self, SEL sel)
{
    [self sj_updateCurrentIconListIndex];
    setPageTitlesEnabled(showPageTitles);
}

//______________________________________________________________________________
//______________________________________________________________________________

@interface SBApplicationIcon (SpringJumps)
- (NSString *)sj_displayName;
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

    return [self sj_displayName];
}

//______________________________________________________________________________
//______________________________________________________________________________

extern "C" void SpringJumpsInitialize()
{
    if (objc_getClass("SpringBoard") == nil)
        return;

    // Setup hooks
    Class $SBIconController(objc_getClass("SBIconController"));
    MSHookMessage($SBIconController, @selector(init), (IMP) &$SBIconController$init, "sj_");
    MSHookMessage($SBIconController, @selector(dealloc), (IMP) &$SBIconController$dealloc, "sj_");
    MSHookMessage($SBIconController, @selector(clickedIcon:), (IMP) &$SBIconController$clickedIcon$, "sj_");

    if (class_getInstanceMethod($SBIconController, @selector(updateCurrentIconListIndex)))
        MSHookMessage($SBIconController, @selector(updateCurrentIconListIndex),
                (IMP) &$SBIconController$updateCurrentIconListIndex, "sj_");
    else
        MSHookMessage($SBIconController, @selector(updateCurrentIconListIndexUpdatingPageIndicator:),
                (IMP) &$SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$, "sj_");

    Class $SBApplicationIcon(objc_getClass("SBApplicationIcon"));
    MSHookMessage($SBApplicationIcon, @selector(displayName), (IMP) &$SBApplicationIcon$displayName, "sj_");

}
