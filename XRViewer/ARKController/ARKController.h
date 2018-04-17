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

// Appy this scale factor to the captured image before sending it to the JS side
#define COMPUTER_VISION_IMAGE_SCALE_FACTOR 4.0

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

@interface ARKController : NSObject

@property(copy) DidUpdate didUpdate;
@property(copy) DidInterupt didInterupt;
@property(copy) DidFailSession didFailSession;
@property(copy) DidChangeTrackingState didChangeTrackingState;
@property(copy) DidAddPlaneAnchors didAddPlaneAnchors;
@property(copy) DidRemovePlaneAnchors didRemovePlaneAnchors;
@property(copy) DidUpdateWindowSize didUpdateWindowSize;
@property UIInterfaceOrientation interfaceOrientation;

@property(nonatomic) BOOL shouldUpdateWindowSize;

@property ARKitSessionState arSessionState;

@property(nonatomic) bool computerVisionDataEnabled;

- (instancetype)initWithType:(ARKType)type rootView:(UIView *)rootView;
- (UIView *)arkView;

- (void)viewWillTransitionToSize:(CGSize)size;

- (void)startSessionWithAppState:(AppState *)state;

- (void)resumeSessionWithAppState: (AppState*)state;

- (void)pauseSession;

- (NSDictionary *)arkData;

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
@end

