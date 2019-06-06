#import <Foundation/Foundation.h>
#import "ARKHelper.h"
#import <Accelerate/Accelerate.h>
#import <os/lock.h>

@class AppState;

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
typedef void (^DidUpdate)(void);
typedef void (^DidChangeTrackingState)(ARCamera *);
typedef void (^SessionWasInterrupted)(void);
typedef void (^SessionInterruptionEnded)(void);
typedef void (^DidFailSession)(NSError *);
typedef void (^DidUpdateWindowSize)(void);
typedef void (^DetectionImageCreatedCompletionType)(BOOL success, NSString* errorString);
typedef void (^ActivateDetectionImageCompletionBlock)(BOOL success, NSString* errorString, NSDictionary* detectedImageAnchor);
typedef void (^GetWorldMapCompletionBlock)(BOOL success, NSString* errorString, NSDictionary* worldMap);
typedef void (^SetWorldMapCompletionBlock)(BOOL success, NSString* errorString);
typedef void (^ResultBlock)(NSDictionary *);
typedef void (^ResultArrayBlock)(NSArray *);
@protocol ARKControllerProtocol;

@interface ARKController : NSObject

@property(copy) DidUpdate didUpdate;
@property(copy) DidChangeTrackingState didChangeTrackingState;
@property(copy) SessionWasInterrupted sessionWasInterrupted;
@property(copy) SessionInterruptionEnded sessionInterruptionEnded;
@property(copy) DidFailSession didFailSession;
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
 A flag representing whether geometry is being sent in arrays (true) or dictionaries (false)
 */
@property(nonatomic) bool geometryArrays;

/**
 Request a CV frame
 */
@property(nonatomic) BOOL computerVisionFrameRequested;


/**
 Enum representing the world sensing data sending authorization status
 @see SendWorldSensingDataAuthorizationState
 */
@property(nonatomic) WebXRAuthorizationState webXRAuthorizationStatus;

@property (nonatomic, strong) ARSession *session;
@property (nonatomic, copy) NSDictionary *request;
@property (nonatomic, strong) ARConfiguration *configuration;
@property (nonatomic, strong) ARWorldMap *backgroundWorldMap;
@property (nonatomic, strong) NSMutableDictionary *objects; // key - JS anchor name : value - ARAnchor NSUUID string
/// Dictionary holding ARReferenceImages by name
@property(nonatomic, strong) NSMutableDictionary* referenceImageMap;
/// Dictionary holding completion blocks by image name
@property(nonatomic, strong) NSMutableDictionary* detectionImageActivationPromises;
- (void)updateFaceAnchorData:(ARFaceAnchor *)faceAnchor toDictionary:(NSMutableDictionary *)faceAnchorDictionary;
/// Array of anchor dictionaries that were added since the last frame.
/// Contains the initial data of the anchor when it was added.
@property (nonatomic, strong) NSMutableArray *addedAnchorsSinceLastFrame;
/// Dictionary holding completion blocks by image name: when an image anchor is removed,
/// if the name exsist in this dictionary, call activate again using the callback stored here.
@property(nonatomic, strong) NSMutableDictionary* detectionImageActivationAfterRemovalPromises;
/// Array of anchor IDs that were removed since the last frame
@property(nonatomic, strong) NSMutableArray *removedAnchorsSinceLastFrame;
/// Dictionary holding completion blocks by image name
@property(nonatomic, strong) NSMutableDictionary* detectionImageCreationPromises;
/// Array holding dictionaries representing detection image data
@property(nonatomic, strong) NSMutableArray *detectionImageCreationRequests;
/**
 We don't send the face geometry on every frame, for performance reasons. This number indicates the
 current number of frames without sending the face geometry
 */
@property int numberOfFramesWithoutSendingFaceGeometry;
// For saving WorldMap
@property(nonatomic, strong) NSURL *worldSaveURL;
@property(nonatomic, strong) SetWorldMapCompletionBlock setWorldMapPromise;
/// completion block for getWorldMap request
@property(nonatomic, strong) GetWorldMapCompletionBlock getWorldMapPromise;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) id<ARKControllerProtocol> controller;
/// The CV image being sent to JS is downscaled using the metho
/// downscaleByFactorOf2UntilLargestSideIsLessThan512AvoidingFractionalSides
/// This call has a side effect on computerVisionImageScaleFactor, that's later used
/// in order to scale the intrinsics of the camera
@property (nonatomic) float computerVisionImageScaleFactor;
/*
 Computer vision properties
 We hold different data structures, like accelerate, NSData, and NSString buffers,
 to avoid allocating/deallocating a huge amount of memory on each frame
 */
/// Luma buffer
@property vImage_Buffer lumaBuffer;
/// A temporary luma buffer used by the Accelerate framework in the buffer scale opration
@property void* lumaScaleTemporaryBuffer;
/// The luma buffer size that's being sent to JS
@property CGSize lumaBufferSize;
/// A data buffer holding the luma information. It's created only onced reused on every frame
/// by means of the replaceBytesInRange method
@property(nonatomic, strong) NSMutableData* lumaDataBuffer;
/// The luma string buffer being sent to JS
@property(nonatomic, strong) NSMutableString* lumaBase64StringBuffer;
/*
 The same properties for luma are used for chroma
 */
@property vImage_Buffer chromaBuffer;
@property void* chromaScaleTemporaryBuffer;
@property CGSize chromaBufferSize;
@property(nonatomic, strong) NSMutableData* chromaDataBuffer;
@property(nonatomic, strong) NSMutableString* chromaBase64StringBuffer;
@property os_unfair_lock lock;
@property NSDictionary *arkData;
@property NSDictionary *computerVisionData;
@property(nonatomic) ShowOptions showOptions;

/// Dictionary that maps a user-generated anchor ID with the one generated by ARKit
@property (nonatomic, strong) NSMutableDictionary *arkitGeneratedAnchorIDUserAnchorIDMap;

@property(nonatomic) BOOL initializingRender;

- (instancetype)initWithType:(ARKType)type rootView:(UIView *)rootView;

/**
 Updates the hit test focus point and updates the orientation

 @param size the size of the new frame
 */
- (void)viewWillTransitionToSize:(CGSize)size;

- (void)setWebXRAuthorizationStatus:(WebXRAuthorizationState)webXRAuthorizationStatus;

@end

