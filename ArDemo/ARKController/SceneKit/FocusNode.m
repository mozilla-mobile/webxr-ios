#import "FocusNode.h"

#define FOCUS_SQUARE_SIZE 0.17

@interface SCNNode (ARDemo)
- (void)setUniformScale:(CGFloat)scale;
@end

@implementation SCNNode (ARDemo)

- (void)setUniformScale:(CGFloat)scale
{
    [self setScale:SCNVector3Make(scale, scale, scale)];
}

@end


@interface FocusNode ()

@property(nonatomic) SCNVector3 lastPositionOnPlane;
@property(nonatomic) SCNVector3 lastPosition;
@property(nonatomic, strong) NSMutableArray *recentFocusSquarePositions;
@property(nonatomic, strong) NSMutableSet *anchorOfVisitedPlanes;
@property BOOL isAnimating;
@property BOOL isOpen;


@property(nonatomic, strong) SCNNode *onNode;
@property(nonatomic, strong) SCNNode *offNode;

@end

@implementation FocusNode

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setOpacity:0];
        
        [self setRecentFocusSquarePositions:[NSMutableArray new]];
        [self setAnchorOfVisitedPlanes:[NSMutableSet new]];
        
        SCNNode *nodeOn = [SCNNode node];
        SCNPlane *planeOn = [SCNPlane planeWithWidth:FOCUS_SQUARE_SIZE height:FOCUS_SQUARE_SIZE];
        
        SCNMaterial *materialOn = [SCNMaterial new];
        UIImage *imgOn = [UIImage imageNamed:@"Models.scnassets/yes_white.png"];
        [[materialOn diffuse] setContents:imgOn];
        //[[materialOn diffuse] setIntensity:0.5];
        [planeOn setMaterials:@[materialOn]];
        
        [nodeOn setGeometry:planeOn];
        [nodeOn setTransform:SCNMatrix4MakeRotation(-M_PI / 2.0, 1, 0, 0)];
        [self addChildNode:nodeOn];
        [self setOnNode:nodeOn];
        
        
        SCNNode *nodeOff = [SCNNode node];
        SCNPlane *planeOff = [SCNPlane planeWithWidth:FOCUS_SQUARE_SIZE height:FOCUS_SQUARE_SIZE];
        
        SCNMaterial *materialOff = [SCNMaterial new];
        UIImage *imgOff = [UIImage imageNamed:@"Models.scnassets/no_white.png"];
        [[materialOff diffuse] setContents:imgOff];
        //[[materialOff diffuse] setIntensity:0.5];
        [planeOff setMaterials:@[materialOff]];
        
        [nodeOff setGeometry:planeOff];
        [nodeOff setTransform:SCNMatrix4MakeRotation(-M_PI / 2.0, 1, 0, 0)];
        [self addChildNode:nodeOff];
        [self setOffNode:nodeOff];
    }
    
    return self;
}

- (void)updateForPosition:(SCNVector3)position planeAnchor:(ARPlaneAnchor *)anchor camera:(ARCamera *)camera
{
    [self setLastPosition:position];
    
    if (anchor)
    {
        [self setLastPositionOnPlane:position];
        [_anchorOfVisitedPlanes addObject:anchor];
        
        [_onNode setOpacity:1];
        [_offNode setOpacity:0];
    }
    else
    {
        [_onNode setOpacity:0];
        [_offNode setOpacity:1];
    }
    
    [self runAction:[SCNAction customActionWithDuration:0.5 actionBlock:^(SCNNode * _Nonnull node, CGFloat elapsedTime)
    {
        [self updateTransformForPosition:position camera:camera];
    }]];
}

- (SCNVector3)averageFromRecentPositions
{
    __block CGFloat x = 0, y = 0, z = 0;
    
    [_recentFocusSquarePositions enumerateObjectsUsingBlock:^(NSValue * _Nonnull posValue, NSUInteger idx, BOOL * _Nonnull stop)
    {
        x += [posValue SCNVector3Value].x;
        y += [posValue SCNVector3Value].y;
        z += [posValue SCNVector3Value].z;
    }];
    
    return SCNVector3Make(x / [_recentFocusSquarePositions count], y / [_recentFocusSquarePositions count], z / [_recentFocusSquarePositions count]);
}

- (void)updateTransformForPosition:(SCNVector3)position camera:(ARCamera *)camera
{
    // add to list of recent positions
    [_recentFocusSquarePositions addObject:[NSValue valueWithSCNVector3:position]];
    
    // remove anything older than the last 8
    NSInteger toRemove = [_recentFocusSquarePositions count] - 8;
    
    if (toRemove > 0)
    {
        [_recentFocusSquarePositions removeObjectsInRange:NSMakeRange(0, toRemove)];
    }
    
    // move to average of recent positions to avoid jitter
    self.position = [self averageFromRecentPositions];
    
    
    CGFloat scale = [self scaleBasedOnDistance:camera];
    [self setUniformScale:scale];
    
    // Correct y rotation of camera square
    CGFloat tilt = fabs([camera eulerAngles].x);
    CGFloat threshold1 = M_PI / 2 * 0.65;
    CGFloat threshold2 = M_PI / 2 * 0.75;
    CGFloat yaw = atan2([camera transform].columns[0].x, [camera transform].columns[1].x);
    CGFloat angle = 0;
    
    if (tilt > 0 && tilt < threshold1)
    {
        angle = [camera eulerAngles].y;
    }
    else if (tilt >= threshold1 && tilt < threshold2)
    {
        CGFloat relativeInRange = fabs((tilt - threshold1) / (threshold2 - threshold1));
        CGFloat normalizedY = [self normalizeAngle:[camera eulerAngles].y forMinimalRotationTo:yaw];
        angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange;
    }
    else
    {
        angle = yaw;
    }
    
    [self setRotation:SCNVector4Make(0, 1, 0, angle)];
}

- (CGFloat)normalizeAngle:(CGFloat)angle forMinimalRotationTo:(CGFloat)rotation
{
    // Normalize angle in steps of 90 degrees such that the rotation to the other angle is minimal
    CGFloat normalized = angle;
    
    while (fabs(normalized - rotation) > M_PI / 4)
    {
        if (angle > rotation)
        {
            normalized -= M_PI / 2;
        }
        else
        {
            normalized += M_PI / 2;
        }
    }
    
    return normalized;
}

- (CGFloat)scaleBasedOnDistance:(ARCamera *)camera
{
    if (camera)
    {
        SCNVector3 diff = SCNVector3Make([self worldPosition].x - [camera transform].columns[3].x, [self worldPosition].y - [camera transform].columns[3].y, [self worldPosition].z - [camera transform].columns[3].z);
        
        CGFloat distanceFromCamera = sqrtf(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z);
        
        // This function reduces size changes of the focus square based on the distance by scaling it up if it far away,
        // and down if it is very close.
        // The values are adjusted such that scale will be 1 in 0.7 m distance (estimated distance when looking at a table),
        // and 1.2 in 1.5 m distance (estimated distance when looking at the floor).
        CGFloat newScale = distanceFromCamera < 0.7 ? (distanceFromCamera / 0.7) : (0.25 * distanceFromCamera + 0.825);
        
        return newScale;
    }
    
    return 1;
}

@end
