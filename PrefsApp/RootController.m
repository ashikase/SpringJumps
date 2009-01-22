/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2009-01-22 13:12:05
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

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"SpringJumps Prefs"];
        [[self navigationItem] setBackButtonTitle:@"Back"];
    }
    return self;
}

- (void)loadView
{
    table = [[UITableView alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame] style:1];
    [table setDataSource:self];
    [table setDelegate:self];
    [table reloadData];
    [self setView:table];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table deselectRowAtIndexPath:[table indexPathForSelectedRow] animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    Preferences *prefs = [Preferences sharedInstance];
    if ([prefs isModified]) {
        // Write preferences to disk
        [prefs writeUserDefaults];

        // Respring SpringBoard
        notify_post("com.apple.language.changed");
    }
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
            return @"General";
        case 1:
            return @"Shortcuts";
        case 2:
            return @"Other";
        default:
            return nil;
    }
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
{
    switch (section) {
        case 0:
            // General
            return 2;
        case 1:
            // Shortcuts
            return MAX_PAGES;
        case 2:
            // Other
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"PreferencesCell";

    // Try to retrieve from the table view a now-unused cell with the given identifier
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil)
        // Cell does not exist, create a new one
        cell = [[[PreferencesCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier] autorelease];

    switch (indexPath.section) {
        case 0:
            // General
            [cell setImage:nil];
            [cell setSelectionStyle:0];

            UISwitch *toggle = [[UISwitch alloc] init];
            [toggle addTarget:self action:@selector(switchToggled:) forControlEvents:4096]; // ValueChanged

            if (indexPath.row == 0) {
                [cell setText:@"Page titles"];
                [toggle setOn:[[Preferences sharedInstance] showPageTitles]];
            } else {
                [cell setText:@"Jump dock"];
                [toggle setOn:[[Preferences sharedInstance] jumpDockIsEnabled]];
            }

            [cell setAccessoryView:toggle];
            [toggle release];
            break;
        case 1:
            // Shortcuts
            {
                ShortcutConfig *config = [Preferences configForShortcut:indexPath.row];
                [cell setText:config.name];

                NSString *identifier = [NSString stringWithFormat:@"%s.%d", "jp.ashikase.springjumps", indexPath.row];
                NSString *iconPath = SBSCopyIconImagePathForDisplayIdentifier(identifier);
                if (iconPath != nil) {
                    UIImage *icon = [UIImage imageWithContentsOfFile:iconPath];
                    icon = [icon _imageScaledToSize:CGSizeMake(35, 36) interpolationQuality:0];
                    [cell setImage:icon];
                }

                UISwitch *toggle = [[UISwitch alloc] init];
                [toggle setOn:config.enabled];
                [toggle addTarget:self action:@selector(switchToggled:) forControlEvents:4096]; // ValueChanged
                [toggle setEnabled:![[Preferences sharedInstance] jumpDockIsEnabled]];
                [cell setAccessoryType:2];
                [cell setAccessoryView:toggle];
                [toggle release];
            }
            break;
        case 2:
            // Other
            [cell setText:@"Visit the project homepage"];
            [cell setImage:nil];
            [cell setAccessoryView:nil];
            break;
    }

    return cell;
}

#pragma mark - UITableViewCellDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 1:
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
                    [table deselectRowAtIndexPath:[table indexPathForSelectedRow] animated:NO];
                }

            }
            break;
        case 2:
            // Other
            [[UIApplication sharedApplication] openURL:
                [NSURL URLWithString:@"http://code.google.com/p/iphone-springjumps/wiki/Documentation"]];
            break;
        case 0:
        default:
            break;
    }
}

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)index
{
    // Reset the table by deselecting the current selection
    [table deselectRowAtIndexPath:[table indexPathForSelectedRow] animated:YES];

    if (index == 1) {
        UITableViewCell *cell = [table cellForRowAtIndexPath:
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
    NSIndexPath *indexPath = [table indexPathForCell:[control superview]];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // Toggled show page titles
            [[Preferences sharedInstance] setShowPageTitles:[control isOn]];
        } else {
            // Toggled jump dock
            [[Preferences sharedInstance] setEnableJumpDock:[control isOn]];

            // Must reload the table data, as the ability to hide shortcuts
            // is affected by this setting.
            [table reloadData];
        }
    } else {
        // Toggled a shortcut
        ShortcutConfig *config = [Preferences configForShortcut:indexPath.row];
        [config setEnabled:[control isOn]];
    }
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
