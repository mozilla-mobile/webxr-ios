#import <Foundation/Foundation.h>

#define MICROPHONE_ENABLED_BY_DEFAULT  YES
#define RECORD_STATE_BY_DEFAULT        RecordStateIsReady
#define SHOW_MODE_BY_DEFAULT           ShowNothing
#define SHOW_OPTIONS_BY_DEFAULT        None
#define POPUP_ENABLED_BY_DEFAULT       YES

typedef NS_ENUM(NSUInteger, ShowMode)
{
    ShowNothing,
    ShowSingle,
    ShowDebug, // Shows the only the debug info
    ShowMulti, // Shows the URL Bar and the record button
    ShowMultiDebug // Shows the URL Bar, the record button and the debug info
};

typedef NS_OPTIONS(NSUInteger, ShowOptions)
{
    None         = 0,
    
    // ShowMulti
    Mic          = (1 << 0),
    Capture      = (1 << 1),
    CaptureTime  = (1 << 2),
    Browser      = (1 << 3),
    ARWarnings   = (1 << 4), // showSingle
    ARFocus      = (1 << 5),
    ARObject     = (1 << 6),
    Debug        = (1 << 7),
    
    // ShowMultiDebug
    ARPlanes     = (1 << 8),
    ARPoints     = (1 << 9),
    ARStatistics = (1 << 10),
    BuildNumber  = (1 << 11),
    
    Full         = NSUIntegerMax
};

typedef NS_ENUM(NSUInteger, RecordState)
{
    RecordStateIsReady,
    RecordStatePhoto,
    RecordStateGoingToRecording, // for preparing UI (JS) for capturing(important for first frame)
    RecordStateRecording,
    RecordStateRecordingWithMicrophone,
    RecordStatePreviewing,
    RecordStateDisabled, // by hardware
    RecordStateAuthDisabled, // by user
    RecordStateError
};

@interface AppState : NSObject <NSCopying>

@property(nonatomic, copy) NSDictionary *aRRequest;
@property(nonatomic, copy) NSString *trackingState;
@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;
@property(nonatomic) RecordState recordState;
@property(nonatomic) BOOL webXR;
@property(nonatomic) BOOL micEnabled;
@property(nonatomic) BOOL interruption;
@property(nonatomic) BOOL computerVisionFrameRequested;
@property(nonatomic) BOOL shouldRemoveAnchorsOnNextARSession;
@property(nonatomic) BOOL sendComputerVisionData;
@property(nonatomic) BOOL shouldShowSessionStartedPopup;
@property(nonatomic) int numberOfTimesSendNativeTimeWasCalled;

@property(nonatomic) bool userGrantedSendingComputerVisionData;

+ (instancetype)defaultState;

- (instancetype)updatedShowMode:(ShowMode)showMode;
- (instancetype)updatedShowOptions:(ShowOptions)showOptions;
- (instancetype)updatedRecordState:(RecordState)state;
- (instancetype)updatedWebXR:(BOOL)webXR;
- (instancetype)updatedWithARRequest:(NSDictionary *)dict;
- (instancetype)updatedWithMicEnabled:(BOOL)enabled;
- (instancetype)updatedWithTrackingState:(NSString *)state;
- (instancetype)updatedWithInterruption:(BOOL)interruption;

@end
