#import <UIKit/UIApplication.h>

@class PreferencesController;
@class UIWindow;

@interface SpringJumpsApplication : UIApplication
{
    UIWindow *window;
    PreferencesController *prefsController;
}

@property(nonatomic, retain) UIWindow *window;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
