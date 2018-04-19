#import "PlaneNode.h"

@interface PlaneNode ()
@end


@implementation PlaneNode

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor
{
    self = [super init];
    
    if (self)
    {
        [self setup];
        
        [self update:anchor];
    }
    
    return self;
}

- (void)update:(ARPlaneAnchor *)anchor
{
    SCNPlane *plane = (SCNPlane *)[self geometry];
    [plane setWidth:anchor.extent.x];
    [plane setHeight:anchor.extent.z];
    
    SCNMaterial *material = [plane firstMaterial];
    [[material diffuse] setContentsTransform:SCNMatrix4MakeScale(anchor.extent.x, anchor.extent.z, 1)];
    [[material diffuse] setWrapS:SCNWrapModeRepeat];
    [[material diffuse] setWrapT:SCNWrapModeRepeat];
    
    SCNMatrix4 translateTransform = SCNMatrix4MakeTranslation(anchor.center.x, 0, anchor.center.z);
    SCNMatrix4 rotationTransform = SCNMatrix4MakeRotation(-M_PI / 2.0, 1.0, 0.0, 0.0);    

    [self setTransform:SCNMatrix4Mult(rotationTransform, translateTransform)];
}

- (void)setup
{
    SCNPlane *plane = [SCNPlane new];
    
    SCNMaterial *material = [SCNMaterial new];
    UIImage *img = [UIImage imageNamed:@"Models.scnassets/plane_grid1.png"];
    [[material diffuse] setContents:img];
    [[material diffuse] setIntensity:0.5];
    [plane setMaterials:@[material]];
    
    [self setGeometry:plane];
    [self setTransform:SCNMatrix4MakeRotation(-M_PI / 2.0, 1, 0, 0)];
    
    [self setOpacity:0];
}

@end
