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

// #define WEBSERVER
#ifdef WEBSERVER
#import "GCDWebServer.h"
#endif

#define CLEAN_VIEW(v) [[v subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)]

#define WAITING_TIME_ON_MEMORY_WARNING .5f

typedef void (^UICompletion)(void);
#define RUN_UI_COMPLETION_ASYNC_MAIN(c) if(c){ dispatch_async(dispatch_get_main_queue(), ^{ c();}); }

#ifdef WEBSERVER
@interface ViewController ()  <GCDWebServerDelegate>
#else
@interface ViewController ()
#endif

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
@property (nonatomic, strong) NSTimer* timerSessionRunningInBackground;

@end


@implementation ViewController {
#ifdef WEBSERVER
@private
    GCDWebServer* _webServer;
#endif
}


#pragma mark UI

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /// This causes UIKit to call preferredScreenEdgesDeferringSystemGestures,
    /// so we can say what edges we want our gestures to take precedence over the system gestures
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    
    [self setupCommonControllers];
    
    /// Apparently, this is called async in the main queue because we need viewDidLoad to finish
    /// its execution before doing anything on the subviews. This also could have been called from
    /// viewDidAppear
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [self setupTargetControllers];
                   });
    
    
    /// Swipe from edge gesture recognizer setup
    UIScreenEdgePanGestureRecognizer * gestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeFromEdge:)];
    [gestureRecognizer setEdges:UIRectEdgeTop];
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    UISwipeGestureRecognizer* swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action: @selector(swipeUp:)];
    [swipeGestureRecognizer setDirection: UISwipeGestureRecognizerDirectionUp];
    swipeGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    
    /// Show the permissions popup if we have never shown it
    if ([[NSUserDefaults standardUserDefaults] boolForKey:permissionsUIAlreadyShownKey] == NO &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ||
         [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == kCLAuthorizationStatusNotDetermined)) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:permissionsUIAlreadyShownKey];
                [[self messageController] showPermissionsPopup];
            });
    }
}

#ifdef WEBSERVER

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    [options setObject:@8080 forKey:GCDWebServerOption_Port];
    //[options setObject:@NO forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
    
    NSString *documentsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
        _webServer = [[GCDWebServer alloc] init];
        [_webServer addGETHandlerForBasePath:@"/" directoryPath:documentsPath indexFilename:@"index.html" cacheAge:0 allowRangeRequests:YES];
        
        _webServer.delegate = self;
        if ([_webServer startWithOptions:options error:NULL]) {
            NSLog(@"GCDWebServer running locally on port %i", (int)_webServer.port);
        } else {
            NSLog(@"GCDWebServer not running!");
        }
    } else {
        NSLog(@"No Web directory, GCDWebServer not running!");
    }
}

#endif

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
#ifdef WEBSERVER
    [_webServer stop];
    _webServer = nil;
#endif
}

- (void)swipeFromEdge: (UISwipeGestureRecognizer*)recognizer {
    if ([[[self stateController] state] webXR]) {
        if ([[self webController] isDebugButtonSelected]) {
            [[self stateController] setShowMode: ShowMultiDebug];
        } else {
            [[self stateController] setShowMode: ShowMulti];
        }
    }
}

