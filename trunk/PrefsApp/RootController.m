/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2009-05-02 12:40:54
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


#import "RootController.h"

#include <notify.h>

#import <Foundation/NSSet.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIAlertView-Private.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UIViewController-UINavigationControllerItem.h>

#import "Constants.h"
#import "DocumentationController.h"
#import "Preferences.h"
#import "ShortcutConfig.h"

extern NSString * SBSCopyIconImagePathForDisplayIdentifier(NSString *identifier);


@interface PreferencesCell : UITableViewCell
{
    float touchLocation;
}

@property(nonatomic, readonly) float touchLocation;

@end

@implementation PreferencesCell

@synthesize touchLocation;

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if (touch) {
        CGPoint point = [touch locationInView:self];
        touchLocation = point.x;
    }
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@implementation RootController

- (id)initWithStyle:(int)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self setTitle:@"SpringJumps Prefs"];
        [[self navigationItem] setBackButtonTitle:@"Back"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    UITableView *tableView = [self tableView];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - UITableViewDataSource

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(int)section
{
    switch (section) {
        case 0:
            return @"Documentation";
        case 1:
            return @"General";
        case 2:
            return @"Shortcuts (Tap label to rename)";
        default:
            return nil;
    }
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
{
    switch (section) {
        case 0:
            // Documentation
            return 4;
        case 1:
            // General
            return 2;
        case 2:
            // Shortcuts
            return MAX_PAGES;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdSimple = @"SimpleCell";
    static NSString *reuseIdSafari = @"SafariCell";
    static NSString *reuseIdToggle = @"ToggleCell";

    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        // Documentation
        if (indexPath.row == 3) {
            // Try to retrieve from the table view a now-unused cell with the given identifier
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdSafari];
            if (cell == nil) {
                // Cell does not exist, create a new one
                cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdSafari] autorelease];
                [cell setSelectionStyle:2]; // Gray

                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                NSString *labelText = @"(via Safari)";
                [label setText:labelText];
                [label setTextColor:[UIColor colorWithRed:0.2f green:0.31f blue:0.52f alpha:1.0f]];
                UIFont *font = [UIFont systemFontOfSize:16.0f];
                [label setFont:font];
                CGSize size = [labelText sizeWithFont:font];
                [label setFrame:CGRectMake(0, 0, size.width, size.height)];

                [cell setAccessoryView:label];
                [label release];
            }

            [cell setText:@"Project Homepage"];
        } else {
            // Try to retrieve from the table view a now-unused cell with the given identifier
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdSimple];
            if (cell == nil) {
                // Cell does not exist, create a new one
                cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdSimple] autorelease];
                [cell setSelectionStyle:2]; // Gray
                [cell setAccessoryType:1]; // Simple arrow
            }

            switch (indexPath.row) {
                case 0:
                    [cell setText:@"How to Use"];
                    break;
                case 1:
                    [cell setText:@"Release Notes"];
                    break;
                case 2:
                    [cell setText:@"Known Issues"];
                    break;
            }
        }
    } else {
        // Try to retrieve from the table view a now-unused cell with the given identifier
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdToggle];
        if (cell == nil) {
            // Cell does not exist, create a new one
            cell = [[[PreferencesCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdToggle] autorelease];
            [cell setSelectionStyle:0];

            UISwitch *toggle = [[UISwitch alloc] init];
            [toggle addTarget:self action:@selector(switchToggled:) forControlEvents:4096]; // ValueChanged
            [cell setAccessoryView:toggle];
            [toggle release];
        }

        UISwitch *toggle = [cell accessoryView];
        if (indexPath.section == 1) {
            // General
            [cell setImage:nil];
            [toggle setEnabled:YES];

            if (indexPath.row == 0) {
                [cell setText:@"Page titles"];
                [toggle setOn:[[Preferences sharedInstance] showPageTitles]];
            } else {
                [cell setText:@"Jump dock"];
                [toggle setOn:[[Preferences sharedInstance] jumpDockIsEnabled]];
            }
        } else {
            // Shortcuts
            ShortcutConfig *config = [Preferences configForShortcut:indexPath.row];
            [cell setText:config.name];

            NSString *identifier = [NSString stringWithFormat:@"%s.%d", "jp.ashikase.springjumps", indexPath.row];
            NSString *iconPath = SBSCopyIconImagePathForDisplayIdentifier(identifier);
            if (iconPath != nil) {
                UIImage *icon = [UIImage imageWithContentsOfFile:iconPath];
                icon = [icon _imageScaledToSize:CGSizeMake(35, 36) interpolationQuality:0];
                [cell setImage:icon];
            }

            [toggle setOn:config.enabled];
            [toggle setEnabled:![[Preferences sharedInstance] jumpDockIsEnabled]];
        }
    }

    return cell;
}

