#import "AnchorNode.h"
#import "ARKHelper.h"

typedef NS_ENUM(NSUInteger, AnchorFigure)
{
    AnchorBox,
    AnchorSphere,
    AnchorPyramid,
    AnchorCylinder,
    AnchorCone,
    AnchorTube,
    AnchorCapsule,
    AnchorTorus,
    AnchorFugureCount
};

@interface AnchorNode ()
@property AnchorFigure figure;
@end

@implementation AnchorNode

- (void)dealloc
{
    DDLogDebug(@"- anchor");
}

- (instancetype)initWithAnchor:(ARAnchor *)anchor
{
    self = [super init];
    
    DDLogDebug(@"+ anchor");
    
    if (self)
    {
        _figure = AnchorBox;//arc4random() % AnchorPyramid;
        
        switch (_figure)
        {
            case AnchorBox:
                [self setupBox];
                break;
            case AnchorPyramid:
                [self setupPiramide];
                break;
            case AnchorSphere:
                [self setupSphere];
                break;
            case AnchorCylinder:
                [self setupCylinder];
                break;
            case AnchorCone:
                [self setupCone];
                break;
            case AnchorTube:
                [self setupTube];
                break;
            case AnchorCapsule:
                [self setupCapsule];
                break;
            case AnchorTorus:
                [self setupTorus];
                break;
            default:
                break;
        }
        
        [self setOpacity:0];
    }
    
    return self;
}

- (CGFloat)size
{
    switch (_figure)
    {
        case AnchorBox:
            return [(SCNBox *)[self geometry] width];
        case AnchorPyramid:
            return [(SCNPyramid *)[self geometry] width];
        case AnchorSphere:
            return [(SCNSphere *)[self geometry] radius];
        case AnchorCylinder:
            return [(SCNCylinder *)[self geometry] height];
        case AnchorCone:
            return [(SCNCone *)[self geometry] height];
        case AnchorTube:
            return [(SCNTube *)[self geometry] height];
        case AnchorCapsule:
            return [(SCNCapsule *)[self geometry] height];
        case AnchorTorus:
            return [(SCNTorus *)[self geometry] pipeRadius];
        default:
            break;
    }
    
    return 0;
}

- (void)setupTorus
{
    SCNGeometry *geometry = [SCNTorus torusWithRingRadius:BOX_SIZE pipeRadius:BOX_SIZE / 3];
    
    UIColor *materialColor;
    NSUInteger col = rand() % 7;
    switch (col)
    {
        case 0:
            materialColor = [UIColor greenColor];
            break;
        case 1:
            materialColor = [UIColor redColor];
            break;
        case 2:
            materialColor = [UIColor blueColor];
            break;
        case 3:
            materialColor = [UIColor greenColor];
            break;
        case 4:
            materialColor = [UIColor yellowColor];
            break;
        case 5:
            materialColor = [UIColor purpleColor];
            break;
        case 6:
            materialColor = [UIColor magentaColor];
            
            break;
        default:
            break;
    }

    geometry.materials = @[[self anchorMaterialWithColor:materialColor]];
    
    [self setGeometry:geometry];
}

- (void)setupCapsule
{
    SCNGeometry *geometry = [SCNCapsule capsuleWithCapRadius:BOX_SIZE height:BOX_SIZE];
    
    UIColor *materialColor;
    
    NSUInteger col = rand() % 7;
    switch (col)
    {
        case 0:
            materialColor = [UIColor greenColor];
            break;
        case 1:
            materialColor = [UIColor redColor];
            break;
        case 2:
            materialColor = [UIColor blueColor];
            break;
        case 3:
            materialColor = [UIColor greenColor];
            break;
        case 4:
            materialColor = [UIColor yellowColor];
            break;
        case 5:
            materialColor = [UIColor purpleColor];
            break;
        case 6:
            materialColor = [UIColor magentaColor];
            break;
        default:
            break;
    }
    
    geometry.materials = @[[self anchorMaterialWithColor:materialColor]];
    
    [self setGeometry:geometry];
}

