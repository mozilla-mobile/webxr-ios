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
#import "Utils.h"
#import "XRViewer-Swift.h"
#import "Constants.h"

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
    
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    
    [self setupCommonControllers];
    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [self setupTargetControllers];
                   });
    
    
    UIScreenEdgePanGestureRecognizer * gestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeFromEdge:)];
    [gestureRecognizer setEdges:UIRectEdgeTop];
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    UISwipeGestureRecognizer* swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action: @selector(swipeUp:)];
    [swipeGestureRecognizer setDirection: UISwipeGestureRecognizerDirectionUp];
    swipeGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
}

- (void)swipeFromEdge: (UISwipeGestureRecognizer*)recognizer {
    if ([[[self stateController] state] webXR]) {
        [[self webController] showBar:YES];
        [[self stateController] setShowMode:ShowMulti];
    }
}

- (void)swipeUp: (UISwipeGestureRecognizer*)recognizer {
    CGPoint location = [recognizer locationInView:[self view]];
    if (location.y > SWIPE_GESTURE_AREA_HEIGHT) return;
 
    if ([[[self stateController] state] webXR]) {
        if (![[self stateController] isRecording]) {
            [[self stateController] setShowMode:ShowNothing];
        }
        [[self webController] showBar:NO];
        [[self webController] hideKeyboard];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    DDLogError(@"didReceiveMemoryWarning");
    
    [self processMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    // Disable the transition animation if we are on XR
    if ([[[self stateController] state] webXR]) {
        [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [UIView setAnimationsEnabled:YES];
        }];
        [UIView setAnimationsEnabled:NO];
    }
    
    [[self arkController] viewWillTransitionToSize:size];
    [[self overlayController] viewWillTransitionToSize:size];
    [[self webController] viewWillTransitionToSize:size];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateConstraints];
}

- (void)updateConstraints {
    // If XR is active, then the top anchor is 0 (fullscreen), else topSafeAreaInset + URL_BAR_HEIGHT
    float topSafeAreaInset = [[[UIApplication sharedApplication] keyWindow] safeAreaInsets].top;
    [[[self webController] barViewHeightAnchorConstraint] setConstant:topSafeAreaInset + URL_BAR_HEIGHT];
    [[[self webController] webViewTopAnchorConstraint] setConstant:[[[self stateController] state] webXR] ? 0.0f : topSafeAreaInset + URL_BAR_HEIGHT];

    
    [[[self webController] webViewLeftAnchorConstraint] setConstant:0.0f];
    [[[self webController] webViewRightAnchorConstraint] setConstant:0.0f];
    if (![[[self stateController] state] webXR]) {
        UIInterfaceOrientation currentOrientation = [Utils getInterfaceOrientationFromDeviceOrientation];
        if (currentOrientation == UIInterfaceOrientationLandscapeLeft) {
            // The notch is to the right
            float rightSafeAreaInset = [[[UIApplication sharedApplication] keyWindow] safeAreaInsets].right;
            [[[self webController] webViewRightAnchorConstraint] setConstant:[[[self stateController] state] webXR] ? 0.0f : -rightSafeAreaInset];
        } else if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
            // The notch is to the left
            float leftSafeAreaInset = [[[UIApplication sharedApplication] keyWindow] safeAreaInsets].left;
            [[[self webController] webViewLeftAnchorConstraint] setConstant:leftSafeAreaInset];
        }
    }

    [[self webLayerView] setNeedsLayout];
    [[self webLayerView] layoutIfNeeded];
}

