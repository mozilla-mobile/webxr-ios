#import "ARKController.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import "Compression.h"
#import "XRViewer-Swift.h"

@interface ARKController () {
}

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
        self.initializingRender = YES;

        self.addedAnchorsSinceLastFrame = [NSMutableArray new];
        self.removedAnchorsSinceLastFrame = [NSMutableArray new];
        self.arkitGeneratedAnchorIDUserAnchorIDMap = [NSMutableDictionary new];
        [self setShouldUpdateWindowSize:YES];
        [self setGeometryArrays:NO];

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

        self.webXRAuthorizationStatus = WebXRAuthorizationStateNotDetermined;
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
    [[self controller] setRenderViewSize: size];
    [[self controller] setHitTestFocus:CGPointMake(size.width / 2, size.height / 2)];
    self.interfaceOrientation = [Utils getInterfaceOrientationFromDeviceOrientation];
}

- (void)setWebXRAuthorizationStatus:(WebXRAuthorizationState)authorizationStatus {
    
    if (self.webXRAuthorizationStatus != authorizationStatus) {
        _webXRAuthorizationStatus = authorizationStatus;
        switch (self.webXRAuthorizationStatus) {
            case WebXRAuthorizationStateNotDetermined: {
                NSLog(@"WebXR auth changed to not determined");
                self.objects = [NSMutableDictionary new];
                break;
            }
            case WebXRAuthorizationStateWorldSensing:
            case WebXRAuthorizationStateVideoCameraAccess: {
                NSLog(@"WebXR auth changed to video camera access/world sensing");
                
                // make sure all the anchors are in the objects[] array, and mark them as added
                NSArray *anchors = [[[self session] currentFrame] anchors];
                for (ARAnchor* addedAnchor in anchors) {
                    if (!self.objects[[self anchorIDFor:addedAnchor]]) {
                        NSMutableDictionary *addedAnchorDictionary = [[self createDictionaryFor:addedAnchor] mutableCopy];
                        self.objects[[self anchorIDFor:addedAnchor]] = addedAnchorDictionary;
                        [self.addedAnchorsSinceLastFrame addObject: self.objects[[self anchorIDFor:addedAnchor]]];
                    }
                }
                
                [self createRequestedDetectionImages];
                
                // Only need to do this if there's an outstanding world map request
                if (self.getWorldMapPromise) {
                    [self _getWorldMap];
                }
                break;
            }
            case WebXRAuthorizationStateLite:
            case WebXRAuthorizationStateMinimal:
            case WebXRAuthorizationStateDenied: {
                NSLog(@"WebXR auth changed to lite/minimal/denied");
                
                NSArray *anchors = [[[self session] currentFrame] anchors];
                for (ARAnchor* addedAnchor in anchors) {
                    if (!self.objects[[self anchorIDFor:addedAnchor]]) {
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
                
                // Tony 2/26/19: Below for loop causing a crash when denying world access
                //            for (NSDictionary* referenceImageDictionary in self.detectionImageCreationRequests) {
                //                DetectionImageCreatedCompletionType block = self.detectionImageCreationPromises[referenceImageDictionary[@"uid"]];
                //                block(NO, @"The user denied access to world sensing data");
                //            }
                
                break;
            }
        }
    }
}

#pragma mark Private

- (void)updateFaceAnchorData:(ARFaceAnchor *)faceAnchor toDictionary:(NSMutableDictionary *)faceAnchorDictionary {
    NSMutableDictionary *geometryDictionary = faceAnchorDictionary[@"geometry"];
    if (!geometryDictionary) {
        geometryDictionary = [NSMutableDictionary new];
        faceAnchorDictionary[@"geometry"] = geometryDictionary;
    }
 
    NSMutableArray* vertices = [NSMutableArray arrayWithCapacity:faceAnchor.geometry.vertexCount];
    for (int i = 0; i < faceAnchor.geometry.vertexCount; i++) {
        if (self.geometryArrays) {
            [vertices addObject:[NSNumber numberWithFloat:faceAnchor.geometry.vertices[i].x]];
            [vertices addObject:[NSNumber numberWithFloat:faceAnchor.geometry.vertices[i].y]];
            [vertices addObject:[NSNumber numberWithFloat:faceAnchor.geometry.vertices[i].z]];
        } else {
            [vertices addObject:dictFromVector3(faceAnchor.geometry.vertices[i])];
        }
    }
    geometryDictionary[@"vertices"] = vertices;
    
    NSMutableArray *blendShapesDictionary = faceAnchorDictionary[@"blendshapes"];
    [self setBlendShapes:faceAnchor.blendShapes toArray:blendShapesDictionary];
    
    // Remove the rest of the geometry data, since it doesn't change
    geometryDictionary[@"vertexCount"] = nil;
    geometryDictionary[@"textureCoordinateCount"] = nil;
    geometryDictionary[@"textureCoordinates"] = nil;
    geometryDictionary[@"triangleCount"] = nil;
    geometryDictionary[@"triangleIndices"] = nil;
}

@end