#pragma mark - UITableViewCellDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            {
                // Documentation
                NSString *fileName = nil;
                NSString *title = nil;

                switch (indexPath.section) {
                    case 0:
                        {
                            switch (indexPath.row) {
                                case 0:
                                    fileName = @"usage.html";
                                    title = @"How to Use";
                                    break;
                                case 1:
                                    fileName = @"release_notes.html";
                                    title = @"Release Notes";
                                    break;
                                case 2:
                                    fileName = @"known_issues.html";
                                    title = @"Known Issues";
                                    break;
                                case 3:
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@DEVSITE_URL]];
                                    break;
                            }
                            if (fileName && title)
                                [[self navigationController] pushViewController:[[[DocumentationController alloc]
                                    initWithContentsOfFile:fileName title:title] autorelease] animated:YES];
                        }
                }
            }
            break;
        case 2:
            // Shortcuts
            {
                PreferencesCell *cell = [tableView cellForRowAtIndexPath:indexPath];

                // NOTE: Thie check is to make sure the popup and switch are not
                //       activated at the same time
                if ([cell touchLocation] < [[cell accessoryView] frame].origin.x) {
                    // Record which shortcut was selected
                    selectedShortcut = indexPath.row;

                    // Show popup to change shortcut title
                    NSString *title = [NSString stringWithFormat:@"Shortcut for Page %d", selectedShortcut];
                    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:nil
                        delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil]
                        autorelease];
                    [alert addTextFieldWithValue:[cell text] label:@"<Enter shortcut name>"];
                    [[alert textField] setDelegate:self];
                    [[alert textField] setClearButtonMode:1]; // UITextFieldViewModeWhileEditing
                    [[alert textField] setAutocorrectionType:1]; // UITextAutocorrectionTypeNo
                    [alert show];
                } else {
                    // Reset the table by deselecting the current selection
                    UITableView *tableView = [self tableView];
                    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
                }

            }
            break;
    }
}

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)index
{
    // Reset the table by deselecting the current selection
    UITableView *tableView = [self tableView];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    if (index == 1) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:
            [NSIndexPath indexPathForRow:selectedShortcut inSection:1]];
        [cell setText:[[alertView textField] text]];

        ShortcutConfig *config = [Preferences configForShortcut:selectedShortcut];
        [config setName:[[alertView textField] text]];
    }
}

// NOTE: The following method allows the use of the return key to select "OK"
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UIAlertView *alert = (UIAlertView *)[textField superview];
	[self alertView:alert clickedButtonAtIndex:1];
	[alert dismissWithClickedButtonIndex:1 animated:NO];

	return NO;
}

#pragma mark - Switch delegate

- (void)switchToggled:(UISwitch *)control
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [tableView indexPathForCell:[control superview]];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // Toggled show page titles
            [[Preferences sharedInstance] setShowPageTitles:[control isOn]];
        } else {
            // Toggled jump dock
            [[Preferences sharedInstance] setEnableJumpDock:[control isOn]];

            // Must reload the table data, as the ability to hide shortcuts
            // is affected by this setting.
            [tableView reloadData];
        }
    } else {
        // Toggled a shortcut
        ShortcutConfig *config = [Preferences configForShortcut:indexPath.row];
        [config setEnabled:[control isOn]];
    }
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
