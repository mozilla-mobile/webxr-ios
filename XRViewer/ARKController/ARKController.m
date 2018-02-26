#import "ARKController.h"
#import <os/lock.h>
#import "WebARKHeader.h"
#import <AVFoundation/AVFoundation.h>
#import "ARKSceneKitController.h"
#import "ARKMetalController.h"
#import "HitAnchor.h"
#import "HitTestResult.h"
#import "Utils.h"
#import "XRViewer-Swift.h"
#import <Accelerate/Accelerate.h>

@interface ARKController () <ARSessionDelegate>
{
    NSDictionary *arkData;
    os_unfair_lock lock;
    NSMutableDictionary *objects; // key - JS anchor name : value - ARAnchor NSUUID string
    NSDictionary* computerVisionData;
}

@property (nonatomic, strong) id<ARKControllerProtocol> controller;

@property (nonatomic, copy) NSDictionary *request;
@property (nonatomic, strong) ARSession *session;

@property (nonatomic, strong) ARWorldTrackingConfiguration *configuration;

@property (nonatomic, strong) AVCaptureDevice *device;

@property(nonatomic) ShowMode showMode;
@property(nonatomic) ShowOptions showOptions;

@property vImage_Buffer lumaBuffer;
@property(nonatomic, strong) NSMutableData* lumaDataBuffer;
@property(nonatomic, strong) NSMutableString* lumaBase64StringBuffer;
@property vImage_Buffer chromaBuffer;
@property(nonatomic, strong) NSMutableData* chromaDataBuffer;
@property(nonatomic, strong) NSMutableString* chromaBase64StringBuffer;

@end