- (void)setupTube
{
    SCNGeometry *geometry = [SCNTube tubeWithInnerRadius:(BOX_SIZE - BOX_SIZE / 5) outerRadius:BOX_SIZE height:BOX_SIZE];
    
    geometry.materials =  @[
                            [self anchorMaterialWithColor:[UIColor yellowColor]],
                            [self anchorMaterialWithColor:[UIColor purpleColor]],
                            [self anchorMaterialWithColor:[UIColor magentaColor]]];
    
    [self setGeometry:geometry];
}

- (void)setupCone
{
    SCNGeometry *geometry = [SCNCone coneWithTopRadius:BOX_SIZE/2 bottomRadius:BOX_SIZE height:BOX_SIZE];
    
    geometry.materials =  @[
                            [self anchorMaterialWithColor:[UIColor redColor]],
                            [self anchorMaterialWithColor:[UIColor greenColor]],
                            [self anchorMaterialWithColor:[UIColor blueColor]]];
    
    [self setGeometry:geometry];
}

- (void)setupCylinder
{
    SCNGeometry *geometry = [SCNCylinder cylinderWithRadius:BOX_SIZE height:BOX_SIZE];
    
    geometry.materials =  @[
                            [self anchorMaterialWithColor:[UIColor orangeColor]],
                            [self anchorMaterialWithColor:[UIColor grayColor]],
                            [self anchorMaterialWithColor:[UIColor blueColor]]];
    
    [self setGeometry:geometry];
}

- (void)setupSphere
{
    SCNGeometry *geometry = [SCNSphere sphereWithRadius:BOX_SIZE];
    
    UIColor *materialColor;
    
    NSUInteger col = rand() % 7;
    switch (col)
    {
        case 0:
            materialColor = [UIColor greenColor];
            break;
        case 1:
            materialColor = [UIColor redColor];
            break;
        case 2:
            materialColor = [UIColor blueColor];
            break;
        case 3:
            materialColor = [UIColor greenColor];
            break;
        case 4:
            materialColor = [UIColor yellowColor];
            break;
        case 5:
            materialColor = [UIColor purpleColor];
            break;
        case 6:
            materialColor = [UIColor magentaColor];
            break;
        default:
            break;
    }
    
    geometry.materials = @[[self anchorMaterialWithColor:materialColor]];
    
    [self setGeometry:geometry];
}

- (void)setupPiramide
{
    SCNGeometry *geometry = [SCNPyramid pyramidWithWidth:BOX_SIZE height:BOX_SIZE length:BOX_SIZE];
    
    geometry.materials =  @[
                            [self anchorMaterialWithColor:[UIColor redColor]],
                            [self anchorMaterialWithColor:[UIColor greenColor]],
                            [self anchorMaterialWithColor:[UIColor blueColor]],
                            [self anchorMaterialWithColor:[UIColor yellowColor]],
                            [self anchorMaterialWithColor:[UIColor purpleColor]]];
    
    [self setGeometry:geometry];
}

- (void)setupBox
{
    SCNGeometry *geometry = [SCNBox boxWithWidth:BOX_SIZE height:BOX_SIZE length:BOX_SIZE chamferRadius:(BOX_SIZE / 20)];
    
    geometry.materials =  @[
                            [self anchorMaterialWithColor:[UIColor redColor]],
                            [self anchorMaterialWithColor:[UIColor greenColor]],
                            [self anchorMaterialWithColor:[UIColor blueColor]],
                            [self anchorMaterialWithColor:[UIColor yellowColor]],
                            [self anchorMaterialWithColor:[UIColor purpleColor]],
                            [self anchorMaterialWithColor:[UIColor magentaColor]]];
    
    [self setGeometry:geometry];
}

- (SCNMaterial *)anchorMaterialWithColor:(UIColor *)color
{
    SCNMaterial *material = [SCNMaterial material];
    [material setFillMode:SCNFillModeFill];
    [[material diffuse] setContents:color];
    [[material specular] setContents:[UIColor whiteColor]];
    [material setLocksAmbientWithDiffuse:YES];
    
    return material;
}

@end
