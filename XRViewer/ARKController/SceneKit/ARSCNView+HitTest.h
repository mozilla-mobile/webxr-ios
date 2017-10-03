#import <ARKit/ARKit.h>

@class HitTestResult;
typedef void (^HitTestResultBlock)(HitTestResult *);

@interface ARSCNView (HitTest)

- (NSArray *)hitTestPoint:(CGPoint)point withResult:(HitTestResultBlock)resultBlock;

@end

@interface HitTestRay : NSObject

@property(nonatomic) SCNVector3 origin;
@property(nonatomic) SCNVector3 direction;

@end

@interface FeatureHitTestResult : NSObject

@property(nonatomic) SCNVector3 position;
@property(nonatomic) CGFloat distanceToRayOrigin;
@property(nonatomic) SCNVector3 featureHit;
@property(nonatomic) CGFloat featureDistanceToHitResult;

@end
