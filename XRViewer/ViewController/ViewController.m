#import "ViewController.h"
#import "ARKController.h"
#import "WebController.h"
#import "UIOverlayController.h"
#import "RecordController.h"
#import "LocationManager.h"
#import "WebARKHeader.h"
#import "MessageController.h"
#import "Animator.h"
#import "Reachability.h"
#import "AppStateController.h"
#import "LayerView.h"

#define CLEAN_VIEW(v) [[v subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)]

#define WAITING_TIME_ON_MEMORY_WARNING .5f

typedef void (^UICompletion)(void);
#define RUN_UI_COMPLETION_ASYNC_MAIN(c) if(c){ dispatch_async(dispatch_get_main_queue(), ^{ c();}); }


@interface ViewController ()

@property (nonatomic, weak) IBOutlet LayerView *splashLayerView;
@property (nonatomic, weak) IBOutlet LayerView *arkLayerView;
@property (nonatomic, weak) IBOutlet LayerView *hotLayerView;
@property (nonatomic, weak) IBOutlet LayerView *webLayerView;

@property (nonatomic, strong) AppStateController *stateController;
@property (nonatomic, strong) ARKController *arkController;
@property (nonatomic, strong) WebController *webController;
@property (nonatomic, strong) UIOverlayController *overlayController;
@property (nonatomic, strong) RecordController *recordController;
@property (nonatomic, strong) LocationManager *locationManager;
@property (nonatomic, strong) MessageController *messageController;
@property (nonatomic, strong) Animator *animator;
@property (nonatomic, strong) Reachability *reachability;

@end


@implementation ViewController

#pragma mark UI

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCommonControllers];
    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [self setupTargetControllers];
                   });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    DDLogError(@"didReceiveMemoryWarning");
    
    [self processMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    CGAffineTransform transform = [coordinator targetTransform];
    CGFloat rotation = atan2(transform.b, transform.a);
    
    [[self arkController] viewWillTransitionToSize:size rotation:rotation];
    [[self overlayController] viewWillTransitionToSize:size];
    [[self webController] viewWillTransitionToSize:size rotation:rotation];
}

#pragma mark Setups

- (void)setupCommonControllers
{
    [self setupStateController];
    [self setupAnimator];
    [self setupMessageController];
    [self setupReachability];
    [self setupNotifications];
}

