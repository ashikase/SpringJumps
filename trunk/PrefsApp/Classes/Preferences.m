/**
 * Name: SpringJumps
 * Type: iPhone OS 2.x SpringBoard extension (MobileSubstrate-based)
 * Description: Allows for the creation of icons that act as shortcuts
 *              to SpringBoard's different icon pages.
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2009-05-02 13:41:26
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


#import "Preferences.h"

#import <Foundation/Foundation.h>

#import "Constants.h"
#import "ShortcutConfig.h"


@implementation Preferences

@synthesize firstRun;
@synthesize showPageTitles;
@synthesize enableJumpDock;
@synthesize shortcutConfigs;

#pragma mark - Methods

+ (Preferences *)sharedInstance
{
    static Preferences *instance = nil;
    if (instance == nil)
        instance = [[Preferences alloc] init];
    return instance;
}

+ (ShortcutConfig *)configForShortcut:(int)index
{
    return [[[Preferences sharedInstance] shortcutConfigs] objectAtIndex:index];
}

- (id)init
{
    self = [super init];
    if (self) {
        shortcutConfigs = [[NSMutableArray alloc] initWithCapacity:MAX_PAGES];

        // Setup default values
        [self registerDefaults];

        // Load preference values into memory
        [self readFromDisk];

        // Retain a copy of the initial values of the preferences
        initialValues = [[self dictionaryRepresentation] retain];

        // The on-disk values at startup are the same as initialValues
        onDiskValues = [initialValues retain];
    }
    return self;
}

- (void)dealloc
{
    [onDiskValues release];
    [initialValues release];
    [shortcutConfigs release];
    [super dealloc];
}

#pragma mark - Other

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];

    [dict setObject:[NSNumber numberWithBool:firstRun] forKey:@"firstRun"];
    [dict setObject:[NSNumber numberWithBool:showPageTitles] forKey:@"showPageTitles"];
    [dict setObject:[NSNumber numberWithBool:enableJumpDock] forKey:@"enableJumpDock"];

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:MAX_PAGES];
    for (int i = 0; i < MAX_PAGES; i++) {
        ShortcutConfig *config = [shortcutConfigs objectAtIndex:i];
        [array addObject:[config dictionaryRepresentation]];
    }
    [dict setObject:array forKey:@"shortcuts"];

    return dict;
}

#pragma mark - Status

- (BOOL)isModified
{
    return ![[self dictionaryRepresentation] isEqual:onDiskValues];
}

- (BOOL)needsRespring
{
    return ![[self dictionaryRepresentation] isEqual:initialValues];
}

#pragma mark - Read/Write methods

- (void)registerDefaults
{
    // NOTE: This method sets default values for options that are not already
    //       already set in the application's on-disk preferences list.

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];

    [dict setObject:[NSNumber numberWithBool:YES] forKey:@"firstRun"];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:@"showPageTitles"];
    [dict setObject:[NSNumber numberWithBool:NO] forKey:@"enableJumpDock"];

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:MAX_PAGES];
    for (int i = 0; i < MAX_PAGES; i++) {
        NSString *name = [NSString stringWithFormat:@"Page %d", i];
        ShortcutConfig *config = [[ShortcutConfig alloc] initWithName:name];
        [array addObject:[config dictionaryRepresentation]];
        [config release];
    }
    [dict setObject:array forKey:@"shortcuts"];

    [defaults registerDefaults:dict];
}

- (void)readFromDisk
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    firstRun = [defaults boolForKey:@"firstRun"];
    showPageTitles = [defaults boolForKey:@"showPageTitles"];
    enableJumpDock = [defaults boolForKey:@"enableJumpDock"];

    NSArray *array = [defaults arrayForKey:@"shortcuts"];
    for (int i = 0; i < MAX_PAGES; i++) {
        NSDictionary *dict = [array objectAtIndex:i];
        ShortcutConfig *config = [[ShortcutConfig alloc] initWithDictionary:dict];
        [shortcutConfigs addObject:config];
    }
}

- (void)writeToDisk
{
    NSDictionary *dict = [self dictionaryRepresentation];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setPersistentDomain:dict forName:[[NSBundle mainBundle] bundleIdentifier]];
    [defaults synchronize];

    // Update the list of on-disk values
    [onDiskValues release];
    onDiskValues = [dict retain];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
