#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

@interface PlaneNode : SCNNode

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor;

- (void)update:(ARPlaneAnchor *)anchor;

@end
