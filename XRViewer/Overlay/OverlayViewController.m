#import "OverlayViewController.h"
#import "WebARKHeader.h"
#import "RecordButton.h"
#import "MicButton.h"

@interface OverlayViewController ()

@property (nonatomic) UIStyle uIStyle;
@property (nonatomic) RecordState recordState;
@property (nonatomic) ShowMode showMode;
@property (nonatomic) ShowOptions showOptions;
@property (nonatomic) BOOL microphoneEnabled;

@property (nonatomic, strong) RecordButton *recordButton;
@property (nonatomic, strong) MicButton *micButton;

@property (nonatomic, strong) UIButton *showButton;
@property (nonatomic, strong) UIButton *debugButton;
@property (nonatomic, strong) UIButton *trackingStateButton;

@property (nonatomic, strong) UILabel *recordTimingLabel;
@property (nonatomic, strong) UILabel *helperLabel;
@property (nonatomic, strong) UILabel *buildLabel;
@property (nonatomic, strong) NSDate *startRecordDate;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation OverlayViewController

- (void)dealloc
{
    DDLogDebug(@"OverlayViewController dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [[self view] setHidden:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self viewWillTransitionToSize:size];
}

- (void)setShowMode:(ShowMode)showMode withAnimationCompletion:(Completion)completion
{
    [self setShowMode:showMode];
    
    [self updateWithCompletion:completion];
}

- (void)setShowOptions:(ShowOptions)showOptions withAnimationCompletion:(Completion)completion
{
    [self setShowOptions:(showOptions)];
    
    [self updateWithCompletion:completion];
}

- (void)setRecordState:(RecordState)recordState withAnimationCompletion:(Completion)completion
{
    [self setRecordState:recordState];
    
    [self updateWithCompletion:completion];
}

- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled withAnimationCompletion:(Completion)completion
{
    _microphoneEnabled = microphoneEnabled;
    
    [[self micButton] setSelected:microphoneEnabled];
    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       completion(YES);
                   });
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
    
    __weak typeof (self) blockSelf = self;
    [[self animator] animate:[self micButton] toFrame:micFrameIn(updRect)];
    [[self animator] animate:[self recordButton] toFrame:recordFrameIn(updRect) completion:^(BOOL f)
     {
         if ([blockSelf recordState] == RecordStatePhoto)
         {
             [[blockSelf animator] animate:[blockSelf recordButton] toFade:YES];
             [[blockSelf animator] animate:[blockSelf micButton] toFade:YES];
         }
         else if (([blockSelf recordState] == RecordStateRecording) || ([blockSelf recordState] == RecordStateRecordingWithMicrophone))
         {
             [[blockSelf animator] animate:[blockSelf recordButton] toFade:([blockSelf showOptions] & Capture) ? NO : YES];
             [[blockSelf animator] animate:[blockSelf micButton] toFade:([blockSelf showOptions] & Mic) ? NO : YES];
         }
     }];
    
    if ([blockSelf showMode] == ShowSingle)
    {
        // delay for show camera, mic frame animations
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                       {
                           [[blockSelf animator] animate:[blockSelf recordButton] toFade:YES];
                           [[blockSelf animator] animate:[blockSelf micButton] toFade:YES];
                       });
    }
    
    [[self helperLabel] setFrame:helperLabelFrameIn(updRect)];
    [[self helperLabel] setTransform:CGAffineTransformMakeRotation(-M_PI/2)];
    
    [[self trackingStateButton] setFrame:trackFrameIn(updRect)];
    [[self showButton] setFrame:showFrameIn(updRect)];
    [[self debugButton] setFrame:debugFrameIn(updRect)];
    [[self recordTimingLabel] setFrame:recordLabelFrameIn(updRect)];
    [[self buildLabel] setFrame:buildFrameIn(updRect)];
    
    if ([self recordState] == RecordStateAuthDisabled)
    {
        [[self recordButton] setImage:[UIImage imageNamed:@"camDisabled"] forState:UIControlStateNormal];
        [[self recordButton] setImage:[UIImage imageNamed:@"camDisabled"] forState:UIControlStateSelected];
        [[self micButton] setImage:[UIImage imageNamed:@"micDisabled"] forState:UIControlStateNormal];
        [[self micButton] setImage:[UIImage imageNamed:@"micDisabled"] forState:UIControlStateSelected];
    }
}

