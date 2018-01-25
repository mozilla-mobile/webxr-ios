#import "OverlayViewController.h"
#import "WebARKHeader.h"


@interface OverlayViewController ()

@property (nonatomic) RecordState recordState;
@property (nonatomic) ShowMode showMode;
@property (nonatomic) ShowOptions showOptions;
@property (nonatomic) BOOL microphoneEnabled;

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *trackingStateButton;
@property (nonatomic, strong) UIButton *micButton;

@property (nonatomic, strong) UILabel *recordTimingLabel;
@property (nonatomic, strong) UIView *recordDot;
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

- (BOOL)prefersStatusBarHidden {
    return [super prefersStatusBarHidden];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeTop;
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
    [self setShowOptions:showOptions];
    
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
    [[self recordDot] setFrame:dotFrameIn(updRect)];
    [[self recordTimingLabel] setFrame:recordLabelFrameIn(updRect)];
    [[self buildLabel] setFrame:buildFrameIn(updRect)];
    
    if ([self recordState] == RecordStateAuthDisabled)
    {
        [[self recordButton] setImage:[UIImage imageNamed:@"camDisabled"] forState:UIControlStateNormal];
        [[self recordButton] setImage:[UIImage imageNamed:@"camDisabled"] forState:UIControlStateSelected];
        [[self micButton] setImage:[UIImage imageNamed:@"micDisabled"] forState:UIControlStateNormal];
        [[self micButton] setImage:[UIImage imageNamed:@"micDisabled"] forState:UIControlStateSelected];
    }
    else
    {
        [[self recordButton] setImage:[UIImage imageNamed:@"cam"] forState:UIControlStateNormal];
        [[self recordButton] setImage:[UIImage animatedImageWithImages:@[[UIImage imageNamed:@"cam"], [UIImage imageNamed:@"camPress"]]
                                                              duration:[[self animator] animationDuration] ]
                             forState:UIControlStateSelected];
        [[self micButton] setImage:[UIImage imageNamed:@"micOff"] forState:UIControlStateNormal];
        [[self micButton] setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateSelected];
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
            [[self animator] animate:[self recordButton] toFade:YES];
            [[self animator] animate:[self micButton] toFade:YES];
            
            [[self animator] animate:[self helperLabel] toFade:YES];
            
            [[self animator] animate:[self buildLabel] toFade:YES];
            [[self animator] animate:[self recordDot] toFade:YES];
            
            [[self timer] invalidate];
            if (completion) {
                completion(YES);
            }
            break;
        }
        case ShowSingle:
        {
            [[self animator] animate:[self helperLabel] toFade:YES];
            [[self animator] animate:[self buildLabel] toFade:YES];
            [[self animator] animate:[self recordDot] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self timer] invalidate];
            if (completion) {
                completion(YES);
            }
            break;
        }
        case ShowMulti:
        {
            [self updateWithRecordStateInDebug:NO];
            if (completion) {
                completion(YES);
            }
            break;
        }
        case ShowMultiDebug:
        {
            [self updateWithRecordStateInDebug:YES];
            if (completion) {
                completion(YES);
            }
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
            [[self animator] animate:[self recordButton] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self recordDot] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self recordButton] setSelected:NO];
            [[self micButton] setSelected:_microphoneEnabled];
            
            [[self helperLabel] setText:HELP_TEXT];
            [[self helperLabel] setTextColor:[UIColor whiteColor]];
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
            
        case RecordStatePhoto:
        {
            [[self animator] animate:[self helperLabel] toFade:YES];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self recordDot] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self recordButton] setImage:[UIImage imageNamed:@"camTap"] forState:UIControlStateSelected];
            [[self recordButton] setSelected:YES];
            [[self micButton] setSelected:_microphoneEnabled];
            
            [[self helperLabel] setText:HELP_TEXT];
            [[self helperLabel] setTextColor:[UIColor whiteColor]];
            [[self timer] invalidate];
            break;
        }
        case RecordStateGoingToRecording:
            break;
            
        case RecordStateRecordingWithMicrophone:
        case RecordStateRecording:
        {
            [[self animator] animate:[self helperLabel] toFade:YES];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self recordDot] toFade:([self showOptions] & CaptureTime) ? NO : YES];
            [[self animator] animate:[self recordTimingLabel] toFade:([self showOptions] & CaptureTime) ? NO : YES];
            
            [[self recordButton] setImage:[UIImage animatedImageWithImages:@[[UIImage imageNamed:@"cam"], [UIImage imageNamed:@"camPress"]]
                                                                  duration:[[self animator] animationDuration] * 2] forState:UIControlStateSelected];
            [[self animator] startPulseAnimation:[self recordButton]];
            [[self recordButton] setSelected:YES];
            [[self micButton] setSelected:_microphoneEnabled];
            
            [[self helperLabel] setText:HELP_TEXT];
            [[self helperLabel] setTextColor:[UIColor whiteColor]];
            
            [self setStartRecordDate:[NSDate date]];
            [self setTimer:[NSTimer scheduledTimerWithTimeInterval:.01 repeats:YES block:^(NSTimer * _Nonnull timer)
                            {
                                NSDate *currentDate = [NSDate date];
                                NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:[self startRecordDate]];
                                NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                                
                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                [dateFormatter setDateFormat:@"mm:ss:SS"];
                                [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
                                
                                NSString *timeString = [dateFormatter stringFromDate:timerDate];
                                [[self recordTimingLabel] setText:timeString];
                            }]];
            break;
        }
            
        case RecordStatePreviewing:
        {
            BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
            [[self animator] animate:[self recordButton] toFade:isIpad && ([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:isIpad && ([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:isIpad && ([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self buildLabel] toFade:isIpad && (debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self recordDot] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self recordButton] setSelected:NO];
            
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
        }
        case RecordStateDisabled:
            [[self animator] animate:[self recordButton] toFade:YES];
            [[self animator] animate:[self micButton] toFade:YES];
            [[self animator] animate:[self helperLabel] toFade:NO];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self recordDot] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self helperLabel] setText:DISABLED_TEXT];
            [[self helperLabel] setTextColor:[UIColor grayColor]];
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
        case RecordStateAuthDisabled:
            [[self animator] animate:[self recordButton] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:NO];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self recordDot] toFade:YES];
            [[self animator] animate:[self recordTimingLabel] toFade:YES];
            
            [[self helperLabel] setText:GRANT_TEXT];
            [[self helperLabel] setTextColor:[UIColor redColor]];
            
            [[self timer] invalidate];
            [[self animator] stopPulseAnimation:[self recordButton]];
            
            break;
        case RecordStateError:
            [[self animator] animate:[self recordButton] toFade:([self showOptions] & Capture) ? NO : YES];
            [[self animator] animate:[self micButton] toFade:([self showOptions] & Mic) ? NO : YES];
            [[self animator] animate:[self helperLabel] toFade:NO];
            [[self animator] animate:[self buildLabel] toFade:(debug && ([self showOptions] & BuildNumber)) ? NO : YES];
            [[self animator] animate:[self recordDot] toFade:YES];
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

                [[self trackingStateButton] setImage:[UIImage imageNamed:@"disabled"] forState:UIControlStateNormal];
            }

            return;
        }
    }

    [[self trackingStateButton] setImage:nil forState:UIControlStateNormal];
}


