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

@protocol PageCutsController
- (id) pc_init;
- (void) pc_dealloc;
- (void) pc_clickedIcon:(SBIcon *)icon;
- (void) pc_updateCurrentIconListIndexUpdatingPageIndicator:(BOOL)update;
- (void) pc_unscatter:(BOOL)unscatter startTime:(double)startTime;
@end

@protocol PageCutsIcon
- (id) pc_displayName;
@end

@protocol PageCutsList
- (id) pc_resetWithDictionaryRepresentation:(id)rep;
@end

#define MAX_DOCK_ICONS 5
#define MAX_PAGES 9
#define NAME_PREFIX "Folder_"


static NSString *pageNames[MAX_PAGES] = {nil};
static NSArray *offscreenDockIcons = nil;

static id $SBIconController$init(SBIconController<PageCutsController> *self, SEL sel)
{
    self = [self pc_init];
    if (self) {
        Class $SBIconModel(objc_getClass("SBIconModel"));
        SBIconModel *iconModel = [$SBIconModel sharedInstance];

        // Load and cache page names
        for (int i = 0; i < MAX_PAGES; i++) {
            SBIcon *icon = [iconModel iconForDisplayIdentifier:
                [NSString stringWithFormat:@"com.pagecuts.%d", i]];
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
                SBIcon *icon = [iconModel iconForDisplayIdentifier:identifier];
                [iconArray addObject:icon];
            }
        }
        offscreenDockIcons = iconArray;
    }
    return self;
}

static void $SBIconController$dealloc(SBIconController<PageCutsController> *self, SEL sel)
{
    [offscreenDockIcons release];
    [self pc_dealloc];
}

static void $SBIconController$clickedIcon$(SBIconController<PageCutsController> *self, SEL sel, SBIcon *icon)
{
    NSString *ident = [icon displayIdentifier];
    if ([ident hasPrefix:@"com.pagecuts"]) {
        // Use identifier with format: com.pagecuts.pagenumber
        // (e.g. com.pagecuts.2)
        NSArray *parts = [ident componentsSeparatedByString:@"."];
        if ([parts count] != 3) return;
        int pageNumber = [[parts objectAtIndex:2] intValue];

        // Get the current page index
        int currentIndex;
        object_getInstanceVariable(self, "_currentIconListIndex",
            reinterpret_cast<void **>(&currentIndex));

        // Get the number of pages
        Class $SBIconModel(objc_getClass("SBIconModel"));
        SBIconModel *iconModel = [$SBIconModel sharedInstance];
        NSMutableArray *pages = [iconModel iconLists];

        if ((pageNumber != currentIndex) &&
                (pageNumber < (int)[pages count])) {
            // Switch to requested page
            [self scrollToIconListAtIndex:pageNumber animate:NO];
        } else if (pageNumber == 0) {
            // Tapped page 0 icon while on page 0 screen (toggle dock)
            SBButtonBar *dock = [iconModel buttonBar];
            NSDictionary *prevRepresentation = [dock dictionaryRepresentation];

            // NOTE: no need to copy; tests show the list creates a new array
            NSArray *prevIcons = [[dock icons] retain];

            if (offscreenDockIcons != nil) {
                // Restore saved state
                [dock removeAllIcons];
                int i = 0;
                for (SBIcon *dockIcon in offscreenDockIcons) {
                    SBIconList *page = [iconModel iconListContainingIcon:dockIcon];
                    if (page)
                        [page removeIcon:dockIcon compactEmptyLists:NO animate:NO];
                    [dock placeIcon:dockIcon atX:i++ Y:0 animate:NO moveNow:YES];
                }
                [offscreenDockIcons release];
                [iconModel saveIconState];
            } else {
                // Remove all icons except for page 0 icon
                for (id dockIcon in [dock icons])
                    if (![[dockIcon displayIdentifier] isEqualToString:@"com.pagecuts.0"])
                        [dock removeIcon:dockIcon compactEmptyLists:NO animate:NO];
            }

            // Refresh the dock to account for any changes
            [dock layoutIconsNow];

            // Save list of off-screen dock icons
            offscreenDockIcons = prevIcons;

            // Also save a list to SpringBoard's preferences
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

static void $SBIconController$unscatter$startTime$(SBIconController<PageCutsController> *self, SEL sel, BOOL unscatter, double startTime)
{
    static BOOL isFirstTime = YES;
    if (isFirstTime) {
        NSLog(@"PageCuts: unscattter first time");
        if (offscreenDockIcons != nil) {
            Class $SBIconModel(objc_getClass("SBIconModel"));
            SBIconModel *iconModel = [$SBIconModel sharedInstance];

            for (SBIcon *dockIcon in offscreenDockIcons) {
                SBIconList *page = [iconModel iconListContainingIcon:dockIcon];
                if (page && ![page isDock])
                    [page removeIcon:dockIcon compactEmptyLists:NO animate:NO];
            }
            [iconModel saveIconState];
        }
        isFirstTime = NO;
    } else {
        NSLog(@"PageCuts: not unscattter first time");
    }

    [self pc_unscatter:unscatter startTime:startTime];
}

static id $SBApplicationIcon$displayName(SBApplicationIcon<PageCutsIcon> *self, SEL sel)
{
    // If the icon's name starts with NAME_PREFIX, remove the prefix
    // FIXME: currently, this can affect *all icons*, not just page cuts
    NSString *name = [self pc_displayName];
    if ([name hasPrefix:@NAME_PREFIX])
        name = [name substringFromIndex:strlen(NAME_PREFIX)];
    return name;
}

static void $SBIconList$resetWithDictionaryRepresentation$(SBIconList<PageCutsList> *self, SEL sel, id rep)
{
    [self pc_resetWithDictionaryRepresentation:rep];
}

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

    Class $SBIconList(objc_getClass("SBIconList"));
    MSHookMessage($SBIconList, @selector(resetWithDictionaryRepresentation:), (IMP) &$SBIconList$resetWithDictionaryRepresentation$, "pc_");
}
