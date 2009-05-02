#import <Foundation/NSObject.h>


@class NSArray;
@class NSDictionary;
@class NSMutableArray;
@class ShortcutConfig;

@interface Preferences : NSObject
{
    NSDictionary *initialValues;
    NSDictionary *onDiskValues;

    BOOL firstRun;
    BOOL showPageTitles;
    BOOL enableJumpDock;
    NSMutableArray *shortcutConfigs;
}

@property(nonatomic) BOOL firstRun;
@property(nonatomic) BOOL showPageTitles;
@property(nonatomic, getter=jumpDockIsEnabled) BOOL enableJumpDock;
@property(nonatomic, readonly) NSArray *shortcutConfigs;

+ (Preferences *)sharedInstance;
+ (ShortcutConfig *)configForShortcut:(int)i;

- (NSDictionary *)dictionaryRepresentation;

- (BOOL)isModified;
- (BOOL)needsRespring;

- (void)registerDefaults;
- (void)readFromDisk;
- (void)writeToDisk;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
