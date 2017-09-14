#import "ARKMetalController.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ARKit/ARKit.h>
#import "Renderer.h"

@interface MTKView () <RenderDestinationProvider>

@end

@interface ARKMetalController () <MTKViewDelegate>


@property (nonatomic, strong) Renderer *renderer;
@property (nonatomic, strong) MTKView *renderView;
@property CGPoint hitTestFocusPoint;

@end

@implementation ARKMetalController

- (instancetype)initWithSesion:(ARSession *)session
{
    self = [super init];
    
    if (self)
    {
        if ([self setupARWithSession:session] == NO)
        {
            return nil;
        }
    }
    
    return self;
}

- (NSArray *)hitTest:(CGPoint)point withType:(ARHitTestResultType)type
{
    return nil;
}

- (matrix_float4x4)cameraProjectionTransform
{
    return matrix_identity_float4x4;
}

- (void)didChangeTrackingState:(ARCamera *)camera
{
    
}

- (id)currentHitTest {
    return nil;
}


- (UIView *)renderView {
    return _renderView;
}

- (void)setShowMode:(ShowMode)mode {
    
}

- (void)setShowOptions:(ShowOptions)options {
    
}

- (BOOL)setupARWithSession:(ARSession *)session
{
    [self setRenderView:[[MTKView alloc] initWithFrame:[[UIScreen mainScreen] bounds] device:MTLCreateSystemDefaultDevice()]];
    [[self renderView] setBackgroundColor:[UIColor clearColor]];
    [[self renderView] setDelegate:self];
    
    if([[self renderView] device] == nil)
    {
        DDLogError(@"Metal is not supported on this device");
        return NO;
    }
    
    [self setRenderer:[[Renderer alloc] initWithSession:session metalDevice:[[self renderView] device] renderDestinationProvider:[self renderView]]];
    
    [[self renderer] drawRectResized:[[self renderView] bounds].size orientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    return YES;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[self renderer] drawRectResized:size orientation:[[UIApplication sharedApplication] statusBarOrientation]];
    });
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    [[self renderer] update];
}

@end
