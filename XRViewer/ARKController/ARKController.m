#import "ARKController.h"
#import <os/lock.h>
#import "WebARKHeader.h"
#import <AVFoundation/AVFoundation.h>
#import "ARKSceneKitController.h"
#import "ARKMetalController.h"
#import "HitAnchor.h"
#import "HitTestResult.h"

@interface ARKController () <ARSessionDelegate>
{
    NSDictionary *arkData;
    os_unfair_lock lock;
    NSMutableDictionary *anchors; // key - JS anchor name : value - ARAnchor NSUUID string
}

@property (nonatomic, strong) id<ARKControllerProtocol> controller;

@property (nonatomic, copy) NSDictionary *request;
@property (nonatomic, strong) ARSession *session;

@property (nonatomic, strong) ARWorldTrackingConfiguration *configuration;

@property (nonatomic, strong) AVCaptureDevice *device;

@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;

@end

@implementation ARKController

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
        lock = OS_UNFAIR_LOCK_INIT;
        anchors = [NSMutableDictionary new];
        
        [self setSession:[ARSession new]];
        [[self session] setDelegate:self];
        
        /**
         A configuration for running world tracking.
         
         @discussion World tracking provides 6 degrees of freedom tracking of the device.
         By finding feature points in the scene, world tracking enables performing hit-tests against the frame.
         Tracking can no longer be resumed once the session is paused.
         */
        [self setConfiguration:[ARWorldTrackingConfiguration new]];
        [[self configuration] setPlaneDetection:ARPlaneDetectionHorizontal];
        
        Class cls = (type == ARKMetal) ? [ARKMetalController class] : [ARKSceneKitController class];
        id<ARKControllerProtocol> controller = [[cls alloc] initWithSesion:[self session] size:[rootView bounds].size];
        [self setController:controller];
        [rootView addSubview:[controller renderView]];
        [[self controller] setHitTestFocusPoint:[[[self controller] renderView] center]];
    }
    
    return self;
}

