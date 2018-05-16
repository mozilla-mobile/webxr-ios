#import <Foundation/Foundation.h>
#import "ARKHelper.h"
#import "AppState.h"

// The ARSessionConfiguration object passed to the run(_:options:) method is not supported by the current device.
#define UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_CODE 100

// A sensor required to run the session is not available.
#define SENSOR_UNAVAILABLE_ARKIT_ERROR_CODE 101

// A sensor failed to provide the required input.
#define SENSOR_FAILED_ARKIT_ERROR_CODE 102

// The user has denied your app permission to use the device camera.
#define CAMERA_ACCESS_NOT_AUTHORIZED_ARKIT_ERROR_CODE 103

// World tracking has encountered a fatal error.
#define WORLD_TRACKING_FAILED_ARKIT_ERROR_CODE 200

/**
 Enum representing the world sensing authorization status
 
 - SendWorldSensingDataAuthorizationStateNotDetermined: The user didn't say anything about the world sensing
 - SendWorldSensingDataAuthorizationStateAuthorized: The user allowed sending wold sensing data
 - SendWorldSensingDataAuthorizationStateDenied: The user denied sending world sensing data
 */
typedef NS_ENUM(NSUInteger, SendWorldSensingDataAuthorizationState)
{
    SendWorldSensingDataAuthorizationStateNotDetermined,
    SendWorldSensingDataAuthorizationStateAuthorized,
    SendWorldSensingDataAuthorizationStateDenied
};

/**
 An enum representing the ARKit session state

 - ARKSessionUnknown: We don't know about the session state, probably it's been initiated but not ran yet
 - ARKSessionPaused: The session is paused
 - ARKSessionRunning: The session is running
 */
typedef NS_ENUM(NSUInteger, ARKitSessionState)
{
    ARKSessionUnknown,
    ARKSessionPaused,
    ARKSessionRunning
};

typedef NS_ENUM(NSUInteger, ARKType)
{
    ARKMetal,
    ARKSceneKit
};

@class ARKController;
typedef void (^DidUpdate)(ARKController *);
typedef void (^DidFailSession)(NSError *);
typedef void (^DidInterupt)(BOOL);
typedef void (^DidChangeTrackingState)(NSString *state);
typedef void (^DidAddPlaneAnchors)(void);
typedef void (^DidRemovePlaneAnchors)(void);
typedef void (^DidUpdateWindowSize)(void);
typedef void (^CompletionBlockWithDictionary)(NSDictionary*);
typedef void (^DetectionImageCreatedCompletionType)(BOOL success, NSString* errorString);
typedef void (^ActivateDetectionImageCompletionBlock)(BOOL success, NSString* errorString, NSDictionary* detectedImageAnchor);

@interface ARKController : NSObject

@property(copy) DidUpdate didUpdate;
@property(copy) DidInterupt didInterupt;
@property(copy) DidFailSession didFailSession;
@property(copy) DidChangeTrackingState didChangeTrackingState;
@property(copy) DidAddPlaneAnchors didAddPlaneAnchors;
@property(copy) DidRemovePlaneAnchors didRemovePlaneAnchors;
@property(copy) DidUpdateWindowSize didUpdateWindowSize;
@property UIInterfaceOrientation interfaceOrientation;

/**
 Flag indicating if we should inform the JS side about a window size update
 within the current AR Frame update. It's set to YES when the device orientation changes.
 The idea is to only send this kind of update once a Frame.
 */
@property(nonatomic) BOOL shouldUpdateWindowSize;

/**
 Enum indicating the AR session state
 @see ARKitSessionState
 */
@property ARKitSessionState arSessionState;

/**
 A flag representing whether the user allowed the app to send computer vision data to the web page
 */
@property(nonatomic) bool computerVisionDataEnabled;

/**
 Enum representing the world sensing data sending authorization status
 @see SendWorldSensingDataAuthorizationState
 */
@property(nonatomic) SendWorldSensingDataAuthorizationState sendingWorldSensingDataAuthorizationStatus;

- (instancetype)initWithType:(ARKType)type rootView:(UIView *)rootView;
- (UIView *)arkView;

- (void)viewWillTransitionToSize:(CGSize)size;

- (void)startSessionWithAppState:(AppState *)state;

- (void)resumeSessionWithAppState: (AppState*)state;

/**
 Pauses the AR session and sets the arSessionState to paused
 */
- (void)pauseSession;

/**
 ARKit data creates a copy of the current AR data and returns it

 @return the dictionary that's going to be sent to JS
 */
- (NSDictionary *)arkData;

/**
 computer vision data creates a copy of the current CV data and returns it

 @return the dictionary of CV data that's going to be sent to JS
 */
- (NSDictionary*)computerVisionData;

- (NSTimeInterval)currentFrameTimeInMilliseconds;

- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;

- (NSArray *)hitTestNormPoint:(CGPoint)point types:(NSUInteger)type;
- (BOOL)addAnchor:(NSString *)userGeneratedAnchorID transform:(NSArray *)transform;

/// Removes the anchors with the ids passed as parameter from the scene.
/// @param anchorIDsToDelete An array of anchor IDs. These can be both ARKit-generated anchorIDs or user-generated anchorIDs
- (void)removeAnchors:(NSArray *)anchorIDsToDelete;

- (NSArray *)currentPlanesArray;

- (NSString *)trackingState;

- (void)removeAllAnchors;

- (void)runSessionRemovingAnchorsWithAppState:(AppState *)state;

- (void)runSessionResettingTrackingAndRemovingAnchorsWithAppState:(AppState *)state;

- (void)removeDistantAnchors;

- (void)runSessionWithAppState:(AppState *)state;

- (void)createDetectionImage:(NSDictionary *)referenceImageDictionary completion:(DetectionImageCreatedCompletionType)completion;

- (void)activateDetectionImage:(NSString *)imageName completion:(ActivateDetectionImageCompletionBlock)completion;

- (void)deactivateDetectionImage:(NSString *)imageName completion:(DetectionImageCreatedCompletionType)completion;

- (void)destroyDetectionImage:(NSString *)imageName completion:(DetectionImageCreatedCompletionType)completion;

- (void)setSendingWorldSensingDataAuthorizationStatus:(SendWorldSensingDataAuthorizationState)sendingWorldSensingDataAuthorizationStatus;

- (void)removeDetectionImages;

- (void)switchCameraButtonTapped;

+ (BOOL)supportsARFaceTrackingConfiguration;

@end