- (void)swipeUp: (UISwipeGestureRecognizer*)recognizer {
    CGPoint location = [recognizer locationInView:[self view]];
    if (location.y > SWIPE_GESTURE_AREA_HEIGHT) return;
 
    if ([[[self stateController] state] webXR]) {
        if (![[self stateController] isRecording]) {
            if ([[self webController] isDebugButtonSelected]) {
                [[self stateController] setShowMode: ShowDebug];
            } else {
                [[self stateController] setShowMode: ShowNothing];
            }
        }
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
             if ([[blockSelf webController] isDebugButtonSelected]) {
                [[blockSelf stateController] setShowMode:ShowDebug];
             } else {
                [[blockSelf stateController] setShowMode:ShowNothing];
             }
             
             if ([[[blockSelf stateController] state] shouldShowSessionStartedPopup]) {
                 [[[blockSelf stateController] state] setShouldShowSessionStartedPopup:NO];
                 [[blockSelf messageController] showMessageWithTitle:AR_SESSION_STARTED_POPUP_TITLE
                                                             message:AR_SESSION_STARTED_POPUP_MESSAGE
                                                           hideAfter:AR_SESSION_STARTED_POPUP_TIME_IN_SECONDS];
             }
             
             [[blockSelf webController] setLastXRVisitedURL:[[[[blockSelf webController] webView] URL] absoluteString]];
         }
         else {
             [[blockSelf stateController] setShowMode:ShowNothing];
             if ([[blockSelf arkController] arSessionState] == ARKSessionRunning) {
                 [blockSelf.timerSessionRunningInBackground invalidate];
                 NSInteger timerSeconds = [[NSUserDefaults standardUserDefaults] integerForKey:secondsInBackgroundKey];
                 NSLog(@"\n\n*********\n\nMoving away from an XR site, keep ARKit running, and launch the timer for %ld seconds\n\n*********", timerSeconds);
                 blockSelf.timerSessionRunningInBackground = [NSTimer scheduledTimerWithTimeInterval:timerSeconds repeats:NO block:^(NSTimer * _Nonnull timer) {
                     NSLog(@"\n\n*********\n\nTimer expired, pausing session\n\n*********");
                     [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"backgroundOrPausedDateKey"];
                     [[blockSelf arkController] pauseSession];
                     [timer invalidate];
                 }];
             }
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
         [[[blockSelf stateController] state] setShouldRemoveAnchorsOnNextARSession: NO];
         
         [[blockSelf messageController] clean];
         NSString* requestedURL = [[NSUserDefaults standardUserDefaults] stringForKey:REQUESTED_URL_KEY];
         if (requestedURL) {
             NSLog(@"\n\n*********\n\nMoving to foreground because the user wants to open a URL externally, loading the page\n\n*********");
             [[NSUserDefaults standardUserDefaults] setObject:nil forKey:REQUESTED_URL_KEY];
             [blockSelf loadURL:requestedURL];
         } else {
             switch ([[blockSelf arkController] arSessionState]) {
                 case ARKSessionUnknown: {
                     NSLog(@"\n\n*********\n\nMoving to foreground while ARKit is not initialized, do nothing\n\n*********");
                     break;
                 }
                 case ARKSessionPaused: {
                     NSLog(@"\n\n*********\n\nMoving to foreground while the session is paused, remember to remove anchors on next AR request\n\n*********");
                     [[[blockSelf stateController] state] setShouldRemoveAnchorsOnNextARSession: YES];
                     break;
                 }
                     
                 case ARKSessionRunning: {
                     NSDate *interruptionDate = [[NSUserDefaults standardUserDefaults] objectForKey:backgroundOrPausedDateKey];
                     NSDate *now = [NSDate date];
                     if ([now timeIntervalSinceDate:interruptionDate] >= pauseTimeInSecondsToRemoveAnchors) {
                         NSLog(@"\n\n*********\n\nMoving to foreground while the session is running and it was in BG for a long time, remove the anchors\n\n*********");
                         [[blockSelf arkController] removeAllAnchors];
                     } else {
                         NSLog(@"\n\n*********\n\nMoving to foreground while the session is running and it was in BG for a short time, do nothing\n\n*********");
                     }
                     break;
                 }
             }
         }
         
         [[NSUserDefaults standardUserDefaults] setObject:nil forKey:backgroundOrPausedDateKey];
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
         NSLog(@"\n\n*********\n\nInvalidate timer\n\n*********");
         [[blockSelf timerSessionRunningInBackground] invalidate];
         
         if (![blockSelf arkController]) {
             NSLog(@"\n\n*********\n\nARKit is nil, instantiate and start a session\n\n*********");
             [blockSelf startNewARKitSessionWithRequest:dict];
         } else {
             switch ([[blockSelf arkController] arSessionState]) {
                 case ARKSessionUnknown: {
                     NSLog(@"\n\n*********\n\nARKit is in unknown state, instantiate and start a session\n\n*********");
                     [[blockSelf arkController] runSessionWithAppState:[[blockSelf stateController] state]];
                     break;
                 }
                     
                 case ARKSessionRunning: {
                     if ([blockSelf urlIsNotTheLastXRVisitedURL]) {
                         NSLog(@"\n\n*********\n\nThis site is not the last XR site visited, and the timer hasn't expired yet. Remove distant anchors and continue with the session\n\n*********");
                         [[blockSelf arkController] removeDistantAnchors];
                         [[blockSelf arkController] runSessionWithAppState:[[blockSelf stateController] state]];
                     } else {
                         NSLog(@"\n\n*********\n\nThis site is the last XR site visited, and the timer hasn't expired yet. Continue with the session\n\n*********");
                     }
                     break;
                 }
                     
                 case ARKSessionPaused: {
                     NSLog(@"\n\n*********\n\nRequest of a new AR session when it's paused\n\n*********");
                     if ([[[blockSelf stateController] state] shouldRemoveAnchorsOnNextARSession]) {
                         NSLog(@"\n\n*********\n\nRun session removing anchors\n\n*********");
                         [[[blockSelf stateController] state] setShouldRemoveAnchorsOnNextARSession:NO];
                         [[blockSelf arkController] runSessionRemovingAnchorsWithAppState:[[blockSelf stateController] state]];
                     } else {
                         NSLog(@"\n\n*********\n\nResume session\n\n*********");
                         [[blockSelf arkController] resumeSessionWithAppState:[[blockSelf stateController] state]];
                     }
                     break;
                 }
             }
         }
         if ([dict[WEB_AR_CV_INFORMATION_OPTION] boolValue]) {
             [[[blockSelf stateController] state] setComputerVisionFrameRequested:YES];
             [[[blockSelf stateController] state] setSendComputerVisionData:YES];
         }
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

-(BOOL)urlIsNotTheLastXRVisitedURL {
    return ![[[[[self webController] webView] URL] absoluteString] isEqualToString:[[self webController] lastXRVisitedURL]];
}

- (void)startNewARKitSessionWithRequest: (NSDictionary*)request {
    [self setupLocationController];
    [[self locationManager] setupForRequest:request];
    [self setupARKController];
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
         switch ([[blockSelf arkController] arSessionState]) {
             case ARKSessionUnknown:
                 NSLog(@"\n\n*********\n\nMoving to background while ARKit is not initialized, nothing to do\n\n*********");
                 break;
             case ARKSessionPaused:
                 NSLog(@"\n\n*********\n\nMoving to background while the session is paused, nothing to do\n\n*********");
                 break;
             case ARKSessionRunning:
                 NSLog(@"\n\n*********\n\nMoving to background while the session is running, store the timestamp\n\n*********");
                 [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:backgroundOrPausedDateKey];
                 break;
         }
         
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
    [self setupLocationController];
    
    [self setupRecordController];
    
    [self setupWebController];
    
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
         if ([[blockSelf stateController] shouldSendNativeTime]) {
             [blockSelf sendNativeTime];
             int numberOfTimesSendNativeTimeWasCalled = [[[blockSelf stateController] state] numberOfTimesSendNativeTimeWasCalled];
             [[[blockSelf stateController] state] setNumberOfTimesSendNativeTimeWasCalled:++numberOfTimesSendNativeTimeWasCalled];
         }
         
         if ([[blockSelf stateController] shouldSendARKData])
         {
             [blockSelf sendARKData];
         }

         if ([[blockSelf stateController] shouldSendCVData]) {
             [blockSelf sendComputerVisionData];
             [[[blockSelf stateController] state] setComputerVisionFrameRequested:NO];
         }
     }];
    [[self arkController] setDidFailSession:^(NSError *error)
    {
        [[blockSelf webController] didReceiveError: error];
        
        if ([error code] == SENSOR_FAILED_ARKIT_ERROR_CODE) {
            NSMutableDictionary* currentARRequest = [[[[blockSelf stateController] state] aRRequest] mutableCopy];
            if ([currentARRequest[WEB_AR_WORLD_ALIGNMENT] boolValue]) {
                // The session failed because the compass (heading) couldn't be initialized. Fallback the session to ARWorldAlignmentGravity
                currentARRequest[WEB_AR_WORLD_ALIGNMENT] = [NSNumber numberWithBool:NO];;
                [[blockSelf stateController] setARRequest:currentARRequest];
                return;
            }
        }
        
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
            [[blockSelf messageController] hideMessages];
            [[blockSelf messageController] showMessageAboutFailSessionWithMessage:errorMessage completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self webController] loadBlankHTMLString];
                });
            }];
        });
     }];
    
    [[self arkController] setDidInterrupt:^(BOOL interruption)
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
    if (![ARKController supportsARFaceTrackingConfiguration]) {
        [[self webController] hideCameraFlipButton];
    }
    [[self webController] setAnimator:[self animator]];
    [[self webController] setOnStartLoad:^
     {
         if ([blockSelf arkController]) {
             NSString *lastURL = [[blockSelf webController] lastURL];
             NSString *currentURL = [[[[blockSelf webController] webView] URL] absoluteString];

             if ([lastURL isEqualToString:currentURL]) {
                 // Page reload
                 [[blockSelf arkController] removeAllAnchorsExceptPlanes];
             } 
         }
         [[blockSelf stateController] setWebXR:NO];
     }];
    
    [[self webController] setOnFinishLoad:^
     {
//         [blockSelf hideSplashWithCompletion:^
//          { }];
     }];
    
    [[self webController] setOnInitAR:^(NSDictionary *uiOptionsDict) {
        [[blockSelf stateController] setShowOptions:showOptionsFormDict(uiOptionsDict)];
        
        [[blockSelf stateController] applyOnEnterForegroundAction];
        [[blockSelf stateController] applyOnDidReceiveMemoryAction];
    }];
    
    [[self webController] setOnError:^(NSError *error)
     {
         [blockSelf showWebError:error];
     }];

    [[self webController] setOnWatchAR:^( NSDictionary * _Nullable request){
        [blockSelf handleOnWatchARWithRequest: request];
    }];

    [[self webController] setOnStopAR:^{
        [[blockSelf stateController] setWebXR:NO];
        [[blockSelf stateController] setShowMode:ShowNothing];
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
        [[blockSelf stateController] setShowMode:selected? ShowMultiDebug: ShowMulti];
    }];
    
    [[self webController] setOnSettingsButtonTapped:^{
        // Before showing the settings popup, we hide the bar and the debug buttons so they are not in the way
        // After dismissing the popup, we show them again.
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

    [[self webController] setOnComputerVisionDataRequested:^{
        [[[blockSelf stateController] state] setComputerVisionFrameRequested:YES];
    }];

    [[self webController] setOnResetTrackingButtonTapped:^{

        [[blockSelf messageController] showMessageAboutResetTracking:^(ResetTrackigOption option){
            switch (option) {
                case ResetTracking:
                    [[blockSelf arkController] runSessionResettingTrackingAndRemovingAnchorsWithAppState:[[blockSelf stateController] state]];
                    break;
                    
                case RemoveExistingAnchors:
                    [[blockSelf arkController] runSessionRemovingAnchorsWithAppState:[[blockSelf stateController] state]];
                    break;
            }
        }];
    }];

    [[self webController] setOnStartSendingComputerVisionData:^{
        [[[blockSelf stateController] state] setSendComputerVisionData:YES];
    }];

    [[self webController] setOnStopSendingComputerVisionData:^{
        [[[blockSelf stateController] state] setSendComputerVisionData:NO];
    }];

    [[self webController] setOnActivateDetectionImage:^(NSString *imageName, ActivateDetectionImageCompletionBlock completion) {
        [[blockSelf arkController] activateDetectionImage:imageName completion:completion];
    }];

    [[self webController] setOnDeactivateDetectionImage:^(NSString *imageName, CreateDetectionImageCompletionBlock completion) {
        [[blockSelf arkController] deactivateDetectionImage:imageName completion:completion];
    }];

    [[self webController] setOnDestroyDetectionImage:^(NSString *imageName, CreateDetectionImageCompletionBlock completion) {
        [[blockSelf arkController] destroyDetectionImage:imageName completion:completion];
    }];

    [[self webController] setOnCreateDetectionImage:^(NSDictionary *dictionary, CreateDetectionImageCompletionBlock completion) {
        [[blockSelf arkController] createDetectionImage:dictionary completion:completion];
    }];
    
    [[self webController] setOnSwitchCameraButtonTapped:^{
        [[blockSelf arkController] switchCameraButtonTapped];
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
    
//    [self showSplashWithCompletion:^
//     {
         [self cleanupTargetControllers];
//     }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(WAITING_TIME_ON_MEMORY_WARNING * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                   {
                       [self setupTargetControllers];
                       
//                       [self hideSplashWithCompletion:^
//                        {}];
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

-(void)sendComputerVisionData {
    [[self webController] sendComputerVisionData:[[self arkController] computerVisionData]];
}

-(void)sendNativeTime {
    [[self webController] sendNativeTime: [[self arkController] currentFrameTimeInMilliseconds]];
}

#pragma mark Web

- (void)showWebError:(NSError *)error
{
    if ([error code] == INTERNET_OFFLINE_CODE)
    {
//        [self showSplashWithCompletion:^
//         {
             [[self stateController] setShowMode:ShowNothing];
             [[self stateController] saveNotReachableOnURL:[[self webController] lastURL]];
             [[self messageController] showMessageAboutConnectionRequired];
//         }];
    }
    else
    {
        [[self messageController] showMessageAboutWebError:error withCompletion:^(BOOL reload)
         {
//             [self hideSplashWithCompletion:^
//              {
                  if (reload)
                  {
                      [self loadURL:nil];
                  }
                  else
                  {
                      [[self stateController] applyOnMessageShowMode];
                  }
//              }];
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


- (void)handleOnWatchARWithRequest: (NSDictionary*)request {
    __weak typeof (self) blockSelf = self;
    
    [[self arkController] setComputerVisionDataEnabled: false];
    [[[self stateController] state] setUserGrantedSendingComputerVisionData:false];
    [[[self stateController] state] setSendComputerVisionData: true];
    [[self arkController] setSendingWorldSensingDataAuthorizationStatus: SendWorldSensingDataAuthorizationStateNotDetermined];

    if ([request[WEB_AR_CV_INFORMATION_OPTION] boolValue]) {
        [[self messageController] showMessageAboutAccessingTheCapturedImage:^(BOOL granted){
            [[blockSelf webController] userGrantedComputerVisionData:granted];
            [[blockSelf arkController] setComputerVisionDataEnabled:granted];
            [[[blockSelf stateController] state] setUserGrantedSendingComputerVisionData:granted];
            
            // Approving computer vision data implicitly approves the world sensing data
            [[blockSelf arkController] setSendingWorldSensingDataAuthorizationStatus: SendWorldSensingDataAuthorizationStateAuthorized];
        }];
    } else if ([request[WEB_AR_WORLD_SENSING_DATA_OPTION] boolValue]) {
        [[self messageController] showMessageAboutAccessingWorldSensingData:^(BOOL granted){
            [[blockSelf webController] userGrantedSendingWorldSensingData:granted];
            [[blockSelf arkController] setSendingWorldSensingDataAuthorizationStatus: granted ? SendWorldSensingDataAuthorizationStateAuthorized: SendWorldSensingDataAuthorizationStateDenied];
        } url:[[[self webController] webView] URL]];
    } else {
        // if neither is requested, we'll actually set it to denied!
        [[blockSelf arkController] setSendingWorldSensingDataAuthorizationStatus: SendWorldSensingDataAuthorizationStateDenied];
    }

    [[self stateController] setARRequest:request];
    [[self stateController] setWebXR:YES];
    [[[self stateController] state] setNumberOfTimesSendNativeTimeWasCalled:0];
}

@end

