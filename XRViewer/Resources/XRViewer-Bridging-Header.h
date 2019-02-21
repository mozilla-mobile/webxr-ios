//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "ARKHelper.h"
#import "ARKController.h"
#import "WebARKHeader.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "Renderer.h"

#if DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

typedef NS_ENUM(NSInteger, ResetTrackingOption) {
    ResetTracking,
    RemoveExistingAnchors,
    SaveWorldMap,
    LoadSavedWorldMap
};

typedef void (^HotAction)(BOOL); // long
