#import "ARKSceneKitController.h"
#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>
#import "PlaneNode.h"
#import "AnchorNode.h"
#import "HitAnchor.h"
#import "FocusNode.h"
#import "ARSCNView+HitTest.h"
#import "HitTestResult.h"
#import "SCNNode+Show.h"

@interface ARKSceneKitController () <ARSCNViewDelegate>

@property (nonatomic, strong) ARSession *session;
@property (nonatomic, strong) ARSCNView *renderView;
@property (nonatomic, weak) SCNCamera *camera;
@property (nonatomic, strong) NSMutableArray *anchorsNodes;

@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;

@property NSMutableDictionary *planes;
@property(copy) NSArray *planeHitTestResults;

@property(strong) HitTestResult *currentHitTest;

@property(strong) FocusNode *focus;
@property CGPoint hitTestFocusPoint;

@end

@implementation ARKSceneKitController

- (void)dealloc
{
    DDLogDebug(@"ARKSceneKitController dealloc");
}

- (instancetype)initWithSesion:(ARSession *)session
{
    self = [super init];
    
    if (self)
    {
        [self setupARWithSession:session];
        [self setPlanes:[NSMutableDictionary new]];
        [self setAnchorsNodes:[NSMutableArray new]];
        
        [self setupFocus];
    }
    
    return self;
}

- (void)updateSession:(ARSession *)session
{
    [self setSession:session];
    
    [[self renderView] setSession:session];
}

- (void)clean
{
    [[[self planes] allValues] enumerateObjectsUsingBlock:^(PlaneNode *  _Nonnull plane, NSUInteger idx, BOOL * _Nonnull stop)
    {
        [plane removeFromParentNode];
    }];
    
    [[self planes] removeAllObjects];
    
    [[self anchorsNodes] enumerateObjectsUsingBlock:^(AnchorNode *  _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop)
    {
        [node removeFromParentNode];
    }];
    
    [[self anchorsNodes] removeAllObjects];
    
    [[self focus] show:NO];
    
    [self setPlaneHitTestResults:nil];
}

- (NSArray *)hitTest:(CGPoint)point withType:(ARHitTestResultType)type
{
    return [[self renderView] hitTest:point types:type];
}

- (void)setShowMode:(ShowMode)showMode
{
    _showMode = showMode;
    
    [self updateModes];
}

- (void)setShowOptions:(ShowOptions)showOptions
{
    _showOptions = showOptions;
    
    [self updateModes];
}

- (void)updateModes
{
    if (_showMode == ShowMultiDebug)
    {
        [[self renderView] setShowsStatistics:(_showOptions & ARStatistics)];
        [[self renderView] setDebugOptions:(_showOptions & ARPoints) ? ARSCNDebugOptionShowFeaturePoints : SCNDebugOptionNone];
    }
    else
    {
        [[self renderView] setShowsStatistics:NO];
        [[self renderView] setDebugOptions:NO];
    }
}

- (matrix_float4x4)cameraProjectionTransform
{
    return SCNMatrix4ToMat4([[self camera] projectionTransform]);
}

- (void)didChangeTrackingState:(ARCamera *)camera
{
    if ([camera trackingState] != ARTrackingStateNormal)
    {
        [[self focus] show:NO];
    }
    else
    {
        [[self focus] show:([self showOptions] & ARFocus)];
    }
}

#pragma mark - Private

- (void)setupARWithSession:(ARSession *)session
{
    [self setSession:session];
    
    [self setRenderView:[[ARSCNView alloc] initWithFrame:[[UIScreen mainScreen] bounds] options:@{SCNPreferredDeviceKey : MTLCreateSystemDefaultDevice()}]];
    [[self renderView] setSession:session];
    [[self renderView] setScene:[SCNScene new]];
    [[self renderView] setShowsStatistics:NO];
    [[self renderView] setAllowsCameraControl:YES];
    [[self renderView] setAutomaticallyUpdatesLighting:NO];
    [[self renderView] setPreferredFramesPerSecond:PREFER_FPS];
    [[self renderView] setDelegate:self];
    
    [self setCamera:[[[self renderView] pointOfView] camera]];
    [[self camera] setWantsHDR:YES];
    
    [[[[self renderView] scene] lightingEnvironment] setContents:[UIColor whiteColor]];
    [[[[self renderView] scene] lightingEnvironment] setIntensity:50];
    
    [[self renderView] setAutoresizingMask:
     UIViewAutoresizingFlexibleRightMargin |
     UIViewAutoresizingFlexibleLeftMargin |
     UIViewAutoresizingFlexibleBottomMargin |
     UIViewAutoresizingFlexibleTopMargin |
     UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight];
}

