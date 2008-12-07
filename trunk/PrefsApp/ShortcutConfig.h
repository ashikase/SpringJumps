#import <Foundation/NSObject.h>

@class NSDictionary;
@class NSString;

@interface ShortcutConfig : NSObject
{
    BOOL enabled;
    NSString *name;
}

@property(nonatomic) BOOL enabled;
@property(nonatomic, copy) NSString *name;

- (id)initWithName:(NSString *)name;
- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
