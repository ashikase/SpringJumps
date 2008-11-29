/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2008-11-29 10:35:01
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
- (void)sj_unscatter:(BOOL)unscatter startTime:(double)startTime;
- (void)sj_clickedIcon:(SBIcon *)icon;
- (void)sj_updateCurrentIconListIndexUpdatingPageIndicator:(BOOL)update;
- (void)sj_updateCurrentIconListIndex;
@end

#define MAX_DOCK_ICONS 5
#define MAX_PAGES 9
#define SHORTCUT_PREFIX "jp.ashikase.springjumps"


static SBIconModel *iconModel = nil;

static NSString *pageNames[MAX_PAGES] = {nil};
static NSArray *offscreenDockIcons = nil;

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
                pageNames[i] = [[icon displayName] copy];
        }

        // Restore any previously saved list of off-screen Dock icons
        NSMutableArray *iconArray = [[NSMutableArray alloc] initWithCapacity:MAX_DOCK_ICONS];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dict = [defaults objectForKey:@"springJumpsOffscreenDockIcons"];
        NSArray *row = [[dict objectForKey:@"iconMatrix"] objectAtIndex:0];
        for (id iconInfo in row) {
            // NOTE: empty slots are represented by NSNumber 0
            if ([iconInfo isKindOfClass:[NSDictionary class]]) {
                NSString *identifier = [iconInfo objectForKey:@"displayIdentifier"];
                SBIcon *icon = [iconModel iconForDisplayIdentifier:identifier];
                if (icon) [iconArray addObject:icon];
            }
        }

        offscreenDockIcons = iconArray;
    }
    return self;
}

static void $SBIconController$dealloc(SBIconController *self, SEL sel)
{
    [offscreenDockIcons release];
    [self sj_dealloc];
}

static void $SBIconController$unscatter$startTime$(SBIconController *self, SEL sel, BOOL unscatter, double startTime)
{
    static BOOL isFirstTime = YES;
    if (isFirstTime) {
        if ([offscreenDockIcons count] != 0) {
            [UIView disableAnimation];

            for (SBIcon *dockIcon in offscreenDockIcons) {
                SBIconList *page = [iconModel iconListContainingIcon:dockIcon];
                if (page && ![page isDock])
                    [page removeIcon:dockIcon compactEmptyLists:NO animate:NO];
            }
            [iconModel compactIconLists];
            [iconModel saveIconState];

            [UIView enableAnimation];
        }

        isFirstTime = NO;
    }

    [self sj_unscatter:unscatter startTime:startTime];
}

static void $SBIconController$clickedIcon$(SBIconController *self, SEL sel, SBIcon *icon)
{
    NSString *ident = [icon displayIdentifier];
    if ([ident hasPrefix:@SHORTCUT_PREFIX]) {
        // Use identifier with format: SHORTCUT_PREFIX.pagenumber
        // (e.g. com.pagecuts.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] != 4) return;
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
            SBButtonBar *dock = [iconModel buttonBar];
            if ([dock containsIcon:icon]) {
                // Icon is in dock; Toggle the dock
                NSDictionary *prevRepresentation = [dock dictionaryRepresentation];

                // NOTE: no need to copy; tests show the list creates a new array
                NSArray *prevIcons = [[dock icons] retain];
                [dock removeAllIcons];

                if ([offscreenDockIcons count] != 0) {
                    // Restore saved state
                    int i = 0;
                    for (SBIcon *dockIcon in offscreenDockIcons)
                        [dock placeIcon:dockIcon atX:i++ Y:0 animate:NO moveNow:YES];
                } else {
                    // Toggled dock must always contain the page-0 icon for toggling
                    [dock placeIcon:icon atX:0 Y:0 animate:NO moveNow:YES];
                }
                [dock layoutIconsNow];

                // Store list of off-screen dock icons
                [offscreenDockIcons release];
                offscreenDockIcons = prevIcons;

                // Save state of pages
                [iconModel saveIconState];

                // Also save list of off-screen icons to SpringBoard's preferences
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:prevRepresentation forKey:@"springJumpsOffscreenDockIcons"];
                [defaults synchronize];
            }
        }
    } else {
        // Regular application icon
        [self sj_clickedIcon:icon];
    }
}

// NOTE: The following method is for firmware 2.0.x
static void $SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$(SBIconController *self, SEL sel, BOOL update)
{
    [self sj_updateCurrentIconListIndexUpdatingPageIndicator:update];

    // Update page title-bar
    Ivar ivar = class_getInstanceVariable([self class], "_currentIconListIndex");
    int *_currentIconListIndex = (int *)((char *)self + ivar_getOffset(ivar));

    [self setIdleModeText:pageNames[*_currentIconListIndex]];
}

// NOTE: The following method is for firmware 2.1+
static void $SBIconController$updateCurrentIconListIndex(SBIconController *self, SEL sel)
{
    [self sj_updateCurrentIconListIndex];

    // Update page title-bar
    Ivar ivar = class_getInstanceVariable([self class], "_currentIconListIndex");
    int *_currentIconListIndex = (int *)((char *)self + ivar_getOffset(ivar));

    [self setIdleModeText:pageNames[*_currentIconListIndex]];
}

//______________________________________________________________________________
//______________________________________________________________________________

extern "C" void SpringJumpsInitialize()
{
    if (objc_getClass("SpringBoard") == nil)
        return;

    Class $SBIconController(objc_getClass("SBIconController"));
    MSHookMessage($SBIconController, @selector(init), (IMP) &$SBIconController$init, "sj_");
    MSHookMessage($SBIconController, @selector(dealloc), (IMP) &$SBIconController$dealloc, "sj_");
    MSHookMessage($SBIconController, @selector(clickedIcon:), (IMP) &$SBIconController$clickedIcon$, "sj_");
    MSHookMessage($SBIconController, @selector(unscatter:startTime:), (IMP) &$SBIconController$unscatter$startTime$, "sj_");

    if ([$SBIconController respondsToSelector:@selector(updateCurrentIconListIndex)])
        MSHookMessage($SBIconController, @selector(updateCurrentIconListIndex),
                (IMP) &$SBIconController$updateCurrentIconListIndex, "sj_");
    else
        MSHookMessage($SBIconController, @selector(updateCurrentIconListIndexUpdatingPageIndicator:),
                (IMP) &$SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$, "sj_");
}
