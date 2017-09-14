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

#define MICROPHONE_ENABLED_BY_DEFAULT YES
#define RECORD_STATE_BY_DEFAULT RecordStateIsReady

typedef NS_ENUM(NSUInteger, ViewIndex)
{
    ARKViewIndex,
    WebViewIndex,
    BackViewIndex,
    HotViewIndex
};


@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *backView;
@property (nonatomic, strong) UIActivityIndicatorView *ai;

@property (nonatomic, strong) ARKController *arkController;
@property (nonatomic, strong) WebController *webController;
@property (nonatomic, strong) UIOverlayController *overlayController;
@property (nonatomic, strong) RecordController *recordController;
@property (nonatomic, strong) LocationManager *locationManager;
@property (nonatomic, strong) MessageController *messageController;

@property (nonatomic, copy) NSDictionary *aRRequest;

#warning Test Memory Warning
@property (nonatomic) BOOL testMemoryWarning;
@property (nonatomic) BOOL didReceiveMemoryWaring;
@property (nonatomic) BOOL willEnterForeground;

@property (nonatomic, copy) NSString *urlOnMemoryWarning;

@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowMode onMessageShowMode;

@property(nonatomic) ShowOptions showOptions;

@property(nonatomic) RecordState recordState;

@property (nonatomic, strong) Animator *animator;

@property (nonatomic) Reachability *reachability;
@property (nonatomic) BOOL reloadByReachability;

@property (nonatomic) BOOL webXR;
#define  WAITING_FOR_WEB_XR 1

@end


@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setAnimator:[Animator new]];
    
    [self setShowMode:ShowNothing];
    [self setShowOptions:None];
    
    [self startAI];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self setupMessageController];
        [self setupReachability];
        [self setupNotifications];
        [self setupControllers];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    DDLogError(@"DIDRECIVEMEMORYWARNING");
    
    [self processMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [[self arkController] viewWillTransitionToSize:size];
    [[self overlayController] viewWillTransitionToSize:size];
    [[self webController] viewWillTransitionToSize:size];
}

#pragma mark Private

- (void)startAI
{
    [[self backView] setAlpha:1];
    [self setAi:[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]];
    [[self ai] startAnimating];
    [[self backView] addSubview:[self ai]];
    CGPoint position = CGPointMake([self view].bounds.size.width - 20, [self view].bounds.size.height - 20);
    [[self ai] setCenter:position];
}

- (void)stopAI
{
    [[self ai] stopAnimating];
    [[self ai] removeFromSuperview];
    [self setAi:nil];
}

- (void)processMemoryWarning
{
    [self setShowMode:ShowNothing];
    [self setUrlOnMemoryWarning:[[self webController] lastURL]];
    [[self webController] clean];
    
    [[[self view] subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        if (obj == [self backView])
        {
            [obj setAlpha:1];
        }
        else
        {
            [obj removeFromSuperview];
        }
    }];
    
    [self setDidReceiveMemoryWaring:YES];
    
    [self startAI];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self setupControllers];
    });
}

- (void)showWebError:(NSError *)error
{
    [[self messageController] showMessageAboutWebError:error withCompletion:^(BOOL reload)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            if (reload)
            {
                [self reload:nil];
            }
            else
            {
                [self setShowMode:[self onMessageShowMode]];
            }
        });
    }];
}

- (void)reload:(id)sender
{
    [self setWebXR:NO];
    
    [[self webController] reload];
}

- (void)setupNotifications
{
    __weak typeof (self) blockSelf = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note)
     {
         [blockSelf cleanARKController];
         [[blockSelf webController] didMoveBackground];
         
         [blockSelf setShowMode:ShowNothing];
         
         [[blockSelf view] bringSubviewToFront:[blockSelf backView]];
         [blockSelf startAI];
     }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note)
     {
         [blockSelf setWillEnterForeground:YES];
         [[blockSelf messageController] showMessageAboutARInteruption:NO];
         [blockSelf reload:nil];
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
        
        if (isReachable && [blockSelf reloadByReachability])
        {
            [blockSelf setReloadByReachability:NO];
            [[blockSelf webController] loadURL:[[blockSelf webController] lastURL]];
        }
        else if (isReachable == NO && [blockSelf aRRequest] == nil)
        {
            [blockSelf setReloadByReachability:YES];
            [[blockSelf messageController] showMessageAboutConnectionRequired];
            [blockSelf stopAI];
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

- (void)setShowMode:(ShowMode)showMode
{
    _showMode = showMode;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[self arkController] setShowMode:showMode];
        [[self overlayController] setMode:showMode];
        
        [[self webController] showBar:([self webXR] == NO) ? YES : ((showMode >= ShowMulti) && ([self showOptions] & Browser))];
        [[self webController] showDebug:(showMode == ShowMultiDebug ? YES : NO)];
    });
}

