#import "ARKController.h"
#import "WebARKHeader.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import "Compression.h"
#import "XRViewer-Swift.h"

@interface ARKController () {
}

@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;

@end

@implementation ARKController {
}

#pragma mark Interface

- (void)dealloc
{
    DDLogDebug(@"ARKController dealloc");
}

- (instancetype)initWithType:(ARKType)type rootView:(UIView *)rootView
{
    self = [super init];
    
    if (self)
    {
        self.lock = OS_UNFAIR_LOCK_INIT;
        self.objects = [NSMutableDictionary new];
        self.computerVisionData = NULL;
        self.arkData = NULL;

        self.addedAnchorsSinceLastFrame = [NSMutableArray new];
        self.removedAnchorsSinceLastFrame = [NSMutableArray new];
        self.arkitGeneratedAnchorIDUserAnchorIDMap = [NSMutableDictionary new];
        [self setShouldUpdateWindowSize:YES];

        [self setSession:[ARSession new]];
        [[self session] setDelegate:self];
        [self setArSessionState:ARKSessionUnknown];
        
        // don't want anyone using this
        self.backgroundWorldMap = nil;

        /**
         A configuration for running world tracking.
         
         @discussion World tracking provides 6 degrees of freedom tracking of the device.
         By finding feature points in the scene, world tracking enables performing hit-tests against the frame.
         Tracking can no longer be resumed once the session is paused.
         */
        
        ARWorldTrackingConfiguration* worldTrackingConfiguration = [ARWorldTrackingConfiguration new];
        
        [worldTrackingConfiguration setPlaneDetection:ARPlaneDetectionHorizontal | ARPlaneDetectionVertical];
        [worldTrackingConfiguration setWorldAlignment:ARWorldAlignmentGravityAndHeading];
        [self setConfiguration: worldTrackingConfiguration];
        
        Class cls = (type == ARKMetal) ? [ARKMetalController class] : [ARKSceneKitController class];
        id<ARKControllerProtocol> controller = [[cls alloc] initWithSesion:[self session] size:[rootView bounds].size];
        [self setController:controller];
        [rootView addSubview:[controller getRenderView]];
        [[controller getRenderView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[[[controller getRenderView] topAnchor] constraintEqualToAnchor:[rootView topAnchor]] setActive:YES];
        [[[[controller getRenderView] leftAnchor] constraintEqualToAnchor:[rootView leftAnchor]] setActive:YES];
        [[[[controller getRenderView] rightAnchor] constraintEqualToAnchor:[rootView rightAnchor]] setActive:YES];
        [[[[controller getRenderView] bottomAnchor] constraintEqualToAnchor:[rootView bottomAnchor]] setActive:YES];
        
        [[self controller] setHitTestFocus:[[[self controller] getRenderView] center]];

        self.interfaceOrientation = [Utils getInterfaceOrientationFromDeviceOrientation];
        
        self.lumaDataBuffer = nil;
        self.lumaBase64StringBuffer = nil;
        self.chromaDataBuffer = nil;
        self.chromaBase64StringBuffer = nil;
        self.computerVisionImageScaleFactor = 4.0;
        self.lumaBufferSize = CGSizeMake(0.0f, 0.0f);

        self.sendingWorldSensingDataAuthorizationStatus = SendWorldSensingDataAuthorizationStateNotDetermined;
        self.detectionImageActivationPromises = [NSMutableDictionary new];
        self.referenceImageMap = [NSMutableDictionary new];
        self.detectionImageCreationRequests = [NSMutableArray new];
        self.detectionImageCreationPromises = [NSMutableDictionary new];
        self.detectionImageActivationAfterRemovalPromises = [NSMutableDictionary new];
        
        self.getWorldMapPromise = nil;
        self.setWorldMapPromise = nil;
        
        NSFileManager *filemgr = [NSFileManager defaultManager];

        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES );
        NSURL *docsDir = [NSURL fileURLWithPath:[dirPaths objectAtIndex:0]];
        NSURL *newDir = [docsDir URLByAppendingPathComponent:@"maps" isDirectory:YES];
        //if ([storeURL checkResourceIsReachableAndReturnError:&error]) {
        NSError* theError = nil;
        if ([filemgr createDirectoryAtURL:newDir withIntermediateDirectories:YES attributes:nil error:&theError] == NO)
        {
            // Failed to create directory
            self.worldSaveURL = nil;
            DDLogError(@"Couldn't create map save directory error - %@", theError);
        } else {
            self.worldSaveURL = [newDir URLByAppendingPathComponent:@"webxrviewer"];
        }
 
        self.numberOfFramesWithoutSendingFaceGeometry = 0;
    }
    
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size
{
    [[self controller] setHitTestFocus:CGPointMake(size.width / 2, size.height / 2)];
    self.interfaceOrientation = [Utils getInterfaceOrientationFromDeviceOrientation];
}

- (NSDictionary*)getARKData {
    NSDictionary* data;
    os_unfair_lock localLock;
    localLock = self.lock;
    os_unfair_lock_lock(&(localLock));
    data = self.arkData;
    os_unfair_lock_unlock(&(localLock));
    self.lock = localLock;
    
    return data;
}

- (NSDictionary*)getComputerVisionData {
    NSDictionary* data;
    os_unfair_lock localLock;
    localLock = self.lock;
    os_unfair_lock_lock(&(localLock));
    data = self.computerVisionData;
    self.computerVisionData = NULL;
    os_unfair_lock_unlock(&(localLock));
    self.lock = localLock;
    
    return data;
}

- (void)setShowMode:(ShowMode)showMode
{
    _showMode = showMode;
    
    [[self controller] setShowMode:showMode];
}

- (void)setShowOptions:(ShowOptions)showOptions
{
    _showOptions = showOptions;
    
    [[self controller] setShowOptions:showOptions];
}

- (NSArray *)hitTestNormPoint:(CGPoint)normPoint types:(NSUInteger)type
{
    CGSize renderSize = [[[self controller] getRenderView] bounds].size;
    
    CGPoint point = CGPointMake(normPoint.x * renderSize.width, normPoint.y * renderSize.height);
    
    NSArray *result = [[self controller] hitTest:point with:type];
    
    return hitTestResultArrayFromResult(result);
}

- (void)setSendingWorldSensingDataAuthorizationStatus:(SendWorldSensingDataAuthorizationState)authorizationStatus {
    _sendingWorldSensingDataAuthorizationStatus = authorizationStatus;
    
    switch (self.sendingWorldSensingDataAuthorizationStatus) {
        case SendWorldSensingDataAuthorizationStateNotDetermined: {
            NSLog(@"World sensing auth changed to not determined");
            break;
        }
        case SendWorldSensingDataAuthorizationStateAuthorized: {
            NSLog(@"World sensing auth changed to authorized");
            
            // make sure all the anchors are in the objects[] array, and mark them as added
            NSArray *anchors = [[[self session] currentFrame] anchors];
            for (ARAnchor* addedAnchor in anchors) {
                if (!self.objects[[self anchorIDFor:addedAnchor]]) {
                    NSMutableDictionary *addedAnchorDictionary = [[self createDictionaryFor:addedAnchor] mutableCopy];
                    self.objects[[self anchorIDFor:addedAnchor]] = addedAnchorDictionary;
                }
                [self.addedAnchorsSinceLastFrame addObject: self.objects[[self anchorIDFor:addedAnchor]]];
            }
            
            [self createRequestedDetectionImages];

            // Only need to do this if there's an outstanding world map request
            if (self.getWorldMapPromise) {
                [self _getWorldMap];
            }
            break;
        }
        case SendWorldSensingDataAuthorizationStateSinglePlane: {
            NSLog(@"World sensing auth changed to single plane");
            if (self.getWorldMapPromise) {
                [self _getWorldMap];
            }
            break;
        }
        case SendWorldSensingDataAuthorizationStateDenied: {
            NSLog(@"World sensing auth changed to denied");

            // still need to send the "required" anchors
            NSArray *anchors = [[[self session] currentFrame] anchors];
            for (ARAnchor* addedAnchor in anchors) {
                if (self.objects[[self anchorIDFor:addedAnchor]]) {
                    // if the anchor is in the current object list, and is now not being sent
                    // mark it as removed and remove from the object list
                    if (![self shouldSend:addedAnchor]) {
                        [self.removedAnchorsSinceLastFrame addObject:[self anchorIDFor:addedAnchor]];
                        self.objects[[self anchorIDFor:addedAnchor]] = nil;
                    }
                } else {
                    // if the anchor was not being sent but is in the approved list, start sending it
                    if ([self shouldSend:addedAnchor]) {
                        NSMutableDictionary *addedAnchorDictionary = [[self createDictionaryFor:addedAnchor] mutableCopy];
                        [self.addedAnchorsSinceLastFrame addObject: addedAnchorDictionary];
                        self.objects[[self anchorIDFor:addedAnchor]] = addedAnchorDictionary;
                    }
                }
            }
            
            if (self.getWorldMapPromise) {
                self.getWorldMapPromise(NO, @"The user denied access to world sensing data", nil);
                self.getWorldMapPromise = nil;
            }

            for (NSDictionary* referenceImageDictionary in self.detectionImageCreationRequests) {
                DetectionImageCreatedCompletionType block = self.detectionImageCreationPromises[referenceImageDictionary[@"uid"]];
                block(NO, @"The user denied access to world sensing data");
            }
            [self.detectionImageCreationRequests removeAllObjects];
            [self.detectionImageCreationPromises removeAllObjects];
            break;
        }
    }
}

#pragma mark Private

- (NSString *)trackingState {
    return trackingState([[[self session] currentFrame] camera]);
}

- (void)updateFaceAnchorData:(ARFaceAnchor *)faceAnchor toDictionary:(NSMutableDictionary *)faceAnchorDictionary {
    NSMutableDictionary *geometryDictionary = faceAnchorDictionary[WEB_AR_GEOMETRY_OPTION];
    if (!geometryDictionary) {
        geometryDictionary = [NSMutableDictionary new];
        faceAnchorDictionary[WEB_AR_GEOMETRY_OPTION] = geometryDictionary;
    }
    NSMutableArray* vertices = [NSMutableArray arrayWithCapacity:faceAnchor.geometry.vertexCount];
    for (int i = 0; i < faceAnchor.geometry.vertexCount; i++) {
        [vertices addObject:dictFromVector3(faceAnchor.geometry.vertices[i])];
    }
    geometryDictionary[@"vertices"] = vertices;
    
    NSMutableArray *blendShapesDictionary = faceAnchorDictionary[WEB_AR_BLEND_SHAPES_OPTION];
    [self setBlendShapes:faceAnchor.blendShapes toArray:blendShapesDictionary];
    
    // Remove the rest of the geometry data, since it doesn't change
    geometryDictionary[@"vertexCount"] = nil;
    geometryDictionary[@"textureCoordinateCount"] = nil;
    geometryDictionary[@"textureCoordinates"] = nil;
    geometryDictionary[@"triangleCount"] = nil;
    geometryDictionary[@"triangleIndices"] = nil;
}

@end
