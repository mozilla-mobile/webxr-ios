#import <Foundation/Foundation.h>
#import "ARKHelper.h"

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
typedef void (^DidUpdate)(ARKController *);
typedef void (^DidFailSession)(NSError *);
typedef void (^DidUpdateWindowSize)(void);
typedef void (^DetectionImageCreatedCompletionType)(BOOL success, NSString* errorString);
typedef void (^ActivateDetectionImageCompletionBlock)(BOOL success, NSString* errorString, NSDictionary* detectedImageAnchor);
typedef void (^GetWorldMapCompletionBlock)(BOOL success, NSString* errorString, NSDictionary* worldMap);
typedef void (^SetWorldMapCompletionBlock)(BOOL success, NSString* errorString);
typedef void (^ResultBlock)(NSDictionary *);
typedef void (^ResultArrayBlock)(NSArray *);

@interface ARKController : NSObject

@property(copy) DidUpdate didUpdate;
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
 Request a CV frame
 */
@property(nonatomic) BOOL computerVisionFrameRequested;


/**
 Enum representing the world sensing data sending authorization status
 @see SendWorldSensingDataAuthorizationState
 */
@property(nonatomic) SendWorldSensingDataAuthorizationState sendingWorldSensingDataAuthorizationStatus;

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
- (void)updateARKDataWithFrame:(ARFrame *)frame;
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
- (NSData *)getDecompressedData:(NSData *) compressed;

/// Dictionary that maps a user-generated anchor ID with the one generated by ARKit
@property (nonatomic, strong) NSMutableDictionary *arkitGeneratedAnchorIDUserAnchorIDMap;

- (void)setupDeviceCamera;

- (instancetype)initWithType:(ARKType)type rootView:(UIView *)rootView;

/**
 Updates the hit test focus point and updates the orientation

 @param size the size of the new frame
 */
- (void)viewWillTransitionToSize:(CGSize)size;

/**
 Save the current ARKit ARWorldMap if tracking.
 */
- (void)saveWorldMapInBackground;

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

/**
 Performs a hit test over the scene

 @param point source point for the ray casting in normalized coordinates
 @param type A bit mask representing the hit test types to be considered
 @return an array of hit tests
 */
- (NSArray *)hitTestNormPoint:(CGPoint)point types:(NSUInteger)type;

/**
 Adds a "regular" anchor to the session

 @param userGeneratedAnchorID the ID the user wants this new anchor to have
 @param transform the transform of the anchor
 @return YES if the anchorID didn't exist already
 */
- (BOOL)addAnchor:(NSString *)userGeneratedAnchorID transform:(NSArray *)transform;

/// Removes the anchors with the ids passed as parameter from the scene.
/// @param anchorIDsToDelete An array of anchor IDs. These can be both ARKit-generated anchorIDs or user-generated anchorIDs
- (void)removeAnchors:(NSArray *)anchorIDsToDelete;

- (BOOL)trackingStateNormal;

- (NSString *)trackingState;

/**
 Remove all the plane anchors further than the value hosted in NSUserdDefaults with the
 key "distantAnchorsDistanceKey"
 */
- (void)removeDistantAnchors;

/**
 Removes the reference image from the current set of reference images and re-runs the session
 
 - It fails when the current session is not of type ARWorldTrackingConfiguration
 
 - It fails when the image trying to be deactivated is not in the current set of detection images
 
 - It fails when the image trying to be deactivated was already detected
 
 - It fails when the image trying to be deactivated is still active

 @param imageName The name of the image to be deactivated
 @param completion The promise that will be called with the outcome of the deactivation
 */
- (void)deactivateDetectionImage:(NSString *)imageName completion:(DetectionImageCreatedCompletionType)completion;

/**
  Get the current tracker World Map and return it in an base64 encoded string in a dictionary, for sending to Javascript
 
  - Fails if tracking isn't initialized, or if the acquisition of a World Map fails for some other reason
 
  @param completion The completion block that will be called with the outcome of the acquisition of the world map
  */
- (void)getWorldMap:(GetWorldMapCompletionBlock)completion;

- (void)setSendingWorldSensingDataAuthorizationStatus:(SendWorldSensingDataAuthorizationState)sendingWorldSensingDataAuthorizationStatus;

 /**
 Removes all the anchors in the curren session.
 
 If the current session is not of class ARFaceTrackingConfiguration, create a
 ARFaceTrackingConfiguration and run the session with it
 
 Otherwise, create a ARWorldTrackingConfiguration, add the images that were not detected
 in the previous ARWorldTrackingConfiguration session, and run the session
 */
- (void)switchCameraButtonTapped;

+ (BOOL)supportsARFaceTrackingConfiguration;

@end