- (void)setShowOptions:(ShowOptions)showOptions
{
    _showOptions = showOptions;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[self arkController] setShowOptions:[self showOptions]];
        [[self overlayController] setOptions:[self showOptions]];
        
        [[self webController] showBar:([self webXR] == NO) ? YES : ((_showMode >= ShowMulti) && ([self showOptions] & Browser))];
    });
}

- (void)setRecordState:(RecordState)recordState
{
    _recordState = recordState;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[self overlayController] setRecordState:recordState];
        [[self webController] setRecordState:recordState];
        
        if (recordState == RecordStatePhoto ||
            recordState == RecordStateRecording ||
            recordState == RecordStateGoingToRecording ||
            ((recordState == RecordStatePreviewing) && ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)))
        {
            [[self webController] showBar:NO];
            return;
        }
        
        [[self webController] showBar:([self webXR] == NO) ? YES : ((_showMode >= ShowMulti) && ([self showOptions] & Browser))];
    });
}

- (void)setWebXR:(BOOL)webXR
{
    _webXR = webXR;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if (webXR == NO)
        {
            [self cleanARKController];
        }
        else
        {
            [self setupARKController];
            [self setupLocationController];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            [self setShowMode:webXR ? ShowSingle : ShowNothing];
        });
    });
}

- (void)cleanARKController
{
    [[[self arkController] arkView] removeFromSuperview];
    [self setArkController:nil];
}

- (void)setupMessageController
{
    [self setMessageController:[[MessageController alloc] initWithViewController:self]];
    
    __weak typeof (self) blockSelf = self;
    
    [[self messageController] setDidShowMessage:^
    {
        [blockSelf setOnMessageShowMode:[blockSelf showMode]];
        [blockSelf setShowMode:ShowNothing];
    }];
    
    [[self messageController] setDidHideMessage:^
     {
         [blockSelf setShowMode:[blockSelf onMessageShowMode]];
     }];
    
    [[self messageController] setDidHideMessageByUser:^
     {
         [blockSelf setShowMode:[blockSelf onMessageShowMode]];
     }];
}

- (void)setupControllers
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
                               
                               [[blockSelf view] bringSubviewToFront:[blockSelf backView]];
                           });
        }];
    }
    
    [[self view] bringSubviewToFront:[blockSelf backView]];
    
    [self setupOverlayController];
}

- (void)setupLocationController
{
    [self setLocationManager:[[LocationManager alloc] init]];
    [[self locationManager] setupForRequest:[self aRRequest]];
}

- (void)setupARKController
{
    [[[self arkController] arkView] removeFromSuperview];
    
    [self setArkController:[[ARKController alloc] initWithType:ARKSceneKit]];
    
    __weak typeof (self) blockSelf = self;
    
    [[self arkController] setDidUpdate:^(ARKController *c)
    {
        if ([blockSelf aRRequest] != nil)
        {
            [blockSelf sendARKData];
        }
    }];
#define CAMERA_ACCESS_NOT_AUTORIZED_CODE 103
    [[self arkController] setDidFailSession:^(NSError *error)
     {
         if ([error code] != CAMERA_ACCESS_NOT_AUTORIZED_CODE)
         {
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
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [[blockSelf recordController] stopRecordingByInterruption:self];
            [[blockSelf messageController] showMessageAboutARInteruption:interruption];
            [[blockSelf overlayController] setARKitInterruption:interruption];
            
            if (interruption)
            {
                [[blockSelf webController] arkitWasInterrupted];
            }
            else
            {
                [[blockSelf webController] arkitInterruptionEnded];
            }
        });
    }];
    
    [[self arkController] setDidChangeTrackingState:^(NSString *state)
    {
        [[blockSelf webController] arkitDidChangeTrackingState:state];
        [[blockSelf overlayController] setTrackingState:state];
    }];
    
    
    [[self view] insertSubview:[[self arkController] arkView] atIndex:ARKViewIndex];
    
    [[self animator] animate:[[self arkController] arkView] toFade:NO];
   
    [[self arkController] startSessionWithRequest:[self aRRequest] showMode:[self showMode] showOptions:[self showOptions]];
}

