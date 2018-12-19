//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "ARKHelper.h"
#import "Prefix.h"
#import "ARKController.h"

typedef NS_ENUM(NSInteger, ResetTrackingOption) {
    ResetTracking,
    RemoveExistingAnchors,
    SaveWorldMap,
    LoadSavedWorldMap
};

typedef void (^HotAction)(BOOL); // long