- (void)setupStateController
{
    __weak typeof (self) blockSelf = self;
    
    [self setStateController:[[AppStateController alloc] initWithState:[AppState defaultState]]];
    
    [[self stateController] setOnDebug:^(BOOL showDebug)
     {
         [[blockSelf webController] showDebug:showDebug];
     }];
    
    [[self stateController] setOnModeUpdate:^(ShowMode mode)
     {
         [[blockSelf arkController] setShowMode:mode];
         [[blockSelf overlayController] setMode:mode];
         
         [[blockSelf webController] showBar:[[blockSelf stateController] shouldShowURLBar]];
     }];
    
    [[self stateController] setOnOptionsUpdate:^(ShowOptions options)
     {
         [[blockSelf arkController] setShowOptions:options];
         [[blockSelf overlayController] setOptions:options];
         
         [[blockSelf webController] showBar:[[blockSelf stateController] shouldShowURLBar]];
     }];
    
    [[self stateController] setOnRecordUpdate:^(RecordState state)
     {
         [[blockSelf overlayController] setRecordState:state];
         [[blockSelf webController] startRecording:[[blockSelf stateController] isRecording]];
         [[blockSelf webController] showBar:[[blockSelf stateController] shouldShowURLBar]];
     }];
    
    [[self stateController] setOnXRUpdate:^(BOOL xr)
     {
         if (xr)
         {
             [blockSelf setupARKController];
             [blockSelf setupLocationController];
             
             [[blockSelf stateController] setShowMode:ShowSingle];
         }
         else
         {
             [blockSelf cleanARKController];
             
             [[blockSelf stateController] setShowMode:ShowNothing];
         }
         
         [[blockSelf webController] setupForWebXR:xr];
     }];
    
    [[self stateController] setOnReachable:^(NSString *url)
     {
         [blockSelf loadURL:url];
     }];
    
    [[self stateController] setOnEnterForeground:^(NSString *url)
     {
         [[blockSelf messageController] clean];
         [blockSelf loadURL:url];
     }];
    
    [[self stateController] setOnMemoryWarning:^(NSString *url)
     {
         [[blockSelf messageController] showMessageAboutMemoryWarningWithCompletion:^
          {
              [blockSelf loadURL:url];
          }];
     }];
    
    [[self stateController] setOnRequestUpdate:^(NSDictionary *dict)
     {
         [[blockSelf locationManager] setupForRequest:dict];
         [[blockSelf arkController] startSessionWithAppState:[[blockSelf stateController] state]];
     }];
    
    [[self stateController] setOnInterruption:^(BOOL interruption)
     {
         [[blockSelf recordController] stopRecordingByInterruption:blockSelf];
         [[blockSelf messageController] showMessageAboutARInteruption:interruption];
         
         [[blockSelf overlayController] setARKitInterruption:interruption];
         [[blockSelf webController] wasARInterruption:interruption];
     }];
    
    [[self stateController] setOnMicUpdate:^(BOOL enabled)
     {
         [[blockSelf recordController] setMicEnabled:enabled];
         [[blockSelf overlayController] setMicEnabled:enabled];
     }];
}

- (void)setupAnimator
{
    [self setAnimator:[Animator new]];
}

- (void)setupMessageController
{
    [self setMessageController:[[MessageController alloc] initWithViewController:self]];
    
    __weak typeof (self) blockSelf = self;
    
    [[self messageController] setDidShowMessage:^
     {
         [[blockSelf stateController] saveOnMessageShowMode];
         [[blockSelf stateController] setShowMode:ShowNothing];
     }];
    
    [[self messageController] setDidHideMessage:^
     {
         [[blockSelf stateController] applyOnMessageShowMode];
     }];
    
    [[self messageController] setDidHideMessageByUser:^
     {
         //[[blockSelf stateController] applyOnMessageShowMode];
     }];
}

- (void)setupNotifications
{
    __weak typeof (self) blockSelf = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note)
     {
         [blockSelf cleanARKController];
         [[blockSelf webController] didBackgroundAction:YES];
         
         [[blockSelf stateController] saveMoveToBackgroundOnURL:[[blockSelf webController] lastURL]];
     }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note)
     {
         [[blockSelf stateController] applyOnEnterForegroundAction];
     }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note)
    {
        [[blockSelf webController] didChangeOrientation:[[UIApplication sharedApplication] statusBarOrientation]
                                               withSize:[[blockSelf view] frame].size];
    }];
}

- (void)setupReachability
{
    [self setReachability:[Reachability reachabilityForInternetConnection]];
    [[self reachability] startNotifier];
    
    __weak typeof (self) blockSelf = self;
    
    void (^ReachBlock)(void) = ^
    {
        NetworkStatus netStatus = [[blockSelf reachability]  currentReachabilityStatus];
        BOOL isReachable = netStatus != NotReachable;
        DDLogDebug(@"Connection isReachable - %d", isReachable);
        
        if (isReachable)
        {
            [[blockSelf stateController] applyOnReachableAction];
        }
        else if (isReachable == NO && [[blockSelf webController] lastURL] == nil)
        {
            [[blockSelf messageController] showMessageAboutConnectionRequired];
            [[blockSelf stateController] saveNotReachableOnURL:nil];
        }
    };
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note)
     {
         ReachBlock();
     }];
    
    ReachBlock();
}

