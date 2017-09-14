#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

@interface AnchorNode : SCNNode

- (instancetype)initWithAnchor:(ARAnchor *)anchor;

- (CGFloat)size;

@end