- (void)setupWebController
{
    __weak typeof (self) blockSelf = self;
    
    [self setWebController:[[WebController alloc] initWithRootView:[blockSelf view] atIndex:WebViewIndex]];
    [[self webController] setAnimator:[self animator]];
    [[self webController] setOnStartLoad:^
     {
         [blockSelf setWebXR:NO];
     }];
    
    [[self webController] setOnFinishLoad:^
    {
        [UIView animateWithDuration:0.5 animations:^
         {
             [[blockSelf backView] setAlpha:0];
             [blockSelf stopAI];
         }];
    }];
    
    [[self webController] setOnInit:^(NSDictionary *uiOptionsDict)
    {
        [blockSelf setWebXR:YES];
        
        ShowOptions op = showOptionsFormDict(uiOptionsDict);
        [blockSelf setShowOptions:op];
        
        if ([blockSelf didReceiveMemoryWaring])
        {
            [blockSelf setDidReceiveMemoryWaring:NO];
            [[blockSelf webController] iosDidReceiveMemoryWarning];
            [[blockSelf messageController] showMessageAboutMemoryWarning];
        }
        
        if ([blockSelf willEnterForeground])
        {
            [blockSelf setWillEnterForeground:NO];
            [[blockSelf webController] willEnterForeground];
        }
    }];
    
    [[self webController] setOnError:^(NSError *error)
    {
        [blockSelf stopAI];
        
        if ([error code] == INTERNET_OFFLINE_CODE)
        {
            [blockSelf setShowMode:ShowNothing];
            [blockSelf setReloadByReachability:YES];
            [[blockSelf messageController] showMessageAboutConnectionRequired];
            [[blockSelf backView] setAlpha:1];
        }
        else
        {
            [blockSelf showWebError:error];
        }
    }];
    
    [[self webController] setOnIOSUpdate:^( NSDictionary * _Nullable request)
     {
         [blockSelf setARRequest:request];
         
         [[blockSelf locationManager] setupForRequest:[blockSelf aRRequest]];
     }];
    
    [[self webController] setOnJSUpdate:^( NSDictionary * _Nullable request)
     {
         [blockSelf setARRequest:request];
         
         [[blockSelf locationManager] setupForRequest:[blockSelf aRRequest]];
         [[blockSelf arkController] startSessionWithRequest:[blockSelf aRRequest] showMode:[blockSelf showMode] showOptions:[blockSelf showOptions]];
     }];
    
    [[self webController] setOnJSUpdateData:^NSDictionary *
     {
         return [blockSelf commonData];
     }];

    [[self webController] setLoadURL:^(NSString *url)
    {
        //... ui?
        [[blockSelf webController] loadURL:url];
    }];
    
    [[self webController] setOnSetUI:^(NSDictionary *uiOptionsDict)
    {
        ShowOptions op = showOptionsFormDict(uiOptionsDict);
        
        [blockSelf setShowOptions:op];
    }];
    
    [[self webController] setOnHitTest:^(NSUInteger mask, CGFloat x, CGFloat y, ResultArrayBlock result)
    {
        NSArray *results = [[blockSelf arkController] hitTestNormPoint:CGPointMake(x, y) types:mask];
        
        result(results);
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
    
    [[self webController] setOnMemory:^(BOOL test)
     {
         [blockSelf setTestMemoryWarning:test];
    }];
    
    [[self webController] loadURL:[self didReceiveMemoryWaring] ? [self urlOnMemoryWarning] : WEB_URL];
}

- (void)setupRecordController
{
    __weak typeof (self) blockSelf = self;
    
    RecordAction rA = ^(RecordState state)
    {
        [blockSelf setRecordState:state];
    };
    
    [self setRecordController:[[RecordController alloc] initWithAction:rA micEnabled:MICROPHONE_ENABLED_BY_DEFAULT]];
    [[self recordController] setAnimator:[self animator]];
    [[self recordController] setAuthAction:^(id sender)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success)
         {}];
    }];
}

- (void)setupOverlayController
{
    __weak typeof (self) blockSelf = self;
    
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
            if ([blockSelf testMemoryWarning])
            {
                [blockSelf processMemoryWarning];
            }
            else
            {
                [[blockSelf recordController] shotAction:blockSelf];
            }
        }
    };
    
    HotAction micAction = ^(BOOL any)
    {
        [[blockSelf recordController] micAction:blockSelf];
        [[blockSelf overlayController] setMicrophoneEnabled:[[blockSelf recordController] microphoneEnabled]];
    };
    
    HotAction showAction = ^(BOOL any)
    {
        [blockSelf setShowMode:[blockSelf showMode] == ShowSingle ? ShowMulti : ShowSingle];
    };
    
    HotAction debugAction = ^(BOOL any)
    {
        [blockSelf setShowMode:[blockSelf showMode] == ShowMulti ? ShowMultiDebug : ShowMulti];
    };
    
    [self setOverlayController:[[UIOverlayController alloc] initWithRootView:[self view]
                                                                     atIndex:HotViewIndex
                                                                cameraAction:cameraAction
                                                                   micAction:micAction
                                                                  showAction:showAction
                                                                 debugAction:debugAction]];
    
    [[self overlayController] setAnimator:[self animator]];
    [[self overlayController] setMode:[self showMode]];
    [[self overlayController] setOptions:[self showOptions]];
    [[self overlayController] setMicrophoneEnabled:MICROPHONE_ENABLED_BY_DEFAULT];
    [[self overlayController] setRecordState:RECORD_STATE_BY_DEFAULT];
}

- (NSDictionary *)commonData
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[[self locationManager] locationData]];
    
    [dictionary setValuesForKeysWithDictionary:[[self arkController] arkData]];
    
    return [dictionary copy];
}

- (void)sendARKData
{
    [[self webController] sendARData:[self commonData]];
}

- (NSDictionary *)initialRequest
{
    return @{WEB_AR_H_PLANE_OPTION : @YES};
}

- (ShowOptions)initialOptions
{
    return Full;
}

@end
