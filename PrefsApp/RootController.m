/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2009-05-07 21:02:29
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

#import <Foundation/Foundation.h>

#import <UIKit/UISwitch.h>
#import <UIKit/UIViewController-UINavigationControllerItem.h>

#import "Constants.h"
#import "GeneralPrefsController.h"
#import "DocumentationController.h"
#import "JumpIconsController.h"
#import "Preferences.h"


@implementation RootController

- (id)initWithStyle:(int)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self setTitle:@"SpringJumps"];
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
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(int)section
{
    return (section == 0) ? @"Documentation" : @"Preferences";
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section
{
    return (section == 0) ? 4 : 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdSimple = @"SimpleCell";
    static NSString *reuseIdSafari = @"SafariCell";

    UITableViewCell *cell = nil;
    if (indexPath.section == 0 && indexPath.row == 3) {
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
        static NSString *cellTitles[][3] = {
            { @"How to Use", @"Release Notes", @"Known Issues" },
            { @"General", @"Jump Icons", nil }
        };

        // Try to retrieve from the table view a now-unused cell with the given identifier
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdSimple];
        if (cell == nil) {
            // Cell does not exist, create a new one
            cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdSimple] autorelease];
            [cell setSelectionStyle:2]; // Gray
            [cell setAccessoryType:1]; // Simple arrow
        }
        [cell setText:cellTitles[indexPath.section][indexPath.row]];
    }

    return cell;
}

#pragma mark - UITableViewCellDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *vc = nil;

    if (indexPath.section == 0) {
        // Documentation
        static NSString *fileNames[] = { @"usage.html", @"release_notes.html", @"known_issues.html" };
        static NSString *titles[] = { @"How to Use", @"Release Notes", @"Known Issues" };

        if (indexPath.row == 3)
            // Project Homepage
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@DEVSITE_URL]];
        else
            vc = [[[DocumentationController alloc]
                initWithContentsOfFile:fileNames[indexPath.row] title:titles[indexPath.row]]
                autorelease];
    } else {
        // Preferences
        if (indexPath.row == 0)
            vc = [[[GeneralPrefsController alloc] initWithStyle:1] autorelease];
        else
            //vc = [[[AppSpecificPrefsController alloc] initWithStyle:1] autorelease];
            vc = [[[JumpIconsController alloc] initWithStyle:1] autorelease];
    }

    if (vc)
        [[self navigationController] pushViewController:vc animated:YES];
}

#pragma mark - Switch delegate

- (void)switchToggled:(UISwitch *)control
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [tableView indexPathForCell:[control superview]];
    if (indexPath.section == 1) {
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
