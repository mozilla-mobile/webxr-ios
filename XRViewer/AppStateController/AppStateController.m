#import "AppStateController.h"

#define RUN_ACTION_ASYNC_MAIN(a,p) if(a){ dispatch_async(dispatch_get_main_queue(), ^{ a(p);}); }

typedef void (^ExclusiveAction)(void);
typedef NS_ENUM(NSUInteger, ExclusiveStateType)
{
    ExclusiveStateMessage,
    ExclusiveStateMemory,
    ExclusiveStateBackground,
    ExclusiveStateReachbility
};


@interface ExclusiveState : NSObject

@property (nonatomic, copy) ExclusiveAction action;
@property (nonatomic, copy) NSString *url;
@property (nonatomic) ExclusiveStateType type;
@property (nonatomic) ShowMode mode;

@end


@implementation ExclusiveState
@end


@interface AppStateController ()

@property (nonatomic, strong) NSMutableArray *exclusives;

@end


@implementation AppStateController

- (instancetype)initWithState:(AppState *)state
{
    self = [super init];
    
    if (self)
    {
        [self setExclusives:[NSMutableArray new]];
        [self setState:state];
    }
    
    return self;
}

- (void)setShowMode:(ShowMode)mode
{
    if (mode != [[self state] showMode])
    {
        RUN_ACTION_ASYNC_MAIN([self onDebug], (mode == ShowMultiDebug));
    }
    
    [self setState:[[self state] updatedShowMode:mode]];
    
    RUN_ACTION_ASYNC_MAIN([self onModeUpdate], [[self state] showMode]);
}

- (void)setShowOptions:(ShowOptions)options
{
    [self setState:[[self state] updatedShowOptions:options]];
    
    RUN_ACTION_ASYNC_MAIN([self onOptionsUpdate], [[self state] showOptions]);
}

- (void)setRecordState:(RecordState)rState
{
    [self setState:[[self state] updatedRecordState:rState]];
    
    RUN_ACTION_ASYNC_MAIN([self onRecordUpdate], [[self state] recordState]);
    
    if (((rState == RecordStateRecordingWithMicrophone) && ([[self state] micEnabled] == NO)) ||
        ((rState == RecordStateRecording) && [[self state] micEnabled]))
    {
        [self invertMic];
    }
}

- (void)setWebXR:(BOOL)webXR
{
    [self setState:[[self state] updatedWebXR:webXR]];
    
    RUN_ACTION_ASYNC_MAIN([self onXRUpdate], [[self state] webXR]);
}

- (void)setARRequest:(NSDictionary *)dict
{
    [self setState:[[self state] updatedWithARRequest:dict]];
    
    RUN_ACTION_ASYNC_MAIN([self onRequestUpdate], dict);
}

- (void)setARInterruption:(BOOL)interruption
{
    [self setState:[[self state] updatedWithInterruption:interruption]];
    
    RUN_ACTION_ASYNC_MAIN([self onInterruption], interruption);
}

- (BOOL)shouldShowURLBar
{
    if ([[self state] recordState] == RecordStatePhoto ||
        [[self state] recordState] == RecordStateRecording ||
        [[self state] recordState] == RecordStateRecordingWithMicrophone ||
        [[self state] recordState] == RecordStateGoingToRecording ||
        (([[self state] recordState] == RecordStatePreviewing) && ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)))
    {
        return NO;
    }
    
    BOOL showURLBar = NO;
    
    if ([[self state] webXR] == NO) {
        showURLBar = YES;
    } else {
        if([[self state] showMode] == ShowDebug) {
            showURLBar = NO;
        } else if ([[self state] showMode] == ShowMulti) {
            showURLBar = YES;
        } else if ([[self state] showMode] == ShowMultiDebug) {
            showURLBar = YES;
        }
    }
    
    return showURLBar;
}

- (BOOL)shouldSendARKData
{
    return [[self state] webXR] && [[self state] aRRequest];
}

- (BOOL)shouldSendCVData {
    return [[self state] computerVisionFrameRequested] && [[self state] sendComputerVisionData] && [[self state] userGrantedSendingComputerVisionData];
}