- (void)setup
{
    [self setRecordButton:[UIButton buttonWithType:UIButtonTypeCustom]];
    
    [[self view] addSubview:[self recordButton]];
    
    [self setMicButton:[UIButton buttonWithType:UIButtonTypeCustom]];
    [[self micButton] setImage:[UIImage imageNamed:@"micOff"] forState:UIControlStateNormal];
    [[self micButton] setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateSelected];
    [[self view] addSubview:[self micButton]];
    
    [self setTrackingStateButton:[UIButton buttonWithType:UIButtonTypeCustom]];
    [[self trackingStateButton] setFrame:trackFrameIn([[self view] bounds])];
    [[self trackingStateButton] setContentVerticalAlignment:UIControlContentVerticalAlignmentFill];
    [[self trackingStateButton] setContentHorizontalAlignment:UIControlContentHorizontalAlignmentFill];
    [[self view] addSubview:[self trackingStateButton]];
    
    [self setRecordDot:[[UIView alloc] initWithFrame:dotFrameIn([[self view] bounds])]];
    [[[self recordDot] layer] setCornerRadius:(DOT_SIZE / 2.0)];
    [[self recordDot] setBackgroundColor:[UIColor redColor]];
    [[self view] addSubview:[self recordDot]];
    
    [self setRecordTimingLabel:[[UILabel alloc] initWithFrame:recordLabelFrameIn([[self view] bounds])]];
    [[self recordTimingLabel] setFont:[UIFont systemFontOfSize:12]];
    [[self recordTimingLabel] setTextAlignment:NSTextAlignmentLeft];
    [[self recordTimingLabel] setTextColor:[UIColor whiteColor]];
    [[self recordTimingLabel] setBackgroundColor:[UIColor clearColor]];
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
    
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
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