// common visibility
- (void)updateWithCompletion:(Completion)completion
{
    [self viewWillTransitionToSize:[[self view] bounds].size];
    
    switch ([self showMode])
    {
        case ShowNothing:
        {
            [[self animator] animate:[self showButton] toFade:YES completion:^(BOOL f)
             {
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    if (completion)
                                    {
                                        completion(f);
                                    }
                                });
             }];
            
            [[self animator] animate:[self recordButton] toFade:YES];
            [[self animator] animate:[self micButton] toFade:YES];
            
            [[self animator] animate:[self debugButton] toFade:YES];
            
            [[self animator] animate:[self helperLabel] toFade:YES];
            
            [[self animator] animate:[self buildLabel] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self timer] invalidate];
            break;
        }
        case ShowSingle:
        {
            [[self animator] animate:[self showButton] toFade:NO completion:^(BOOL f)
             {
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    if (completion)
                                    {
                                        completion(f);
                                    }
                                });
             }];
            
            [[self showButton] setHidden:NO];
            [[self showButton] setSelected:NO];
            [[self showButton] setEnabled:YES];
            
            [[self animator] animate:[self helperLabel] toFade:YES];
            [[self animator] animate:[self debugButton] toFade:YES];
            [[self animator] animate:[self buildLabel] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self timer] invalidate];
            break;
        }
        case ShowMulti:
        {
            if ([self uIStyle] == WebXRControlUI)
            {
                [[self animator] animate:[self showButton] toFade:NO completion:^(BOOL f)
                 {
                     dispatch_async(dispatch_get_main_queue(), ^
                                    {
                                        if (completion)
                                        {
                                            completion(f);
                                        }
                                    });
                 }];
                [[self showButton] setSelected:YES];
            }
            else
            {
                [[self showButton] setHidden:YES];
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   if (completion)
                                   {
                                       completion(YES);
                                   }
                               });
            }
            
            [self updateWithRecordStateInDebug:NO];
            break;
        }
        case ShowMultiDebug:
        {
            if ([self uIStyle] == WebXRControlUI)
            {
                [[self animator] animate:[self showButton] toFade:NO completion:^(BOOL f)
                 {
                     dispatch_async(dispatch_get_main_queue(), ^
                                    {
                                        if (completion)
                                        {
                                            completion(f);
                                        }
                                    });
                 }];
                [[self showButton] setSelected:YES];
            }
            else
            {
                [[self showButton] setHidden:YES];
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   if (completion)
                                   {
                                       completion(YES);
                                   }
                               });
            }
            
            [self updateWithRecordStateInDebug:YES];
            break;
        }
    }
}

