#import "UIOverlayController.h"
#import "TouchView.h"
#import "OverlayViewController.h"

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
                         atIndex:(NSUInteger)index
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
        
        [self setupTouchViewAtIndex:index];
        [self setupOverlayWindow];
    }
    
    return self;
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
    
    [[self overlayVC] setShowMode:mode];
    [[self touchView] setShowMode:mode];
        
    [self viewWillTransitionToSize:[[self rootView] bounds].size];
    
    [self setupTouchViewEnabled];
}

- (void)setOptions:(ShowOptions)options
{
    _showOptions = options;
    
    [[self overlayVC] setShowOptions:options];
    [[self touchView] setShowOptions:options];
}

- (void)setRecordState:(RecordState)state
{
    _recordState = state;
    
    [[self overlayVC] setRecordState:state];
    [self viewWillTransitionToSize:[[self rootView] bounds].size];
    
    [self setupTouchViewEnabled];
}

- (void)setupTouchViewEnabled
{
    BOOL touchEnabledByRecordState = (_showMode > ShowNothing) && (_recordState != RecordStateDisabled);
    
    if (touchEnabledByRecordState)
    {
        [[self touchView] setHoldTouch:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([[self animator] animationDuration] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                       {
                           [[self touchView] setHoldTouch:NO];
                       });
    }
    else
    {
        [[self touchView] setHoldTouch:YES];
    }
}

- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled
{
    [[self overlayVC] setMicrophoneEnabled:microphoneEnabled];
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

- (void)setARKitInterruption:(BOOL)interruption
{
    [[self overlayWindow] setAlpha:interruption? 1 : 0];
}

- (void)setTrackingState:(NSString *)state
{
    [[self overlayVC] setTrackingState:state];
}

#pragma mark Private

- (void)setupTouchViewAtIndex:(NSUInteger)index
{
    [self setTouchView:[[TouchView alloc] initWithFrame:[[self rootView] bounds]
                                           cameraAction:[self cameraAction]
                                              micAction:[self micAction]
                                             showAction:[self showAction]
                                            debugAction:[self debugAction]]];
    
    [self viewWillTransitionToSize:[[self rootView] bounds].size];
     
    [[self rootView] insertSubview:[self touchView] atIndex:index];
    [[self rootView] bringSubviewToFront:[self touchView]];
    
    [[self touchView] setBackgroundColor:[UIColor clearColor]];
    
    [[self touchView] setAutoresizingMask:
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight];
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

@end
