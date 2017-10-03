#import <Metal/Metal.h>
#import <ARKit/ARKit.h>

NS_ASSUME_NONNULL_BEGIN

#warning DEFAULT APPLE METAL RENDER

/*
 Protocol abstracting the platform specific view in order to keep the Renderer
 class independent from platform.
 */
@protocol RenderDestinationProvider

@property (nonatomic, readonly, nullable) MTLRenderPassDescriptor *currentRenderPassDescriptor;
@property (nonatomic, readonly, nullable) id<MTLDrawable> currentDrawable;

@property (nonatomic) MTLPixelFormat colorPixelFormat;
@property (nonatomic) MTLPixelFormat depthStencilPixelFormat;
@property (nonatomic) NSUInteger sampleCount;

@end


typedef void (^CompletionUpdate)(void);

/*
 The main class performing the rendering of a session.
 */
@interface Renderer : NSObject

@property(nonatomic, copy) CompletionUpdate completionUpdate;

- (instancetype)initWithSession:(ARSession *)session metalDevice:(id<MTLDevice>)device renderDestinationProvider:(id<RenderDestinationProvider>)renderDestinationProvider;

- (void)drawRectResized:(CGSize)size orientation:(UIInterfaceOrientation)orientation;

- (void)update;

@end

NS_ASSUME_NONNULL_END