- (void)updateWithRecordStateInDebug:(BOOL)debug
{
    if ([self recordState] == RecordStateRecordingWithMicrophone)
    {
        [self setMicrophoneEnabled:YES];
    }
    else if ([self recordState] == RecordStateRecording)
    {
        [self setMicrophoneEnabled:NO];
    }
    
    switch ([self recordState])
    {
        case RecordStateIsReady:
            [[self showButton] setEnabled:YES];
            [[self animator] animate:[self recordButton] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self debugButton] toFade:([self showOptions] & Debug) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self recordButton] setSelected:NO];
            
            [[self micButton] setSelected:_microphoneEnabled];
            
            [[self helperLabel] setText:nil];
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
            
        case RecordStatePhoto:
        {
            [[self showButton] setEnabled:NO];
            [[self animator] animate:[self helperLabel] toFade:YES];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self debugButton] toFade:([self showOptions] & Debug) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self recordButton] setImage:[UIImage imageNamed:@"camTap"] forState:UIControlStateSelected];
            [[self recordButton] setSelected:YES];
            
            [[self micButton] setSelected:_microphoneEnabled];
            
            [[self helperLabel] setText:nil];
            [[self timer] invalidate];
            break;
        }
        case RecordStateGoingToRecording:
            break;
            
        case RecordStateRecordingWithMicrophone:
        case RecordStateRecording:
        {
            [[self showButton] setEnabled:NO];
            [[self animator] animate:[self helperLabel] toFade:YES];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self debugButton] toFade:([self showOptions] & Debug) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:([self showOptions] & CaptureTime) ? NO : YES];
            
            [[self recordButton] setSelected:YES];
            
            [[self micButton] setSelected:_microphoneEnabled];
            
            [[self helperLabel] setText:nil];
            
            [self setStartRecordDate:[NSDate date]];
            [self setTimer:[NSTimer scheduledTimerWithTimeInterval:.01 repeats:YES block:^(NSTimer * _Nonnull timer)
                            {
                                NSDate *currentDate = [NSDate date];
                                NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:[self startRecordDate]];
                                NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                                
                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                [dateFormatter setDateFormat:@"HH:mm:ss"];
                                [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
                                
                                NSString *timeString = [dateFormatter stringFromDate:timerDate];
                                [[self recordTimingLabel] setText:timeString];
                            }]];
            break;
        }
            
        case RecordStatePreviewing:
        {
            BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
            [[self showButton] setEnabled:YES];
            [[self animator] animate:[self showButton] toFade:isIpad ? NO : YES];
            [[self animator] animate:[self recordButton] toFade:isIpad && ([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:isIpad && ([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:isIpad && ([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self buildLabel] toFade:isIpad && (debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self debugButton] toFade:isIpad && ([self showOptions] & Debug) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self recordButton] setSelected:NO];
            
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
        }
        case RecordStateDisabled:
            [[self showButton] setEnabled:YES];
            
            [[self animator] animate:[self recordButton] toFade:YES];
            [[self animator] animate:[self micButton] toFade:YES];
            [[self animator] animate:[self helperLabel] toFade:NO];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self debugButton] toFade:([self showOptions] & Debug) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self helperLabel] setText:DISABLED_TEXT];
            [[self helperLabel] setTextColor:[UIColor grayColor]];
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
        case RecordStateAuthDisabled:
            [[self showButton] setEnabled:YES];
            [[self animator] animate:[self recordButton] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:NO];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self debugButton] toFade:([self showOptions] & Debug) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self helperLabel] setText:GRANT_TEXT];
            [[self helperLabel] setTextColor:[UIColor redColor]];
            
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
        case RecordStateError:
            [[self showButton] setEnabled:YES];
            [[self animator] animate:[self recordButton] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:NO];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self debugButton] toFade:([self showOptions] & Debug) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self recordButton] setSelected:NO];
            [[self micButton] setSelected:_microphoneEnabled];
            
            [[self helperLabel] setText:ERROR_TEXT];
            [[self helperLabel] setTextColor:[UIColor redColor]];
            
            // move to Is Ready state
            // fix multiple block executing
            // RF me:
            static NSUInteger counter = 0;
            counter++;
            __block NSUInteger blockCounter = counter;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SHOW_ERROR_RECORDING_LABEL_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                           {
                               if ((blockCounter == counter) && [self recordState] == RecordStateError)
                               {
                                   [self setRecordState:RecordStateIsReady withAnimationCompletion:NULL];
                               }
                           });
            
            break;
    }
}