- (void)setupDeviceCamera
{
    [self setDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]];
    
    if ([self device] == nil)
    {
        DDLogError(@"Camera device is NIL");
        return;
    }
    
    NSError *outError;
    [[self device] lockForConfiguration:&outError];
    
    if ([[self device] lockForConfiguration:&outError])
    {
        if ([[self device] isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            DDLogDebug(@"AVCaptureFocusModeContinuousAutoFocus Supported");
            [[self device] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if ([[self device] isFocusPointOfInterestSupported])
        {
            DDLogDebug(@"FocusPointOfInterest Supported");
            [[self device] setFocusPointOfInterest:CGPointMake(0.5, 0.5)];
        }
        
        if ([[self device] isSmoothAutoFocusSupported])
        {
            DDLogDebug(@"SmoothAutoFocus Supported");
            [[self device] setSmoothAutoFocusEnabled:YES];
        }
        
        [[self device] unlockForConfiguration];
    }
    else
    {
        DDLogError(@"Camera lock error - %@", outError);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size
{
    [[self controller] setHitTestFocusPoint:CGPointMake(size.width / 2, size.height / 2)];
}

- (UIView *)arkView
{
    return [[self controller] renderView];
}

- (void)stopSession
{
    [[self session] pause];
}

- (NSDictionary *)arkData
{
    NSDictionary *data;
    
    os_unfair_lock_lock(&(lock));
    data = arkData;
    os_unfair_lock_unlock(&(lock));
    
    return [data copy];
}

- (void)startSessionWithAppState:(AppState *)state
{
    if ([state aRRequest] == nil)
    {
        [self setRequest:nil];
        [self removeAnchors:nil];
        [self setSession:nil];
        [[self controller] clean];
        
        return;
    }
    
    [self setRequest:[state aRRequest]];
    
    if ([self session] == nil)
    {
        [self setSession:[ARSession new]];
        [[self session] setDelegate:self];
        [[self controller] updateSession:[self session]];
    }
    
    [[self session] runWithConfiguration:[self configuration]];
    
    [self setupDeviceCamera];
    
    [self setShowMode:[state showMode]];
    [self setShowOptions:[state showOptions]];
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
    CGSize renderSize = [[[self controller] renderView] bounds].size;
    
    CGPoint point = CGPointMake(normPoint.x * renderSize.width, normPoint.y * renderSize.height);
    
    NSArray *result = [[self controller] hitTest:point withType:type];
    
    return hitTestResultArrayFromResult(result);
}

- (BOOL)addAnchor:(NSString *)name transform:(NSArray *)transform
{
    if ((name == nil) || [anchors objectForKey:name])
    {
        DDLogError(@"Duplicate or NIL anchor Name - %@", name);
        return NO;
    }
    
    matrix_float4x4 matrix = [transform isKindOfClass:[NSArray class]] ? matrixFromArray(transform) : matrixFromDictionary((NSDictionary *)transform);
    
    ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:matrix];
    
    [[self session] addAnchor:anchor];
    [anchors setObject:[[anchor identifier] UUIDString] forKey:name];
    
    return YES;
}

- (void)removeAnchors:(NSArray *)anchorNames
{
    ARFrame *currentFrame = [[self session] currentFrame];
    
    if (anchorNames == nil)
    {
        for (ARAnchor *anchor in [currentFrame anchors])
        {
            [[self session] removeAnchor:anchor];
        }
        
        [anchors removeAllObjects];
    }
    else
    {
        for (NSString *name in anchorNames)
        {
            NSString *uuid = anchors[name];
            
            for (ARAnchor *anchor in [currentFrame anchors])
            {
                if ([[[anchor identifier] UUIDString] isEqualToString:uuid])
                {
                    [[self session] removeAnchor:anchor];
                    [anchors removeObjectForKey:uuid];
                    
                    break;
                }
            }
        }
    }
}

#pragma mark Private

- (void)updateARKDataWithFrame:(ARFrame *)frame
{
    @synchronized(self)
    {
        if ([self request] == nil)
        {
            return;
        }
        
        if (frame)
        {
            NSMutableDictionary *newData = [NSMutableDictionary dictionaryWithCapacity:3]; // max request object
            
            if ([[self request][WEB_AR_LIGHT_INTENSITY_OPTION] boolValue])
            {
                newData[WEB_AR_LIGHT_INTENSITY_OPTION] = @([[frame lightEstimate] ambientIntensity]);
            }
            if ([[self request][WEB_AR_CAMERA_OPTION] boolValue])
            {
                newData[WEB_AR_PROJ_CAMERA_OPTION] = arrayFromMatrix4x4([[self controller] cameraProjectionTransform]);
                newData[WEB_AR_CAMERA_TRANSFORM_OPTION] = arrayFromMatrix4x4([[frame camera] transform]);
            }
            if ([[self request][WEB_AR_3D_OBJECTS_OPTION] boolValue])
            {
                newData[WEB_AR_3D_OBJECTS_OPTION] = [self currentAnchorsArray];
            }
            
            os_unfair_lock_lock(&(lock));
            arkData = [newData copy];
            os_unfair_lock_unlock(&(lock));
        }
    }
}

- (NSArray *)currentAnchorsArray
{
    ARFrame *currentFrame = [[self session] currentFrame];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (ARAnchor *anchor in [currentFrame anchors])
    {
        __block NSString *name = nil;
        [anchors enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop)
         {
             if ([[[anchor identifier] UUIDString] isEqualToString:obj])
             {
                 name = key;
                 *stop = YES;
             }
         }];
        
        if (name)
        {
            [array addObject:[self anchorDictFromAnchor:anchor withName:name]];
        }
    }
    
    //DDLogDebug(@"Anchors - %@", [array debugDescription]);
    return [array copy];
}

- (NSDictionary *)anchorDictFromAnchor:(ARAnchor *)anchor withName:(NSString *)name
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    dict[WEB_AR_UUID_OPTION] = name;
    dict[WEB_AR_TRANSFORM_OPTION] = arrayFromMatrix4x4([anchor transform]);
    
    return [dict copy];
}

- (NSArray *)currentPlanesArray
{
    ARFrame *currentFrame = [[self session] currentFrame];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (ARAnchor *anchor in [currentFrame anchors])
    {
        if ([anchor isKindOfClass:[ARPlaneAnchor class]])
        {
            [array addObject:[self planeDictFromPlaneAnchor:(ARPlaneAnchor *)anchor]];
        }
    }
    
    return [array copy];
}

- (NSDictionary *)planeDictFromPlaneAnchor:(ARPlaneAnchor *)planeAnchor
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    dict[WEB_AR_H_PLANE_ID_OPTION] = [[planeAnchor identifier] UUIDString];
    dict[WEB_AR_H_PLANE_CENTER_OPTION] = dictFromVector3([planeAnchor center]);
    dict[WEB_AR_H_PLANE_EXTENT_OPTION] = dictFromVector3([planeAnchor extent]);
    
    return [dict copy];
}

#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame
{
    [self updateARKDataWithFrame:frame];
    
    [self didUpdate](self);
}

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor*>*)anchors
{
    DDLogDebug(@"Add Anchors - %@", [anchors debugDescription]);
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor*>*)anchors
{
    //DDLogDebug(@"Update Anchors - %@", [anchors debugDescription]);
}

- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor*>*)anchors
{
    DDLogDebug(@"Remove Anchors - %@", [anchors debugDescription]);
}

#pragma mark ARSessionObserver

- (void)session:(ARSession *)session didFailWithError:(NSError *)error
{
    DDLogError(@"Session didFailWithError - %@", error);
    
    if ([self didFailSession])
    {
        [self didFailSession](error);
    }
}

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera
{
    DDLogDebug(@"Session cameraDidChangeTrackingState - %@", trackingState(camera));
    
    if ([self didChangeTrackingState])
    {
        [self didChangeTrackingState](trackingState(camera));
    }
    
    [[self controller] didChangeTrackingState:camera];
}

- (void)sessionWasInterrupted:(ARSession *)session
{
    DDLogError(@"Session WasInterrupted");
    
    if ([self didInterupt])
    {
        [self didInterupt](YES);
    }
}

- (void)sessionInterruptionEnded:(ARSession *)session
{
    DDLogError(@"Session InterruptionEnded");
    
    if ([self didInterupt])
    {
        [self didInterupt](NO);
    }
}

- (void)session:(ARSession *)session didOutputAudioSampleBuffer:(CMSampleBufferRef)audioSampleBuffer
{
    //DDLogDebug(@"Session didOutputAudioSampleBuffer");
}

@end

