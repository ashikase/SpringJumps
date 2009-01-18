#import <Foundation/NSObject.h>

@class NSArray;
@class NSMutableArray;
@class ShortcutConfig;

@interface Preferences : NSObject
{
    BOOL modified;

    BOOL firstRun;
    BOOL showPageTitles;
    BOOL enableJumpDock;
    NSMutableArray *shortcutConfigs;
}

@property(nonatomic, getter=isModified) BOOL modified;
@property(nonatomic) BOOL firstRun;
@property(nonatomic) BOOL showPageTitles;
@property(nonatomic, getter=jumpDockIsEnabled) BOOL enableJumpDock;
@property(nonatomic, readonly) NSArray *shortcutConfigs;

+ (Preferences *)sharedInstance;
+ (ShortcutConfig *)configForShortcut:(int)i;

- (void)registerDefaults;
- (void)readUserDefaults;
- (void)writeUserDefaults;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
