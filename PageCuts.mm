#include <substrate.h>

#import <CoreGraphics/CGGeometry.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBIconList.h>
#import <SpringBoard/SBIconModel.h>

#import <UIKit/UIView-Animation.h>

@protocol PageCutsController
- (id) pc_init;
- (void) pc_dealloc;
- (void) pc_unscatter:(BOOL)unscatter startTime:(double)startTime;
- (void) pc_clickedIcon:(SBIcon *)icon;
- (void) pc_updateCurrentIconListIndexUpdatingPageIndicator:(BOOL)update;
@end

@protocol PageCutsIcon
- (id) pc_displayName;
@end

#define MAX_DOCK_ICONS 5
#define MAX_PAGES 9
#define NAME_PREFIX "Folder_"
#define PAGECUT_PREFIX "com.pagecuts"


static SBIconModel *iconModel = nil;

static NSString *pageNames[MAX_PAGES] = {nil};
static NSArray *offscreenDockIcons = nil;

static id $SBIconController$init(SBIconController<PageCutsController> *self, SEL sel)
{
    self = [self pc_init];
    if (self) {
        Class $SBIconModel(objc_getClass("SBIconModel"));
        iconModel = [$SBIconModel sharedInstance];

        // Load and cache page names
        for (int i = 0; i < MAX_PAGES; i++) {
            SBIcon *icon = [iconModel iconForDisplayIdentifier:
                [NSString stringWithFormat:@PAGECUT_PREFIX".%d", i]];
            if (icon) {
                NSString *name = [icon displayName];
                if ([name hasPrefix:@NAME_PREFIX])
                    pageNames[i] = [[name substringFromIndex:strlen(NAME_PREFIX)] retain];
                else
                    pageNames[i] = [name copy];
            }
        }

        // Restore any previously saved list of off-screen Dock icons
        NSMutableArray *iconArray = [[NSMutableArray alloc] initWithCapacity:MAX_DOCK_ICONS];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dict = [defaults objectForKey:@"pageCutsOffscreenDockIcons"];
        NSArray *row = [[dict objectForKey:@"iconMatrix"] objectAtIndex:0];
        for (id iconInfo in row) {
            // NOTE: empty slots are represented by NSNumber 0
            if ([iconInfo isKindOfClass:[NSDictionary class]]) {
                NSString *identifier = [iconInfo objectForKey:@"displayIdentifier"];
                [iconArray addObject:[iconModel iconForDisplayIdentifier:identifier]];
            }
        }
        if ([iconArray count] == 0)
            // Toggled dock must always contain the page-0 icon for toggling
            [iconArray addObject:[iconModel iconForDisplayIdentifier:@PAGECUT_PREFIX".0"]];

        offscreenDockIcons = iconArray;
    }
    return self;
}

static void $SBIconController$dealloc(SBIconController<PageCutsController> *self, SEL sel)
{
    [offscreenDockIcons release];
    [self pc_dealloc];
}

static void $SBIconController$unscatter$startTime$(SBIconController<PageCutsController> *self, SEL sel, BOOL unscatter, double startTime)
{
    static BOOL isFirstTime = YES;
    if (isFirstTime) {
        [UIView disableAnimation];

        for (SBIcon *dockIcon in offscreenDockIcons) {
            SBIconList *page = [iconModel iconListContainingIcon:dockIcon];
            if (page && ![page isDock])
                [page removeIcon:dockIcon compactEmptyLists:NO animate:NO];
        }
        [iconModel compactIconLists];
        [iconModel saveIconState];

        [UIView enableAnimation];

        isFirstTime = NO;
    }

    [self pc_unscatter:unscatter startTime:startTime];
}

static void $SBIconController$clickedIcon$(SBIconController<PageCutsController> *self, SEL sel, SBIcon *icon)
{
    NSString *ident = [icon displayIdentifier];
    if ([ident hasPrefix:@PAGECUT_PREFIX]) {
        // Use identifier with format: PAGECUT_PREFIX.pagenumber
        // (e.g. com.pagecuts.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] != 3) return;
        int pageNumber = [[parts objectAtIndex:2] intValue];

        // Get the current page index
        int currentIndex;
        object_getInstanceVariable(self, "_currentIconListIndex",
            reinterpret_cast<void **>(&currentIndex));

        if ((pageNumber != currentIndex) &&
                (pageNumber < (int)[[iconModel iconLists] count])) {
            // Switch to requested page
            [self scrollToIconListAtIndex:pageNumber animate:NO];
        } else if (pageNumber == 0) {
            // Tapped page 0 icon while on page 0 screen (toggle dock)
            SBButtonBar *dock = [iconModel buttonBar];
            NSDictionary *prevRepresentation = [dock dictionaryRepresentation];

            // NOTE: no need to copy; tests show the list creates a new array
            NSArray *prevIcons = [[dock icons] retain];
            [dock removeAllIcons];

            // Restore saved state
            int i = 0;
            for (SBIcon *dockIcon in offscreenDockIcons)
                [dock placeIcon:dockIcon atX:i++ Y:0 animate:NO moveNow:YES];
            [dock layoutIconsNow];

            // Store list of off-screen dock icons
            [offscreenDockIcons release];
            offscreenDockIcons = prevIcons;

            // Save state of pages
            [iconModel saveIconState];

            // Also save list of off-screen icons to SpringBoard's preferences
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:prevRepresentation forKey:@"pageCutsOffscreenDockIcons"];
            [defaults synchronize];
        }
    } else {
        // Regular application icon
        [self pc_clickedIcon:icon];
    }
}

static void $SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$(SBIconController<PageCutsController> *self, SEL sel, BOOL update)
{
    [self pc_updateCurrentIconListIndexUpdatingPageIndicator:update];

    // Update page title-bar
    int index;
    object_getInstanceVariable(self, "_currentIconListIndex", reinterpret_cast<void **>(&index));
    [self setIdleModeText:pageNames[index]];
}

//______________________________________________________________________________
//______________________________________________________________________________

static id $SBApplicationIcon$displayName(SBApplicationIcon<PageCutsIcon> *self, SEL sel)
{
    // If the icon's name starts with NAME_PREFIX, remove the prefix
    // FIXME: currently, this can affect *all icons*, not just page cuts
    NSString *name = [self pc_displayName];
    if ([name hasPrefix:@NAME_PREFIX])
        name = [name substringFromIndex:strlen(NAME_PREFIX)];
    return name;
}

//______________________________________________________________________________
//______________________________________________________________________________

extern "C" void PageCutsInitialize()
{
    if (objc_getClass("SpringBoard") == nil)
        return;

    Class $SBIconController(objc_getClass("SBIconController"));
    MSHookMessage($SBIconController, @selector(init), (IMP) &$SBIconController$init, "pc_");
    MSHookMessage($SBIconController, @selector(dealloc), (IMP) &$SBIconController$dealloc, "pc_");
    MSHookMessage($SBIconController, @selector(clickedIcon:), (IMP) &$SBIconController$clickedIcon$, "pc_");
    MSHookMessage($SBIconController, @selector(updateCurrentIconListIndexUpdatingPageIndicator:),
        (IMP) &$SBIconController$updateCurrentIconListIndexUpdatingPageIndicator$, "pc_");
    MSHookMessage($SBIconController, @selector(unscatter:startTime:), (IMP) &$SBIconController$unscatter$startTime$, "pc_");

    Class $SBApplicationIcon(objc_getClass("SBApplicationIcon"));
    MSHookMessage($SBApplicationIcon, @selector(displayName), (IMP) &$SBApplicationIcon$displayName, "pc_");
}