- (BOOL)shouldSendNativeTime {
    return [[self state] numberOfTimesSendNativeTimeWasCalled] < 9;
}

- (void)invertMic
{
    BOOL micEnabledUpdated = ![[self state] micEnabled];
    
    [self setState:[[self state] updatedWithMicEnabled:micEnabledUpdated]];
    
    RUN_ACTION_ASYNC_MAIN([self onMicUpdate], micEnabledUpdated);
}

- (void)invertShowMode
{
    [[self state] showMode] == ShowSingle ? [self setShowMode:ShowMulti] : [self setShowMode:ShowSingle];
}

- (void)invertDebugMode
{
    [[self state] showMode] == ShowMulti ? [self setShowMode:ShowMultiDebug] : [self setShowMode:ShowMulti];
}

- (BOOL)wasMemoryWarning
{
    __block BOOL was = NO;
    
    [[self exclusives] enumerateObjectsUsingBlock:^(ExclusiveState *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
     {
         if ([obj type] == ExclusiveStateMemory)
         {
             was = YES;
             *stop = YES;
         }
     }];
    
    return was;
}

- (BOOL)isRecording
{
    switch ([[self state] recordState])
    {
        case RecordStateGoingToRecording:
        case RecordStatePhoto:
        case RecordStateRecording:
        case RecordStateRecordingWithMicrophone:
            return YES;
            
        default:
            return NO;
    }
}

- (void)saveOnMessageShowMode
{
    [self saveOnType:ExclusiveStateMessage url:nil mode:[[self state] showMode]];
}

- (void)applyOnMessageShowMode
{
    [self applyOnType:ExclusiveStateMessage];
}

- (void)saveDidReceiveMemoryWarningOnURL:(NSString *)url
{
    [self saveOnType:ExclusiveStateMemory url:url mode:0];
}

- (void)applyOnDidReceiveMemoryAction
{
    [self applyOnType:ExclusiveStateMemory];
}

- (void)saveMoveToBackgroundOnURL:(NSString *)url
{
    [self setShowMode:ShowNothing];
    [self saveOnType:ExclusiveStateBackground url:url mode:0];
}

- (void)applyOnEnterForegroundAction
{
    [self applyOnType:ExclusiveStateBackground];
}

- (void)saveNotReachableOnURL:(NSString *)url
{
    [self saveOnType:ExclusiveStateReachbility url:url mode:0];
}

- (void)applyOnReachableAction
{
    [self applyOnType:ExclusiveStateReachbility];
}

#pragma mark Private

- (void)saveOnType:(ExclusiveStateType)type url:(NSString *)url mode:(ShowMode)mode
{
    ExclusiveState *state = [ExclusiveState new];
    if (url != nil)
    {
        [state setUrl:url];
    }
    else
    {
        [state setMode:mode];
    }
    [state setType:type];
    
    __weak typeof (self) blockSelf = self;
    //__weak typeof (ExclusiveState *) blockState = state;
    
    switch (type)
    {
        case ExclusiveStateMessage:
        {
            [state setAction:^
             {
                 [blockSelf setShowMode:mode];
             }];
            break;
        }
        case ExclusiveStateMemory:
        {
            [state setAction:^
             {
                 RUN_ACTION_ASYNC_MAIN([blockSelf onMemoryWarning], url);
             }];
            break;
        }
        case ExclusiveStateBackground:
        {
            [state setAction:^
             {
                 RUN_ACTION_ASYNC_MAIN([blockSelf onEnterForeground], url);
             }];
            break;
        }
        case ExclusiveStateReachbility:
        {
            [state setAction:^
             {
                 RUN_ACTION_ASYNC_MAIN([blockSelf onReachable], url);
             }];
            break;
        }
    }
    
    [[self exclusives] addObject:state];
}

- (void)applyOnType:(ExclusiveStateType)type
{
    __block ExclusiveState *message = nil;
    
    [[self exclusives] enumerateObjectsUsingBlock:^(ExclusiveState *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
     {
         if ([obj type] == type)
         {
             message = obj;
             *stop = YES;
         }
     }];
    
    if (message != nil)
    {
        [message action]();
        [[self exclusives] removeObject:message];
    }
}

@end