- (void)setupTargetControllers
{
    __weak typeof (self) blockSelf = self;
    
    [self setupLocationController];
    
    [self setupRecordController];
    
    if ([[self recordController] cameraAvailable])
    {
        [self setupWebController];
    }
    else
    {
        [[self recordController] requestAuthorizationWithCompletion:^(RecordController *sender)
         {
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                [blockSelf setupWebController];
                            });
         }];
    }
    
    [self setupOverlayController];
}

- (void)setupLocationController
{
    [self setLocationManager:[[LocationManager alloc] init]];
    [[self locationManager] setupForRequest:[[[self stateController] state] aRRequest]];
    
    __weak typeof (self) blockSelf = self;
    
    [[self locationManager] setEnterRegion:^(NSDictionary *dict)
     {
         [[blockSelf webController] didRegion:dict enter:YES];
    }];
    
    [[self locationManager] setExitRegion:^(NSDictionary *dict)
    {
        [[blockSelf webController] didRegion:dict enter:NO];
    }];
    
    [[self locationManager] setUpdateHeading:^(NSDictionary *dict)
    {
        [[blockSelf webController] didUpdateHeading:dict];
    }];
    
    [[self locationManager] setUpdateLocation:^(NSDictionary *dict)
    {
        [[blockSelf webController] didUpdateLocation:dict];
    }];
    
    [[self locationManager] setFail:^(NSError *error)
    {
        DDLogDebug(@"Location error - %@", error);
    }];
}

- (void)setupARKController
{
    CLEAN_VIEW([self arkLayerView]);
    __weak typeof (self) blockSelf = self;
    
    [self setArkController:[[ARKController alloc] initWithType:ARKSceneKit rootView:[self arkLayerView]]];
    
    [[self arkController] setDidUpdate:^(ARKController *c)
     {
         if ([[blockSelf stateController] shouldSendARKData])
         {
             [blockSelf sendARKData];
         }
     }];

#define CAMERA_ACCESS_NOT_AUTORIZED_CODE 103

    [[self arkController] setDidFailSession:^(NSError *error)
     {
         if ([error code] != CAMERA_ACCESS_NOT_AUTORIZED_CODE)
         {
             [[blockSelf webController] didSessionFails];
             
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                [[blockSelf messageController] showMessageAboutFailSessionWithCompletion:^
                                 {
                                     dispatch_async(dispatch_get_main_queue(), ^
                                                    {
                                                        [[blockSelf webController] reload];
                                                    });
                                 }];
                            });
         }
     }];
    
    [[self arkController] setDidInterupt:^(BOOL interruption)
     {
         [[blockSelf stateController] setARInterruption:interruption];
     }];
    
    [[self arkController] setDidChangeTrackingState:^(NSString *state)
     {
         [[blockSelf webController] didChangeARTrackingState:state];
         [[blockSelf overlayController] setTrackingState:state];
     }];
    
    [[self arkController] setDidAddPlanes:^(NSDictionary *dict)
     {
         [[blockSelf webController] didAddPlanes:dict];
    }];
    
    [[self arkController] setDidRemovePlanes:^(NSDictionary *dict)
     {
         [[blockSelf webController] didRemovePlanes:dict];
     }];
    
    [[self arkController] setDidUpdateAnchors:^(NSDictionary *dict)
     {
         [[blockSelf webController] didUpdateAnchors:dict];
     }];
    
    [[self animator] animate:[self arkLayerView] toFade:NO];
    
    [[self arkController] startSessionWithAppState:[[self stateController] state]];
}