- (void)setTrackingState:(NSString *)state withAnimationCompletion:(Completion)completion;
{
    if ([self recordState] == RecordStatePreviewing)
    {
        if ((([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && ([self showOptions] & ARWarnings)))
        {
            [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
             {
                 completion(finish);
             }];
        }
        else
        {
            [[self animator] animate:[self trackingStateButton] toFade:YES completion:^(BOOL finish)
             {
                 completion(finish);
             }];
        }
        
        return;
    }
    
    if ([self showMode] >= ShowNothing)
    {
        if ([self showOptions] & ARWarnings)
        {
            if ([state isEqualToString:WEB_AR_TRACKING_STATE_NORMAL])
            {
                [[self animator] animate:[self trackingStateButton] toFade:YES completion:^(BOOL finish)
                 {
                     [[self trackingStateButton] setImage:nil forState:UIControlStateNormal];
                     completion(finish);
                 }];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                 {
                     completion(finish);
                 }];
                
                [[self trackingStateButton] setImage:[UIImage imageNamed:@"ARKitNotInitialized"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                 {
                     completion(finish);
                 }];
                
                [[self trackingStateButton] setImage:[UIImage imageNamed:@"ARKitNotInitialized"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED_FEATURES])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                 {
                     completion(finish);
                 }];
                
                [[self trackingStateButton] setImage:[UIImage imageNamed:@"NotEnoughVisualFeatures"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED_MOTION])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                 {
                     completion(finish);
                 }];
                
                [[self trackingStateButton] setImage:[UIImage imageNamed:@"MoovingTooFast"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_NOT_AVAILABLE])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                 {
                     completion(finish);
                 }];
                
                [[self trackingStateButton] setImage:[UIImage imageNamed:@"ARKitNotAvailable"] forState:UIControlStateNormal];
            }
            
            return;
        }
    }
    
    [[self trackingStateButton] setImage:nil forState:UIControlStateNormal];
}

- (void)setTrackingState:(NSString *)state withAnimationCompletion:(Completion)completion sceneHasPlanes:(BOOL)hasPlanes {
    if ([self recordState] == RecordStatePreviewing)
    {
        if ((([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && ([self showOptions] & ARWarnings)))
        {
            [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
            {
                completion(finish);
            }];
        }
        else
        {
            [[self animator] animate:[self trackingStateButton] toFade:YES completion:^(BOOL finish)
            {
                completion(finish);
            }];
        }

        return;
    }

    if ([self showMode] >= ShowNothing)
    {
        if ([self showOptions] & ARWarnings)
        {
            if ([state isEqualToString:WEB_AR_TRACKING_STATE_NORMAL])
            {
                if (hasPlanes) {
                    [[self animator] animate:[self trackingStateButton] toFade:YES completion:^(BOOL finish)
                    {
                        [[self trackingStateButton] setImage:nil forState:UIControlStateNormal];
                        completion(finish);
                    }];
                } else {
                    [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                    {
                        completion(finish);
                    }];

                    [[self trackingStateButton] setImage:[UIImage imageNamed:@"NoPlanesDetectedYet"] forState:UIControlStateNormal];
                }
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                {
                    completion(finish);
                }];

                [[self trackingStateButton] setImage:[UIImage imageNamed:@"ARKitNotInitialized"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                {
                    completion(finish);
                }];

                [[self trackingStateButton] setImage:[UIImage imageNamed:@"ARKitNotInitialized"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED_FEATURES])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                {
                    completion(finish);
                }];

                [[self trackingStateButton] setImage:[UIImage imageNamed:@"NotEnoughVisualFeatures"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_LIMITED_MOTION])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                {
                    completion(finish);
                }];

                [[self trackingStateButton] setImage:[UIImage imageNamed:@"MovingTooFast"] forState:UIControlStateNormal];
            }
            else if ([state isEqualToString:WEB_AR_TRACKING_STATE_NOT_AVAILABLE])
            {
                [[self animator] animate:[self trackingStateButton] toFade:NO completion:^(BOOL finish)
                {
                    completion(finish);
                }];

                [[self trackingStateButton] setImage:[UIImage imageNamed:@"ARKitNotAvailable"] forState:UIControlStateNormal];
            }

            return;
        }
    }

    [[self trackingStateButton] setImage:nil forState:UIControlStateNormal];
}