@implementation ARKController {
    /// Array of anchor dictionaries that were added since the last frame.
    /// Contains the initial data of the anchor when it was added.
    NSMutableArray *addedAnchorsSinceLastFrame;

    /// Array of anchor IDs that were removed since the last frame
    NSMutableArray *removedAnchorsSinceLastFrame;
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
        lock = OS_UNFAIR_LOCK_INIT;
        objects = [NSMutableDictionary new];
        addedAnchorsSinceLastFrame = [NSMutableArray new];
        removedAnchorsSinceLastFrame = [NSMutableArray new];
        [self setShouldUpdateWindowSize:YES];

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
        [[self configuration] setWorldAlignment:ARWorldAlignmentGravityAndHeading];
        
        Class cls = (type == ARKMetal) ? [ARKMetalController class] : [ARKSceneKitController class];
        id<ARKControllerProtocol> controller = [[cls alloc] initWithSesion:[self session] size:[rootView bounds].size];
        [self setController:controller];
        [rootView addSubview:[controller renderView]];
        [[controller renderView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[[[controller renderView] topAnchor] constraintEqualToAnchor:[rootView topAnchor]] setActive:YES];
        [[[[controller renderView] leftAnchor] constraintEqualToAnchor:[rootView leftAnchor]] setActive:YES];
        [[[[controller renderView] rightAnchor] constraintEqualToAnchor:[rootView rightAnchor]] setActive:YES];
        [[[[controller renderView] bottomAnchor] constraintEqualToAnchor:[rootView bottomAnchor]] setActive:YES];
        
        [[self controller] setHitTestFocusPoint:[[[self controller] renderView] center]];

        self.interfaceOrientation = [Utils getInterfaceOrientationFromDeviceOrientation];
        
        self.lumaDataBuffer = nil;
        self.lumaBase64StringBuffer = nil;
        self.chromaDataBuffer = nil;
        self.chromaBase64StringBuffer = nil;
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
    self.interfaceOrientation = [Utils getInterfaceOrientationFromDeviceOrientation];
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

- (NSDictionary*)computerVisionData {
    NSDictionary* data;
    
    os_unfair_lock_lock(&(lock));
    data = computerVisionData;
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
    if ((name == nil) || [objects objectForKey:name])
    {
        DDLogError(@"Duplicate or NIL anchor Name - %@", name);
        return NO;
    }
    
    matrix_float4x4 matrix = [transform isKindOfClass:[NSArray class]] ? matrixFromArray(transform) : matrixFromDictionary((NSDictionary *)transform);
    
    ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:matrix];
    
    [[self session] addAnchor:anchor];
    [objects setObject:[[anchor identifier] UUIDString] forKey:name];
    
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
        
        [objects removeAllObjects];
    }
    else
    {
        for (NSString *name in anchorNames)
        {
            NSString *uuid = objects[name];
            
            for (ARAnchor *anchor in [currentFrame anchors])
            {
                if ([[[anchor identifier] UUIDString] isEqualToString:uuid])
                {
                    [[self session] removeAnchor:anchor];
                    [objects removeObjectForKey:uuid];
                    
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
                CGSize size = [[self controller] renderView].frame.size;
                matrix_float4x4 projectionMatrix = [[frame camera] projectionMatrixForOrientation:self.interfaceOrientation
                                                                               viewportSize:size
                                                                                      zNear:AR_CAMERA_PROJECTION_MATRIX_Z_NEAR
                                                                                       zFar:AR_CAMERA_PROJECTION_MATRIX_Z_FAR];
                newData[WEB_AR_PROJ_CAMERA_OPTION] = arrayFromMatrix4x4(projectionMatrix);
             
                matrix_float4x4 viewMatrix = [frame.camera viewMatrixForOrientation:self.interfaceOrientation];
                matrix_float4x4 modelMatrix = matrix_invert(viewMatrix);
                
                newData[WEB_AR_CAMERA_TRANSFORM_OPTION] = arrayFromMatrix4x4(modelMatrix);
                newData[WEB_AR_CAMERA_VIEW_OPTION] = arrayFromMatrix4x4(viewMatrix);
            }
            if ([[self request][WEB_AR_3D_OBJECTS_OPTION] boolValue])
            {
                newData[WEB_AR_3D_OBJECTS_OPTION] = [self currentAnchorsArray];
                
                // Prepare the objectsRemoved array
                NSArray *removedObjects = [removedAnchorsSinceLastFrame copy];
                [removedAnchorsSinceLastFrame removeAllObjects];
                newData[WEB_AR_3D_REMOVED_OBJECTS_OPTION] = removedObjects;
                
                // Prepare the newObjects array
                NSArray *newObjects = [addedAnchorsSinceLastFrame copy];
                [addedAnchorsSinceLastFrame removeAllObjects];
                newData[WEB_AR_3D_NEW_OBJECTS_OPTION] = newObjects;
            }
            if (/*[[self request][WEB_AR_CV_INFORMATION_OPTION] boolValue]*/true)
            {
                NSMutableDictionary *cvInformation = [NSMutableDictionary new];
                NSMutableDictionary *frameInformation = [NSMutableDictionary new];
                frameInformation[@"size"] = @{
                                              @"width": @(320),
                                              @"height": @(180)
                                              };
                NSInteger timestamp = [frame timestamp];
                frameInformation[@"timestamp"] = @(timestamp);
                
                // TODO: prepare depth data
                frameInformation[@"capturedDepthData"] = nil;
                frameInformation[@"capturedDepthDataTimestamp"] = nil;
                
                // Computer vision data
                [self updateBase64BuffersFromPixelBuffer:frame.capturedImage];
                
                frameInformation[@"images"] = @[self.lumaBase64StringBuffer, self.chromaBase64StringBuffer];
                frameInformation[@"pixelFormatType"] = [self stringForOSType:CVPixelBufferGetPixelFormatType(frame.capturedImage)];
                
                NSMutableDictionary *cameraInformation = [NSMutableDictionary new];
                CGSize cameraImageResolution = [[frame camera] imageResolution];
                cameraInformation[@"cameraImageResolution"] = @{
                                                                @"width": @(cameraImageResolution.width),
                                                                @"height": @(cameraImageResolution.height)
                                                                };
                
                // Get the projection matrix
                CGSize viewportSize = [[self controller] renderView].frame.size;
                matrix_float4x4 projectionMatrix = [[frame camera] projectionMatrixForOrientation:self.interfaceOrientation
                                                                                     viewportSize:viewportSize
                                                                                            zNear:AR_CAMERA_PROJECTION_MATRIX_Z_NEAR
                                                                                             zFar:AR_CAMERA_PROJECTION_MATRIX_Z_FAR];
                cameraInformation[@"projectionMatrix"] = arrayFromMatrix4x4(projectionMatrix);
                
                // Get the view matrix
                matrix_float4x4 viewMatrix = [frame.camera viewMatrixForOrientation:self.interfaceOrientation];
                cameraInformation[@"viewMatrix"] = arrayFromMatrix4x4(viewMatrix);
                
                
                // Send also the interface orientation
                cameraInformation[@"interfaceOrientation"] = @(self.interfaceOrientation);
                
                cvInformation[@"frame"] = frameInformation;
                cvInformation[@"camera"] = cameraInformation;
                
                os_unfair_lock_lock(&(lock));
                computerVisionData = [cvInformation copy];
                os_unfair_lock_unlock(&(lock));
            }
            
            os_unfair_lock_lock(&(lock));
            arkData = [newData copy];
            os_unfair_lock_unlock(&(lock));
        }
    }
}

-(void)logPixelBufferInfo:(CVPixelBufferRef)capturedImagePixelBuffer {
    size_t capturedImagePixelBufferWidth = CVPixelBufferGetWidth(capturedImagePixelBuffer);
    size_t capturedImagePixelBufferHeight = CVPixelBufferGetHeight(capturedImagePixelBuffer);
    size_t capturedImagePixelBufferBytesPerRow = CVPixelBufferGetBytesPerRow(capturedImagePixelBuffer);
    size_t capturedImageNumberOfPlanes = CVPixelBufferGetPlaneCount(capturedImagePixelBuffer);
    CFTypeID capturedImagePixelBufferTypeID = CVPixelBufferGetTypeID();
    size_t capturedImagePixelBufferDataSize = CVPixelBufferGetDataSize(capturedImagePixelBuffer);
    OSType capturedImagePixelBufferPixelFormatType = CVPixelBufferGetPixelFormatType(capturedImagePixelBuffer);
    void* capturedImagePixelBufferBaseAddress = CVPixelBufferGetBaseAddress(capturedImagePixelBuffer);

    NSLog(@"\n\nnumberOfPlanes: %zu\npixelBufferWidth: %zu\npixelBufferHeight: %zu\npixelBufferTypeID: %lu\npixelBufferDataSize: %zu\npixelBufferBytesPerRow: %zu\npixelBufferPIxelFormatType: %@\npixelBufferBaseAddress: %p\n",
          capturedImageNumberOfPlanes,
          capturedImagePixelBufferWidth,
          capturedImagePixelBufferHeight,
          capturedImagePixelBufferTypeID,
          capturedImagePixelBufferDataSize,
          capturedImagePixelBufferBytesPerRow,
          [self stringForOSType:capturedImagePixelBufferPixelFormatType],
          capturedImagePixelBufferBaseAddress);
}

-(void)updateBase64BuffersFromPixelBuffer:(CVPixelBufferRef)capturedImagePixelBuffer {

    //[self logPixelBufferInfo:capturedImagePixelBuffer];

    vImagePixelCount targetWidth = 320;
    vImagePixelCount targetHeight = 180;
    
    // Luma
    CVPixelBufferLockBaseAddress(capturedImagePixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    vImage_Buffer lumaSrcBuffer;
    lumaSrcBuffer.data = CVPixelBufferGetBaseAddressOfPlane(capturedImagePixelBuffer, 0);
    lumaSrcBuffer.width = CVPixelBufferGetWidthOfPlane(capturedImagePixelBuffer, 0);
    lumaSrcBuffer.height = CVPixelBufferGetHeightOfPlane(capturedImagePixelBuffer, 0);
    lumaSrcBuffer.rowBytes = CVPixelBufferGetBytesPerRowOfPlane(capturedImagePixelBuffer, 0);
    
    if (self.lumaBuffer.data == nil) {
        vImageBuffer_Init(&self->_lumaBuffer, targetHeight, targetWidth, 8 * sizeof(Pixel_8), kvImageNoFlags);
    }

    vImage_Error scaleError = vImageScale_Planar8(&lumaSrcBuffer, &self->_lumaBuffer, NULL, kvImageNoFlags);
    if (scaleError != 0) {
        NSLog(@"Error scaling luma image");
        CVPixelBufferUnlockBaseAddress(capturedImagePixelBuffer, kCVPixelBufferLock_ReadOnly);
        return;
    }
    
    if (self.lumaDataBuffer == nil) {
        self.lumaDataBuffer = [NSMutableData dataWithBytes:self.lumaBuffer.data length:self.lumaBuffer.rowBytes * self.lumaBuffer.height];
    }
    [self.lumaDataBuffer setData:[NSData dataWithBytes:self.lumaBuffer.data length:self.lumaBuffer.rowBytes * self.lumaBuffer.height]];
    
    if (self.lumaBase64StringBuffer == nil) {
        self.lumaBase64StringBuffer = [NSMutableString new];
    }
    [self.lumaBase64StringBuffer setString:[self.lumaDataBuffer base64EncodedStringWithOptions:0]];
    

    // Chroma
    vImage_Buffer chromaSrcBuffer;
    chromaSrcBuffer.data = CVPixelBufferGetBaseAddressOfPlane(capturedImagePixelBuffer, 1);
    chromaSrcBuffer.width = CVPixelBufferGetWidthOfPlane(capturedImagePixelBuffer, 1);
    chromaSrcBuffer.height = CVPixelBufferGetHeightOfPlane(capturedImagePixelBuffer, 1);
    chromaSrcBuffer.rowBytes = CVPixelBufferGetBytesPerRowOfPlane(capturedImagePixelBuffer, 1);
    
    if (self->_chromaBuffer.data == nil) {
        vImageBuffer_Init(&self->_chromaBuffer, targetHeight / 2, targetWidth / 2, 8 * sizeof(Pixel_16U), kvImageNoFlags);
    }

    scaleError = vImageScale_CbCr8(&chromaSrcBuffer, &self->_chromaBuffer, NULL, kvImageNoFlags);
    if (scaleError != 0) {
        NSLog(@"Error scaling chroma image");
        CVPixelBufferUnlockBaseAddress(capturedImagePixelBuffer, kCVPixelBufferLock_ReadOnly);
        return;
    }

    if (self.chromaDataBuffer == nil) {
        self.chromaDataBuffer = [NSMutableData dataWithBytes:self.chromaBuffer.data length:self.chromaBuffer.rowBytes * self.chromaBuffer.height];
    }
    [self.chromaDataBuffer setData:[NSData dataWithBytes:self.chromaBuffer.data length:self.chromaBuffer.rowBytes * self.chromaBuffer.height]];

    if (self.chromaBase64StringBuffer == nil) {
        self.chromaBase64StringBuffer = [NSMutableString new];
    }
    [self.chromaBase64StringBuffer setString:[self.chromaDataBuffer base64EncodedStringWithOptions:0]];
    
    CVPixelBufferUnlockBaseAddress(capturedImagePixelBuffer, kCVPixelBufferLock_ReadOnly);
}

- (NSString *)stringForOSType:(OSType)type {
    switch (type) {
        case kCVPixelFormatType_1Monochrome:                   return @"kCVPixelFormatType_1Monochrome";
        case kCVPixelFormatType_2Indexed:                      return @"kCVPixelFormatType_2Indexed";
        case kCVPixelFormatType_4Indexed:                      return @"kCVPixelFormatType_4Indexed";
        case kCVPixelFormatType_8Indexed:                      return @"kCVPixelFormatType_8Indexed";
        case kCVPixelFormatType_1IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_1IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_2IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_2IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_4IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_4IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_8IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_8IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_16BE555:                       return @"kCVPixelFormatType_16BE555";
        case kCVPixelFormatType_16LE555:                       return @"kCVPixelFormatType_16LE555";
        case kCVPixelFormatType_16LE5551:                      return @"kCVPixelFormatType_16LE5551";
        case kCVPixelFormatType_16BE565:                       return @"kCVPixelFormatType_16BE565";
        case kCVPixelFormatType_16LE565:                       return @"kCVPixelFormatType_16LE565";
        case kCVPixelFormatType_24RGB:                         return @"kCVPixelFormatType_24RGB";
        case kCVPixelFormatType_24BGR:                         return @"kCVPixelFormatType_24BGR";
        case kCVPixelFormatType_32ARGB:                        return @"kCVPixelFormatType_32ARGB";
        case kCVPixelFormatType_32BGRA:                        return @"kCVPixelFormatType_32BGRA";
        case kCVPixelFormatType_32ABGR:                        return @"kCVPixelFormatType_32ABGR";
        case kCVPixelFormatType_32RGBA:                        return @"kCVPixelFormatType_32RGBA";
        case kCVPixelFormatType_64ARGB:                        return @"kCVPixelFormatType_64ARGB";
        case kCVPixelFormatType_48RGB:                         return @"kCVPixelFormatType_48RGB";
        case kCVPixelFormatType_32AlphaGray:                   return @"kCVPixelFormatType_32AlphaGray";
        case kCVPixelFormatType_16Gray:                        return @"kCVPixelFormatType_16Gray";
        case kCVPixelFormatType_30RGB:                         return @"kCVPixelFormatType_30RGB";
        case kCVPixelFormatType_422YpCbCr8:                    return @"kCVPixelFormatType_422YpCbCr8";
        case kCVPixelFormatType_4444YpCbCrA8:                  return @"kCVPixelFormatType_4444YpCbCrA8";
        case kCVPixelFormatType_4444YpCbCrA8R:                 return @"kCVPixelFormatType_4444YpCbCrA8R";
        case kCVPixelFormatType_4444AYpCbCr8:                  return @"kCVPixelFormatType_4444AYpCbCr8";
        case kCVPixelFormatType_4444AYpCbCr16:                 return @"kCVPixelFormatType_4444AYpCbCr16";
        case kCVPixelFormatType_444YpCbCr8:                    return @"kCVPixelFormatType_444YpCbCr8";
        case kCVPixelFormatType_422YpCbCr16:                   return @"kCVPixelFormatType_422YpCbCr16";
        case kCVPixelFormatType_422YpCbCr10:                   return @"kCVPixelFormatType_422YpCbCr10";
        case kCVPixelFormatType_444YpCbCr10:                   return @"kCVPixelFormatType_444YpCbCr10";
        case kCVPixelFormatType_420YpCbCr8Planar:              return @"kCVPixelFormatType_420YpCbCr8Planar";
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:     return @"kCVPixelFormatType_420YpCbCr8PlanarFullRange";
        case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:        return @"kCVPixelFormatType_422YpCbCr_4A_8BiPlanar";
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  return @"kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange";
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:   return @"kCVPixelFormatType_420YpCbCr8BiPlanarFullRange";
        case kCVPixelFormatType_422YpCbCr8_yuvs:               return @"kCVPixelFormatType_422YpCbCr8_yuvs";
        case kCVPixelFormatType_422YpCbCr8FullRange:           return @"kCVPixelFormatType_422YpCbCr8FullRange";
        case kCVPixelFormatType_OneComponent8:                 return @"kCVPixelFormatType_OneComponent8";
        case kCVPixelFormatType_TwoComponent8:                 return @"kCVPixelFormatType_TwoComponent8";
        case kCVPixelFormatType_30RGBLEPackedWideGamut:        return @"kCVPixelFormatType_30RGBLEPackedWideGamut";
        case kCVPixelFormatType_OneComponent16Half:            return @"kCVPixelFormatType_OneComponent16Half";
        case kCVPixelFormatType_OneComponent32Float:           return @"kCVPixelFormatType_OneComponent32Float";
        case kCVPixelFormatType_TwoComponent16Half:            return @"kCVPixelFormatType_TwoComponent16Half";
        case kCVPixelFormatType_TwoComponent32Float:           return @"kCVPixelFormatType_TwoComponent32Float";
        case kCVPixelFormatType_64RGBAHalf:                    return @"kCVPixelFormatType_64RGBAHalf";
        case kCVPixelFormatType_128RGBAFloat:                  return @"kCVPixelFormatType_128RGBAFloat";
        case kCVPixelFormatType_14Bayer_GRBG:                  return @"kCVPixelFormatType_14Bayer_GRBG";
        case kCVPixelFormatType_14Bayer_RGGB:                  return @"kCVPixelFormatType_14Bayer_RGGB";
        case kCVPixelFormatType_14Bayer_BGGR:                  return @"kCVPixelFormatType_14Bayer_BGGR";
        case kCVPixelFormatType_14Bayer_GBRG:                  return @"kCVPixelFormatType_14Bayer_GBRG";
        default: return @"UNKNOWN";
    }
}

- (NSArray *)currentAnchorsArray
{
    NSMutableArray *array = [NSMutableArray array];
    [objects enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop)
     {
         [array addObject:objects[key]];
     }];
    
    return [array copy];
}

- (NSDictionary *)anchorDictFromAnchor:(ARAnchor *)anchor withName:(NSString *)name
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    dict[WEB_AR_UUID_OPTION] = name;
    dict[WEB_AR_TRANSFORM_OPTION] = arrayFromMatrix4x4([anchor transform]);

    if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
        ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
        [self addPlaneAnchorData:planeAnchor toDictionary:dict];
    }
    
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

