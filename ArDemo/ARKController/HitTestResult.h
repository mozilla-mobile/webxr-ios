#import <Foundation/Foundation.h>
#import "ARKHelper.h"

@interface HitTestResult : NSObject

@property(nonatomic) SCNVector3 position;
@property(nonatomic) ARPlaneAnchor *anchor;
@property(nonatomic) BOOL hightQuality;
@property(nonatomic) BOOL infinitePlane;

@end