- (void)setupWebController
{
    CLEAN_VIEW([self webLayerView]);
    
    __weak typeof (self) blockSelf = self;
    
    [self setWebController:[[WebController alloc] initWithRootView:[self webLayerView]]];
    [[self webController] setAnimator:[self animator]];
    [[self webController] setOnStartLoad:^
     {
         [[blockSelf stateController] setWebXR:NO];
     }];
    
    [[self webController] setOnFinishLoad:^
     {
         [blockSelf hideSplashWithCompletion:^
          { }];
     }];
    
    [[self webController] setOnError:^(NSError *error)
     {
         [blockSelf showWebError:error];
     }];
    
    // xr
    [[self webController] setOnInit:^(NSDictionary *uiOptionsDict)
     {
         [[blockSelf stateController] setWebXR:YES];
         [[blockSelf stateController] setShowMode:ShowSingle];
         [[blockSelf stateController] setShowOptions:showOptionsFormDict(uiOptionsDict)];
         
         [[blockSelf stateController] applyOnEnterForegroundAction];
         [[blockSelf stateController] applyOnDidReceiveMemoryAction];
     }];
    
    [[self webController] setOnLoadURL:^(NSString *url)
    {
        [[blockSelf webController] loadURL:url];
    }];
    
    [[self webController] setOnWatch:^( NSDictionary * _Nullable request)
     {
         [[blockSelf stateController] setARRequest:request];
     }];
    
    [[self webController] setOnSetUI:^(NSDictionary *uiOptionsDict)
     {
         [[blockSelf stateController] setShowOptions:showOptionsFormDict(uiOptionsDict)];
     }];
    
    [[self webController] setOnHitTest:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf arkController] hitTest:dict]);
     }];
    
    [[self webController] setOnAddAnchor:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf arkController] addAnchor:dict]);
     }];
    
    [[self webController] setOnRemoveAnchor:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf arkController] removeAnchor:dict]);
     }];
    
    [[self webController] setOnUpdateAnchor:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf arkController] updateAnchor:dict]);
     }];
    
    [[self webController] setOnStartHold:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf arkController] startHoldAnchor:dict]);
     }];
    
    [[self webController] setOnStopHold:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf arkController] stopHoldAnchor:dict]);
     }];
    
    [[self webController] setOnAddRegion:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf locationManager] addRegion:dict]);
     }];
    
    [[self webController] setOnRemoveRegion:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf locationManager] removeRegion:dict]);
     }];
    
    [[self webController] setOnInRegion:^(NSDictionary *dict, OnAction result)
     {
         result([[blockSelf locationManager] inRegion:dict]);
     }];
    
    // start
    if ([[self stateController] wasMemoryWarning])
    {
        [[self stateController] applyOnDidReceiveMemoryAction];
    }
    else
    {
        [[self webController] loadURL:WEB_URL];
    }
}

- (void)setupRecordController
{
    __weak typeof (self) blockSelf = self;
    
    RecordAction rA = ^(RecordState state)
    {
        [[blockSelf stateController] setRecordState:state];
    };
    
    [self setRecordController:[[RecordController alloc] initWithAction:rA
                                                            micEnabled:[[[self stateController] state] micEnabled]]];
    [[self recordController] setAnimator:[self animator]];
    [[self recordController] setAuthAction:^(id sender)
     {
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success)
          {}];
     }];
}

- (void)setupOverlayController
{
    CLEAN_VIEW([self hotLayerView]);
    
    __weak typeof (self) blockSelf = self;
    
    // the overlay routes the record action to the record controller directly,
    // because this action (buttons) must belong the record controoler
    HotAction cameraAction = ^(BOOL longTouch)
    {
        if (longTouch)
        {
            [[blockSelf recordController] recordAction:blockSelf];
        }
        else if ([[blockSelf recordController] isRecording]) // stop
        {
            [[blockSelf recordController] recordAction:blockSelf];
        }
        else
        {
            [[blockSelf recordController] shotAction:blockSelf];
        }
    };
    
    // mic enabling should be accepted by user in ReplayKit popup
    // this value can be changed in State comtroller on Record action
    HotAction micAction = ^(BOOL any)
    {
        [[blockSelf stateController] invertMic];
    };
    
    HotAction showAction = ^(BOOL any)
    {
        [[blockSelf stateController] invertShowMode];
    };
    
    HotAction debugAction = ^(BOOL any)
    {
        [[blockSelf stateController] invertDebugMode];
    };
    
    [[self hotLayerView] setProcessTouchInSubview:YES];
    
    [self setOverlayController:[[UIOverlayController alloc] initWithRootView:[self hotLayerView]
                                                                cameraAction:cameraAction
                                                                   micAction:micAction
                                                                  showAction:showAction
                                                                 debugAction:debugAction]];
    
    [[self overlayController] setAnimator:[self animator]];
    
    [[self overlayController] setMode:[[[self stateController] state] showMode]];
    [[self overlayController] setOptions:[[[self stateController] state] showOptions]];
    [[self overlayController] setMicEnabled:[[[self stateController] state] micEnabled]];
    [[self overlayController] setRecordState:[[[self stateController] state] recordState]];
}