- (NSString *)trackingState {
    return trackingState([[[self session] currentFrame] camera]);
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

    if ([self shouldUpdateWindowSize]) {
        [self setShouldUpdateWindowSize:NO];
        if ([self didUpdateWindowSize]) {
            [self didUpdateWindowSize]();
        }
    }
}

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor*>*)anchors
{
    DDLogDebug(@"Add Anchors - %@", [anchors debugDescription]);
    for (ARAnchor* addedAnchor in anchors) {
        NSDictionary *addedAnchorDictionary = [self getDictionaryForAnchor:addedAnchor];
        [addedAnchorsSinceLastFrame addObject: addedAnchorDictionary];
        objects[[addedAnchor.identifier UUIDString]] = addedAnchorDictionary;
    }

    // Inform up in the calling hierarchy when we have plane anchors added to the scene
    if ([self didAddPlaneAnchors]) {
        if ([self anyPlaneAnchor:anchors]) {
            [self didAddPlaneAnchors]();
        }
    }
}

- (NSDictionary *)getDictionaryForAnchor:(ARAnchor *)addedAnchor {
    NSMutableDictionary *addedAnchorDictionary = [[self anchorDictFromAnchor:addedAnchor withName:[addedAnchor.identifier UUIDString]] mutableCopy];
    if ([addedAnchor isKindOfClass:[ARPlaneAnchor class]]) {
        ARPlaneAnchor *addedPlaneAnchor = (ARPlaneAnchor *)addedAnchor;
        [self addPlaneAnchorData:addedPlaneAnchor toDictionary: addedAnchorDictionary];
    }
    return [addedAnchorDictionary copy];
}

