#import "UIOverlayController.h"
#import "OverlayViewController.h"
#import "XRViewer-Swift.h"

@interface UIOverlayController ()

@property (nonatomic, weak) UIView *rootView;
@property (nonatomic, strong) TouchView *touchView;
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) OverlayViewController *overlayVC;

@property (nonatomic, copy) HotAction cameraAction;
@property (nonatomic, copy) HotAction micAction;
@property (nonatomic, copy) HotAction showAction;
@property (nonatomic, copy) HotAction debugAction;

@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;
@property(nonatomic) RecordState recordState;

@end


@implementation UIOverlayController

- (void)dealloc
{
    DDLogDebug(@"UIOverlayController dealloc");
}

- (instancetype)initWithRootView:(UIView *)rootView
                    cameraAction:(HotAction)cameraAction
                       micAction:(HotAction)micAction
                      showAction:(HotAction)showAction
                     debugAction:(HotAction)debugAction
{
    self = [super init];
    
    if (self)
    {
        [self setRootView:rootView];
        
        [self setCameraAction:cameraAction];
        [self setMicAction:micAction];
        [self setShowAction:showAction];
        [self setDebugAction:debugAction];
        
        [self setupTouchView];
        [self setupOverlayWindow];
    }
    
    return self;
}

- (void)clean
{
    [[self hotView] removeFromSuperview];
    [[self overlayWindow] setHidden:YES];
    [self setOverlayWindow:nil];
}

- (UIView *)hotView
{
    return [self touchView];
}

- (void)setAnimator:(Animator *)animator
{
    _animator = animator;
    
    [[self overlayVC] setAnimator:animator];
}

- (void)setMode:(ShowMode)mode
{
    _showMode = mode;
    
    [[self overlayWindow] setAlpha:mode == ShowNothing? 0 : 1];
    
    [[self touchView] setShowMode:mode];
    
    [[self touchView] setProcessTouches:NO];
    
    [[self overlayVC] setShowMode:mode withAnimationCompletion:^(BOOL finish)
     {
         [self enableTouchesOnFinishAnimation:finish];
     }];
    
    [self viewWillTransitionToSize:[[self rootView] bounds].size];
}

- (void)setOptions:(ShowOptions)options
{
    _showOptions = options;
    
    [[self touchView] setShowOptions:options];
    [[self overlayVC] setShowOptions:options withAnimationCompletion:^(BOOL finish)
     {
     }];
}

- (void)setRecordState:(RecordState)state
{
    DDLogDebug(@"setRecordState");
    
    _recordState = state;
    
    [[self touchView] setRecordState:state];
    
    if (state == RecordStatePhoto)
    {
        [[self touchView] setProcessTouches:NO];
    }
    
    [[self overlayVC] setRecordState:state withAnimationCompletion:^(BOOL finish)
     {
         [self enableTouchesOnFinishAnimation:finish];
     }];
    
    [self viewWillTransitionToSize:[[self rootView] bounds].size];
}

- (void)setMicEnabled:(BOOL)micEnabled
{
    [[self overlayVC] setMicrophoneEnabled:micEnabled withAnimationCompletion:^(BOOL finish)
     { }];
}

- (void)setARKitInterruption:(BOOL)interruption
{
    [[self overlayWindow] setAlpha:interruption? 1 : 0];
}

- (void)setTrackingState:(NSString *)state sceneHasPlanes:(BOOL)hasPlanes {

    [[self overlayVC] setTrackingState:state withAnimationCompletion:^(BOOL finish) {} sceneHasPlanes:hasPlanes];
}

- (void)viewWillTransitionToSize:(CGSize)size
{
    CGRect updRect = CGRectMake(0, 0, size.width, size.height);
    
    if ([self showMode] >= ShowMulti)
    {
        if ([self showOptions] & Browser)
        {
            if (([self recordState] == RecordStateIsReady) ||
                ([self recordState] == RecordStateGoingToRecording) ||
                ([self recordState] >= RecordStatePreviewing))
            {
                updRect.origin.y = URL_BAR_HEIGHT;
            }
        }
    }
    
    [[self touchView] setCameraRect:recordFrameIn(updRect)
                            micRect:micFrameIn(updRect)
                           showRect:showFrameIn(updRect)
                          debugRect:debugFrameIn(updRect)];
}

#pragma mark Private

- (void)setupTouchView
{
    [self setTouchView:[[TouchView alloc] initWithFrame:[[self rootView] bounds]
                                           cameraAction:[self cameraAction]
                                              micAction:[self micAction]
                                             showAction:[self showAction]
                                            debugAction:[self debugAction]]];
    
    [self viewWillTransitionToSize:[[self rootView] bounds].size];
    
    [[self rootView] addSubview:[self touchView]];
    
    [[[[self touchView] topAnchor] constraintEqualToAnchor:[[self rootView] topAnchor]] setActive: YES];
    [[[[self touchView] bottomAnchor] constraintEqualToAnchor:[[self rootView] bottomAnchor]] setActive: YES];
    [[[[self touchView] leftAnchor] constraintEqualToAnchor:[[self rootView] leftAnchor]] setActive: YES];
    [[[[self touchView] rightAnchor] constraintEqualToAnchor:[[self rootView] rightAnchor]] setActive: YES];
    
    [[self touchView] setBackgroundColor:[UIColor clearColor]];
}

- (void)setupOverlayWindow
{
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    [self setOverlayWindow:[[UIWindow alloc] initWithFrame:[mainWindow bounds]]];
    
    [self setOverlayVC:[[OverlayViewController alloc] init]];
    [[[self overlayVC] view] setFrame:[[self overlayWindow] bounds]];
    [[self overlayWindow] setRootViewController:[self overlayVC]];
    [[self overlayWindow] setBackgroundColor:[UIColor clearColor]];
    [[self overlayWindow] setHidden:NO];
    [[self overlayWindow] setAlpha:0];
    [[self overlayWindow] setUserInteractionEnabled:NO];
    [[[self overlayVC] view] setUserInteractionEnabled:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [mainWindow makeKeyWindow];
                   });
}

- (void)enableTouchesOnFinishAnimation:(BOOL)finish
{
    if (finish)
    {
        [[self touchView] setProcessTouches:YES];
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([[self animator] animationDuration] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                       {
                           [[self touchView] setProcessTouches:YES];
                       });
    }
}

@end