#pragma mark Cleanups

- (void)cleanupCommonControllers
{
    [[self animator] clean];
    
    [[self stateController] setState:[AppState defaultState]];
    
    [[self messageController] clean];
}

- (void)cleanupTargetControllers
{
    [self setLocationManager:nil];
    [self setRecordController:nil];
    
    [self cleanWebController];
    [self cleanARKController];
    
    [self cleanOverlay];
}

- (void)cleanARKController
{
    CLEAN_VIEW([self arkLayerView]);
    [self setArkController:nil];
}

- (void)cleanWebController
{
    [[self webController] clean];
    CLEAN_VIEW([self webLayerView]);
    [self setWebController:nil];
}

- (void)cleanOverlay
{
    [[self overlayController] clean];
    CLEAN_VIEW([self hotLayerView]);
    [self setOverlayController:nil];
}

#pragma mark Splash

- (void)showSplashWithCompletion:(UICompletion)completion
{
    [[self splashLayerView] setAlpha:1];
    
    RUN_UI_COMPLETION_ASYNC_MAIN(completion);
}

- (void)hideSplashWithCompletion:(UICompletion)completion
{
    [[self splashLayerView] setAlpha:0];
    
    RUN_UI_COMPLETION_ASYNC_MAIN(completion);
}

#pragma mark MemoryWarning

- (void)processMemoryWarning
{
    [[self stateController] saveDidReceiveMemoryWarningOnURL:[[self webController] lastURL]];
    
    [self cleanupCommonControllers];
    
    [self showSplashWithCompletion:^
     {
         [self cleanupTargetControllers];
     }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(WAITING_TIME_ON_MEMORY_WARNING * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                   {
                       [self setupTargetControllers];
                       
                       [self hideSplashWithCompletion:^
                        {}];
                   });
}

#pragma mark Data

- (NSDictionary *)commonData
{
    return [[[self arkController] arkData] copy];
}

- (void)sendARKData
{
    [[self webController] sendARData:[self commonData]];
}

#pragma mark Web

- (void)showWebError:(NSError *)error
{
    if ([error code] == INTERNET_OFFLINE_CODE)
    {
        [self showSplashWithCompletion:^
         {
             [[self stateController] setShowMode:ShowNothing];
             [[self stateController] saveNotReachableOnURL:[[self webController] lastURL]];
             [[self messageController] showMessageAboutConnectionRequired];
         }];
    }
    else
    {
        [[self messageController] showMessageAboutWebError:error withCompletion:^(BOOL reload)
         {
             [self hideSplashWithCompletion:^
              {
                  if (reload)
                  {
                      [self loadURL:nil];
                  }
                  else
                  {
                      [[self stateController] applyOnMessageShowMode];
                  }
              }];
         }];
    }
}

- (void)loadURL:(NSString *)url
{
    if (url == nil)
    {
        [[self webController] reload];
    }
    else
    {
        [[self webController] loadURL:url];
    }
    
    [[self stateController] setWebXR:NO];
}

@end

