/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2009-01-18 22:00:38
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


#import "Dock.h"

#import "Common.h"

#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBIconModel.h>

#define MARGIN_HORIZ_ROW_1 4.0f
#define MARGIN_HORIZ_ROW_2 17.0f
#define MARGIN_VERT 10.0f

#define PADDING_LEFT 4.0f
#define PADDING_TOP 12.0f
#define PADDING_BOTTOM 4.0f


@implementation SpringJumpsDock

- (id)initWithDefaultSize
{
    self = [super init];
    if (self) {
        // Ensure that the background is transparent
        [self setBackgroundColor:[UIColor clearColor]];

        // Adjust the size to fit two rows of icons
        Class $SBApplicationIcon = objc_getClass("SBApplicationIcon");
        CGSize iconSize = [$SBApplicationIcon defaultIconSize];
        [self setFrame:CGRectMake(0, 0, 320.0f,
            PADDING_TOP + MARGIN_VERT + (iconSize.height * 2.0f) + PADDING_BOTTOM)];

        // Add a background image
        UIImage *image = [UIImage imageWithContentsOfFile:
            [NSString stringWithFormat:@"%@/SpringJumpsDockBackground.png",
            [[NSBundle bundleWithIdentifier:@APP_ID] bundlePath]]];
        if (image) {
            UIImageView * imageView = [[UIImageView alloc] initWithImage:image];
            [imageView setFrame:[self frame]];
            [self addSubview:imageView];
            [imageView release];
        }

        // Add the shortcut icons
        Class $SBIconModel = objc_getClass("SBIconModel");
        SBIconModel *iconModel = [$SBIconModel sharedInstance];
        if (iconModel) {
            for (int i = 0; i < MAX_PAGES; i++) {
                SBApplicationIcon *icon = [iconModel iconForDisplayIdentifier:
                    [NSString stringWithFormat:@APP_ID".%d", i]];
                if (icon) {
                    [icon setShowsImages:YES];
                    [icon setAllowJitter:NO];
                    float x, y;
                    if (i == 0) {
                        // Jump 0
                        x = ([self frame].size.width - iconSize.width) / 2.0f;
                        y = ([self frame].size.height - iconSize.height) / 2.0f;
                    } else if (i < 3) {
                        // Jump 1 & 2
                        x = PADDING_LEFT + ((i - 1) * (iconSize.width + MARGIN_HORIZ_ROW_1));
                        y = PADDING_TOP;
                    } else if (i < 5) {
                        // Jump 3 & 4
                        x = PADDING_LEFT + ((i - 3) * (iconSize.width + MARGIN_HORIZ_ROW_1));
                        y = PADDING_TOP + iconSize.height + MARGIN_VERT;
                    } else if (i < 7) {
                        // Jump 5 & 6
                        x = PADDING_LEFT + ((i - 2) * (iconSize.width + MARGIN_HORIZ_ROW_1));
                        y = PADDING_TOP;
                    } else {
                        // Jump 7 & 8
                        x = PADDING_LEFT + ((i - 4) * (iconSize.width + MARGIN_HORIZ_ROW_1));
                        y = PADDING_TOP + iconSize.height + MARGIN_VERT;
                    }
                    [icon setOrigin:CGPointMake(x, y)];
                    [self addSubview:icon];
                }
            }
        }
    }
    return self;
}

@end

/* vim: set syntax=objcpp sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
