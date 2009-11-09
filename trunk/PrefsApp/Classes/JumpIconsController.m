/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2009-10-02 00:20:01
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


#import "JumpIconsController.h"

#import <CoreGraphics/CGGeometry.h>

#import "Constants.h"
#import "HtmlDocController.h"
#import "Preferences.h"
#import "ShortcutConfig.h"

extern NSString * SBSCopyIconImagePathForDisplayIdentifier(NSString *identifier);

#define HELP_FILE "jump_icons.html"


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

@implementation JumpIconsController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Jump Icons";
        [[self navigationItem] setRightBarButtonItem:
             [[UIBarButtonItem alloc] initWithTitle:@"Help" style:5
                target:self
                action:@selector(helpButtonTapped)]];
    }
    return self;
}

#pragma mark - UITableViewDataSource

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(int)section
{
    return nil;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
{
    return MAX_PAGES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdToggle = @"ToggleCell";

    // Try to retrieve from the table view a now-unused cell with the given identifier
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdToggle];
    if (cell == nil) {
        // Cell does not exist, create a new one
        cell = [[[PreferencesCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdToggle] autorelease];
        [cell setSelectionStyle:0];

        UISwitch *toggle = [[UISwitch alloc] init];
        [toggle addTarget:self action:@selector(switchToggled:) forControlEvents:4096]; // ValueChanged
        [cell setAccessoryView:toggle];
        [toggle release];
    }

    ShortcutConfig *config = [Preferences configForShortcut:indexPath.row];
    [cell setText:config.name];

    NSString *identifier = [NSString stringWithFormat:@"%s.%d", "jp.ashikase.springjumps", indexPath.row];
    NSString *iconPath = SBSCopyIconImagePathForDisplayIdentifier(identifier);
    if (iconPath != nil) {
        UIImage *icon = [UIImage imageWithContentsOfFile:iconPath];
        //icon = [icon _imageScaledToSize:CGSizeMake(35, 36) interpolationQuality:0];
        [cell setImage:icon];
        [iconPath release];
    }

    UISwitch *toggle = (UISwitch *)[cell accessoryView];
    [toggle setOn:config.enabled];
    [toggle setHidden:[[Preferences sharedInstance] jumpDockIsEnabled]];

    return cell;
}

#pragma mark - UITableViewCellDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PreferencesCell *cell = (PreferencesCell *)[tableView cellForRowAtIndexPath:indexPath];

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

#pragma mark - Switch delegate

- (void)switchToggled:(UISwitch *)control
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[control superview]];
    ShortcutConfig *config = [Preferences configForShortcut:indexPath.row];
    [config setEnabled:[control isOn]];
}

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)index
{
    // Reset the table by deselecting the current selection
    UITableView *tableView = [self tableView];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    if (index == 1) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:
            [NSIndexPath indexPathForRow:selectedShortcut inSection:0]];
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

#pragma mark - Navigation bar delegates

- (void)helpButtonTapped
{
    // Create and show help page
    [[self navigationController] pushViewController:[[[HtmlDocController alloc]
        initWithContentsOfFile:@HELP_FILE title:@"Explanation"] autorelease] animated:YES];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