- (void)setup
{
    [self setRecordButton:[RecordButton new]];
    [[self view] addSubview:[self recordButton]];
    
    [self setMicButton:[MicButton new]];
    [[self view] addSubview:[self micButton]];
    
    [self setTrackingStateButton:[UIButton buttonWithType:UIButtonTypeCustom]];
    [[self trackingStateButton] setFrame:trackFrameIn([[self view] bounds])];
    [[self trackingStateButton] setContentVerticalAlignment:UIControlContentVerticalAlignmentFill];
    [[self trackingStateButton] setContentHorizontalAlignment:UIControlContentHorizontalAlignmentFill];
    [[self view] addSubview:[self trackingStateButton]];
    
    [self setShowButton:[UIButton buttonWithType:UIButtonTypeCustom]];
    [[self showButton] setImage:[UIImage imageNamed:@"3DHide"] forState:UIControlStateNormal];
    [[self showButton] setImage:[UIImage imageNamed:@"3DShow"] forState:UIControlStateSelected];
    [[self view] addSubview:[self showButton]];
    
    [self setDebugButton:[UIButton buttonWithType:UIButtonTypeCustom]];
    [[self debugButton] setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
    [[self view] addSubview:[self debugButton]];
    
    [self setRecordTimingLabel:[[UILabel alloc] initWithFrame:recordLabelFrameIn([[self view] bounds])]];
    [[self recordTimingLabel] setFont:[UIFont boldSystemFontOfSize:15]];
    [[self recordTimingLabel] setTextAlignment:NSTextAlignmentCenter];
    [[self recordTimingLabel] setTextColor:[UIColor blackColor]];
    [[self recordTimingLabel] setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.5]];
    [[[self recordTimingLabel] layer] setCornerRadius:5];
    [[self recordTimingLabel] setClipsToBounds:YES];
    [[self view] addSubview:[self recordTimingLabel]];
    
    [self setHelperLabel:[[UILabel alloc] initWithFrame:helperLabelFrameIn([[self view] bounds])]];
    [[self helperLabel] setFont:[UIFont systemFontOfSize:12]];
    [[self helperLabel] setTextAlignment:NSTextAlignmentCenter];
    [[self helperLabel] setTextColor:[UIColor whiteColor]];
    [[self helperLabel] setBackgroundColor:[UIColor clearColor]];
    [[self helperLabel] setClipsToBounds:YES];
    [[self view] addSubview:[self helperLabel]];
    
    [self setBuildLabel:[[UILabel alloc] initWithFrame:buildFrameIn([[self view] bounds])]];
    [[self buildLabel] setFont:[UIFont boldSystemFontOfSize:12]];
    [[self buildLabel] setTextAlignment:NSTextAlignmentCenter];
    [[self buildLabel] setTextColor:[UIColor whiteColor]];
    [[self buildLabel] setBackgroundColor:[UIColor colorWithWhite:0 alpha:.0]];
    [[self buildLabel] setText:[self versionBuild]];
    [[self view] addSubview:[self buildLabel]];
    
    [self viewWillTransitionToSize:[[self view] bounds].size];
}

- (NSString *)appVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

- (NSString *)build
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
}

- (NSString *)versionBuild
{
    NSString *version = [self appVersion];
    NSString *build = [self build];
    
    NSString *versionBuild = [NSString stringWithFormat: @"v%@", version];
    
    if (![version isEqualToString: build]) {
        versionBuild = [NSString stringWithFormat: @"%@(%@)", versionBuild, build];
    }
    
    return versionBuild;
}

@end