- (BOOL)prefersStatusBarHidden {
    return [super prefersStatusBarHidden];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeTop;
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
         
         if (![[blockSelf stateController] isRecording]) {
             [[blockSelf webController] showBar:[[blockSelf stateController] shouldShowURLBar]];
         }
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
             [[blockSelf messageController] showMessageWithTitle:AR_SESSION_STARTED_POPUP_TITLE
                                                         message:AR_SESSION_STARTED_POPUP_MESSAGE
                                                       hideAfter:AR_SESSION_STARTED_POPUP_TIME_IN_SECONDS];
         }
         else
         {
             [blockSelf cleanARKController];
             
             [[blockSelf stateController] setShowMode:ShowNothing];
         }
         
         [blockSelf updateConstraints];
         
         [[blockSelf webController] setupForWebXR:xr];
     }];
    
    [[self stateController] setOnReachable:^(NSString *url)
     {
         [blockSelf loadURL:url];
     }];
    
    [[self stateController] setOnEnterForeground:^(NSString *url)
     {
         [[blockSelf messageController] clean];
         NSString* requestedURL = [[NSUserDefaults standardUserDefaults] stringForKey:REQUESTED_URL_KEY];
         if (requestedURL) {
             [[NSUserDefaults standardUserDefaults] setObject:nil forKey:REQUESTED_URL_KEY];
             [blockSelf loadURL:requestedURL];
         } else {
             [blockSelf loadURL:url];
         }
     }];
    
    [[self stateController] setOnMemoryWarning:^(NSString *url)
     {
         [[blockSelf messageController] showMessageAboutMemoryWarningWithCompletion:^{
             [[self webController] loadBlankHTMLString];
          }];

         [[blockSelf webController] didReceiveError: [NSError errorWithDomain:MEMORY_ERROR_DOMAIN
                                                                         code:MEMORY_ERROR_CODE
                                                                     userInfo:@{NSLocalizedDescriptionKey: MEMORY_ERROR_MESSAGE}]];
     }];
    
    [[self stateController] setOnRequestUpdate:^(NSDictionary *dict)
     {
         [[blockSelf locationManager] setupForRequest:dict];
         [[blockSelf arkController] startSessionWithAppState:[[blockSelf stateController] state]];
     }];
    
    [[self stateController] setOnInterruption:^(BOOL interruption)
     {
         [[blockSelf recordController] stopRecordingByInterruption:blockSelf];
         [[blockSelf messageController] showMessageAboutARInterruption:interruption];
         
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [[self arkController] setShouldUpdateWindowSize: YES];
    [self updateConstraints];
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
    [[self arkController] setDidFailSession:^(NSError *error)
    {
        NSString* errorMessage = @"ARKit Error";
        switch ([error code]) {
            case CAMERA_ACCESS_NOT_AUTHORIZED_ARKIT_ERROR_CODE:
                // If there is a camera access error, do nothing
                return;
            case UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_CODE:
                errorMessage = UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_MESSAGE;
                break;
            case SENSOR_UNAVAILABLE_ARKIT_ERROR_CODE:
                errorMessage = SENSOR_UNAVAILABLE_ARKIT_ERROR_MESSAGE;
                break;
            case SENSOR_FAILED_ARKIT_ERROR_CODE:
                errorMessage = SENSOR_FAILED_ARKIT_ERROR_MESSAGE;
                break;
            case WORLD_TRACKING_FAILED_ARKIT_ERROR_CODE:
                errorMessage = WORLD_TRACKING_FAILED_ARKIT_ERROR_MESSAGE;
                break;

            default:
                break;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[blockSelf messageController] showMessageAboutFailSessionWithMessage:errorMessage completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self webController] loadBlankHTMLString];
                });
            }];

            [[blockSelf webController] didReceiveError: error];
        });
     }];
    
    [[self arkController] setDidInterupt:^(BOOL interruption)
     {
         [[blockSelf stateController] setARInterruption:interruption];
     }];
    
    [[self arkController] setDidChangeTrackingState:^(NSString *state)
     {
         [[blockSelf webController] didChangeARTrackingState:state];

         // When the tracking state changes, we let the overlay controller know about that,
         // providing the tracking state string, and also a boolean indicating if the scene has any plane anchor.
         // The overlay controller will decide on the warning message to show
         [[blockSelf overlayController] setTrackingState:state
                                          sceneHasPlanes:[[[blockSelf arkController] currentPlanesArray] count] > 0];
     }];

    [[self arkController] setDidAddPlaneAnchors:^{
        // When a new plane is added, we pass the tracking state and whether the scene has planes or not to the
        // overlay controller. He will decide on the warning message to show
        [[blockSelf overlayController] setTrackingState:[[self arkController] trackingState]
                                         sceneHasPlanes:[[[blockSelf arkController] currentPlanesArray] count] > 0];
    }];

    [[self arkController] setDidRemovePlaneAnchors:^{
        // When a new plane is removed, we pass the tracking state and whether the scene has planes or not to the
        // overlay controller. He will decide on the warning message to show
        [[blockSelf overlayController] setTrackingState:[[self arkController] trackingState]
                                         sceneHasPlanes:[[[blockSelf arkController] currentPlanesArray] count] > 0];
    }];

    [[self arkController] setDidUpdateWindowSize:^{
        [[blockSelf webController] updateWindowSize];
    }];

    [[self animator] animate:[self arkLayerView] toFade:NO];
    
    [[self arkController] startSessionWithAppState:[[self stateController] state]];
    
    // Log event when we start an AR session
    [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodWebXR object:EventObjectInitialize];
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
    
    [[self webController] setOnInit:^(NSDictionary *uiOptionsDict)
     {
         [[blockSelf stateController] setWebXR:YES];
         [[blockSelf stateController] setShowMode:ShowSingle];
         [[blockSelf stateController] setShowOptions:showOptionsFormDict(uiOptionsDict)];
         
         [[blockSelf stateController] applyOnEnterForegroundAction];
         [[blockSelf stateController] applyOnDidReceiveMemoryAction];
     }];
    
    [[self webController] setOnError:^(NSError *error)
     {
         [blockSelf showWebError:error];
     }];
    
    [[self webController] setOnIOSUpdate:^( NSDictionary * _Nullable request)
     {
         [[blockSelf stateController] setARRequest:request];
     }];
    
    [[self webController] setOnJSUpdate:^( NSDictionary * _Nullable request)
     {
         [[blockSelf stateController] setARRequest:request];
     }];
    
    [[self webController] setOnJSUpdateData:^NSDictionary *
     {
         return [blockSelf commonData];
     }];
    
    [[self webController] setLoadURL:^(NSString *url)
     {
         [[blockSelf webController] loadURL:url];
     }];
    
    [[self webController] setOnSetUI:^(NSDictionary *uiOptionsDict)
     {
         [[blockSelf stateController] setShowOptions:showOptionsFormDict(uiOptionsDict)];
     }];
    
    [[self webController] setOnHitTest:^(NSUInteger mask, CGFloat x, CGFloat y, ResultArrayBlock result)
     {
         result([[blockSelf arkController] hitTestNormPoint:CGPointMake(x, y) types:mask]);
     }];
    
    [[self webController] setOnAddAnchor:^(NSString *name, NSArray *transformArray, ResultBlock result)
     {
         if ([[blockSelf arkController] addAnchor:name transform:transformArray])
         {
             result(@{WEB_AR_UUID_OPTION : name, WEB_AR_TRANSFORM_OPTION : transformArray});
         }
         else
         {
             result(@{});
         }
     }];
    
    [[self webController] setOnRemoveObjects:^(NSArray *objects)
     {
         [[blockSelf arkController] removeAnchors:objects];
     }];
    
    [[self webController] setOnDebugButtonToggled:^(BOOL selected) {
        [[blockSelf arkController] setShowMode:selected? ShowMultiDebug: ShowNothing];
    }];
    
    [[self webController] setOnSettingsButtonTapped:^{
        // Before showing the settings popup, we hide the bar and the debug buttons so they are not in the way
        // After dismissing the popup, we show them again.
        /*
        [[blockSelf webController] showBar:NO];
        [[blockSelf webController] hideKeyboard];
        [[blockSelf stateController] setShowMode:ShowNothing];
        [[blockSelf messageController] showSettingsPopup: ^(BOOL response) {
            if (response) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success)
                 {}];
            }
            [[blockSelf webController] showBar:YES];
            [[blockSelf stateController] setShowMode:ShowMulti];
        }];
         */
        
        SettingsViewController* settingsViewController = [SettingsViewController new];
        UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
        __weak typeof (SettingsViewController*) weakSettingsViewController = settingsViewController;
        settingsViewController.onDoneButtonTapped = ^{
            [weakSettingsViewController dismissViewControllerAnimated:YES completion:nil];
            [[blockSelf webController] showBar:YES];
            [[blockSelf stateController] setShowMode:ShowMulti];
        };

        [[blockSelf webController] showBar:NO];
        [[blockSelf webController] hideKeyboard];
        [[blockSelf stateController] setShowMode:ShowNothing];
        [blockSelf presentViewController:navigationController animated:YES completion:nil];
    }];
    
    if ([[self stateController] wasMemoryWarning])
    {
        [[self stateController] applyOnDidReceiveMemoryAction];
    }
    else
    {
        NSString* requestedURL = [[NSUserDefaults standardUserDefaults] stringForKey:REQUESTED_URL_KEY];
        if (requestedURL && ![requestedURL isEqualToString:@""]) {
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:REQUESTED_URL_KEY];
            [[self webController] loadURL:requestedURL];
        } else {
            NSString* lastURL = [[NSUserDefaults standardUserDefaults] stringForKey:LAST_URL_KEY];
            if (lastURL) {
                [[self webController] loadURL:lastURL];
            } else {
                NSString* homeURL = [[NSUserDefaults standardUserDefaults] stringForKey:homeURLKey];
                if (homeURL && ![homeURL isEqualToString:@""]) {
                    [[self webController] loadURL:homeURL];
                } else {
                    [[self webController] loadURL:WEB_URL];
                }
            }
        }
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
    
    [[self overlayController] setOnSwipeDown:^{
        if ([[[blockSelf stateController] state] webXR]) {
            [[blockSelf webController] showBar:YES];
            [[blockSelf stateController] setShowMode:ShowMulti];
        }
    }];
    
    [[self overlayController] setOnSwipeUp:^{
        if ([[[blockSelf stateController] state] webXR]) {
            if (![[blockSelf stateController] isRecording]) {
                [[blockSelf stateController] setShowMode:ShowNothing];
            }
            [[blockSelf webController] showBar:NO];
            [[blockSelf webController] hideKeyboard];
        }
    }];
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
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    [dictionary setValuesForKeysWithDictionary:[[self arkController] arkData]];
    
    return [dictionary copy];
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

