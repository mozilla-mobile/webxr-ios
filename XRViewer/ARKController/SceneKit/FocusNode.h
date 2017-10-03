#import <SceneKit/SceneKit.h>
#import "ARKHelper.h"

@interface FocusNode : SCNNode

- (void)updateForPosition:(SCNVector3)position planeAnchor:(ARPlaneAnchor *)anchor camera:(ARCamera *)camera;

@end