#pragma mark Focus

- (void)setupFocus
{
    if ([self focus])
    {
        [[self focus] removeFromParentNode];
    }
    
    [self setFocus:[FocusNode new]];
    [[[[self renderView] scene] rootNode] addChildNode:[self focus]];
}

- (void)hitTest
{
    // hit testing only for Focus node!
    if (([self showOptions] & ARFocus))
    {
        [self setPlaneHitTestResults:
        [[self renderView] hitTestPoint:[self hitTestFocusPoint] withResult:^(HitTestResult *result)
         {
             [self setCurrentHitTest:result];
             
             [self updateFocus];
         }]];
    }
    else
    {
        [[self focus] show:NO];
    }
}

- (void)updateFocus
{
    if ([self currentHitTest])
    {
        [[self focus] show:([self showOptions] & ARFocus)];
    }
    else
    {
        [[self focus] show:NO];
    }
    
    [[self focus] updateForPosition:[[self currentHitTest] position] planeAnchor:[[self currentHitTest] anchor] camera:[[[self session] currentFrame] camera]];
}

- (void)updateCameraFocus
{
    CGFloat focusDistance = 0;
    
    if ([[self focus] opacity] > 0)
    {
        SCNVector3 focusPosition = [[self focus] position];
        SCNVector3 cameraPosition = [[[self renderView] pointOfView] position];
        
        SCNVector3 vector = SCNVector3Make(focusPosition.x - cameraPosition.x,
                                           focusPosition.y - cameraPosition.y,
                                           focusPosition.z - cameraPosition.z);
        
        focusDistance = sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z);
    }
    
    if (focusDistance > 0)
    {
        //DDLogDebug(@"Camera focus - %.1f", focusDistance);
        [[self camera] setFocusDistance:focusDistance];
    }
}

- (void)updatePlanes
{
    [[self planes] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, PlaneNode * _Nonnull obj, BOOL * _Nonnull stop)
     {
         [obj show:(([self showMode] == ShowMultiDebug) && ([self showOptions] & ARPlanes))];
     }];
}

- (void)updateAnchors
{
    [[self anchorsNodes] enumerateObjectsUsingBlock:^(SCNNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        [obj show:([self showOptions] & ARObject)];
    }];
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        CGFloat lightEstimate = [[[[self session] currentFrame] lightEstimate] ambientIntensity];
        
        [[[[self renderView] scene] lightingEnvironment] setIntensity:(lightEstimate / 40)];
        
        [self hitTest];
        
        [self updateCameraFocus];
        [self updatePlanes];
        [self updateAnchors];
    });
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if ([anchor isKindOfClass:[ARPlaneAnchor class]] )
        {
            PlaneNode *plane = [[PlaneNode alloc] initWithAnchor:(ARPlaneAnchor *)anchor];
            [[self planes] setObject:plane forKey:[anchor identifier]];
            [node addChildNode:plane];
        }
        else
        {
            AnchorNode *anchorNode = [[AnchorNode alloc] initWithAnchor:anchor];
            [node addChildNode:anchorNode];
            [[self anchorsNodes] addObject:anchorNode];
            
            // move anchor to be over the plane
            SCNMatrix4 transform = [node worldTransform];
            transform = SCNMatrix4Translate(transform, 0, ([anchorNode size]) / 2, 0);
            [node setTransform:transform];
           
        }
    });
}

- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if ([anchor isKindOfClass:[ARPlaneAnchor class]])
        {
            PlaneNode *plane = [[self planes] objectForKey:[anchor identifier]];
            [plane update:(ARPlaneAnchor *)anchor];
        }
    });
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if ([node isKindOfClass:[AnchorNode class]])
        {
            [[self anchorsNodes] removeObject:node];
        }
        else
        {
            [[self planes] removeObjectForKey:[anchor identifier]];
        }
    });
}

@end
