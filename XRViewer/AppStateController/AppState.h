#import <Foundation/Foundation.h>

#define MICROPHONE_ENABLED_BY_DEFAULT  YES
#define SHOW_MODE_BY_DEFAULT           ShowNothing
#define SHOW_OPTIONS_BY_DEFAULT        None
#define POPUP_ENABLED_BY_DEFAULT       YES
#define POPUP_ENABLED_BY_DEFAULT       YES
#define USER_GRANTED_SENDING_COMPUTER_VISION_DATA_BY_DEFAULT    NO
#define USER_GRANTED_SENDING_WORLD_DATA_BY_DEFAULT    NO

/*
 ShowDebug, // Shows the only the debug info
 ShowMulti, // Shows the URL Bar and the record button
 ShowMultiDebug // Shows the URL Bar the record button and the debug info
 */

/**
 An enum representing the state of the app UI at a given time

 - ShowNothing: Shows the warning labels
 - ShowSingle: Shows the record button
 - ShowDebug: Shows the record button, the helper and build label, and the AR debug info
 - ShowMulti: Shows the URL Bar and the record button
 - ShowMultiDebug: Shows the URL Bar the record button and the AR debug info
 */
typedef NS_ENUM(NSUInteger, ShowMode)
{
    ShowNothing,
    ShowSingle,
    ShowDebug,
    ShowMulti,
    ShowMultiDebug
};

/**
 Show options. This option set is built from the AR Request dictionary received on initAR

 - None: Shows nothing
 - Mic: Shows the mic button
 - Capture: Shows the record button
 - CaptureTime: Shows the record dot button
 - Browser: Shows in browser mode
 - ARWarnings: Shows warnings reported by ARKit
 - ARFocus: Shows a focus node
 - ARObject: Shows AR objects
 - Debug: Not used
 - ARPlanes: Shows AR planes
 - ARPoints: Shows AR feature points
 - ARStatistics: Shows AR Statistics
 - BuildNumber: Shows the app build number
 - Full: Shows everything
 */
typedef NS_OPTIONS(NSUInteger, ShowOptions)
{
    None         = 0,

    Mic          = (1 << 0),
    Capture      = (1 << 1),
    CaptureTime  = (1 << 2),
    Browser      = (1 << 3),
    ARWarnings   = (1 << 4),
    ARFocus      = (1 << 5),
    ARObject     = (1 << 6),
    Debug        = (1 << 7),

    ARPlanes     = (1 << 8),
    ARPoints     = (1 << 9),
    ARStatistics = (1 << 10),
    BuildNumber  = (1 << 11),

    Full         = NSUIntegerMax
};

/**
 The app internal state
 */
@interface AppState : NSObject <NSCopying>

@property(nonatomic, copy) NSDictionary *aRRequest;
@property(nonatomic, copy) NSString *trackingState;
@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;
@property(nonatomic) BOOL webXR;
@property(nonatomic) BOOL micEnabled;
@property(nonatomic) BOOL interruption;
@property(nonatomic) BOOL computerVisionFrameRequested;
@property(nonatomic) BOOL shouldRemoveAnchorsOnNextARSession;
@property(nonatomic) BOOL sendComputerVisionData;
@property(nonatomic) BOOL shouldShowSessionStartedPopup;
@property(nonatomic) int numberOfTimesSendNativeTimeWasCalled;
@property(nonatomic) bool userGrantedSendingComputerVisionData;
@property(nonatomic) bool askedComputerVisionData;
@property(nonatomic) bool userGrantedSendingWorldStateData;
@property(nonatomic) bool askedWorldStateData;

+ (instancetype)defaultState;

- (instancetype)updatedShowMode:(ShowMode)showMode;
- (instancetype)updatedShowOptions:(ShowOptions)showOptions;
- (instancetype)updatedWebXR:(BOOL)webXR;
- (instancetype)updatedWithARRequest:(NSDictionary *)dict;
- (instancetype)updatedWithMicEnabled:(BOOL)enabled;
- (instancetype)updatedWithInterruption:(BOOL)interruption;

@end