- (void)addPlaneAnchorData:(ARPlaneAnchor *)planeAnchor toDictionary:(NSMutableDictionary *)dictionary {
    dictionary[WEB_AR_H_PLANE_CENTER_OPTION] = dictFromVector3([planeAnchor center]);
    dictionary[WEB_AR_H_PLANE_EXTENT_OPTION] = dictFromVector3([planeAnchor extent]);
    dictionary[WEB_AR_H_PLANE_ALIGNMENT_OPTION] = @([planeAnchor alignment]);
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor*>*)anchors
{
    DDLogDebug(@"Update Anchors - %@", [anchors debugDescription]);
    for (ARAnchor* updatedAnchor in anchors) {
        NSString* anchorID = [updatedAnchor.identifier UUIDString];
        NSDictionary *updatedAnchorDictionary = [self getDictionaryForAnchor:updatedAnchor];
        objects[anchorID] = updatedAnchorDictionary;
    }
}

- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor*>*)anchors
{
    DDLogDebug(@"Remove Anchors - %@", [anchors debugDescription]);
    for (ARAnchor* removedAnchor in anchors) {
        NSString* anchorID = [removedAnchor.identifier UUIDString];
        [removedAnchorsSinceLastFrame addObject: anchorID];
        objects[anchorID] = nil;
    }

    // Inform up in the calling hierarchy when we have plane anchors removed from the scene
    if ([self didRemovePlaneAnchors]) {
        if ([self anyPlaneAnchor:anchors]) {
            [self didRemovePlaneAnchors]();
        }
    }
}

- (BOOL)anyPlaneAnchor:(NSArray<ARAnchor *> *)anchorArray {
    BOOL anyPlaneAnchor = NO;
    for (ARAnchor *anchor in anchorArray) {
        if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
            anyPlaneAnchor = YES;
            break;
        }
    }
    return anyPlaneAnchor;
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

