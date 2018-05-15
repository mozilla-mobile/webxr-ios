#import "RecordController.h"
#import <ReplayKit/ReplayKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Endian.h"
#import <Photos/Photos.h>
#import "OverlayHeader.h"
#import "XRViewer-Swift.h"

#define USER_DECLINED_RECORD_CODE -5801

#define clamp(a) (a>255?255:(a<0?0:a));

// https://github.com/TUNER88/iOSSystemSoundsLibrary
#define CAMERA_SHUTTER_SOUND_ID  1108
#define BEGIN_RECORDING_SOUND_ID 1113
#define END_RECORDING_SOUND_ID   1114

@interface RecordController() <RPPreviewViewControllerDelegate, RPScreenRecorderDelegate, UIPopoverPresentationControllerDelegate>
{
    // to make photo not in the first capture frame becouse of some distruction
    int _frameToShot;
    int _shotCounter;
}

@property(nonatomic, copy) RecordAction action;
@property(nonatomic, strong) RPScreenRecorder *recorder;
@property(nonatomic, assign) BOOL microphoneEnabled;

@property BOOL photoCapturing;

@end

@implementation RecordController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]  removeObserver:self];
    
    DDLogDebug(@"RecordController dealloc");
}

- (instancetype)initWithAction:(RecordAction)action micEnabled:(BOOL)enabled
{
    self = [super init];
    
    if (self)
    {
        _frameToShot = 3;
        
        [self setAction:action];
        [self setRecorder:[RPScreenRecorder sharedRecorder]];
        [[self recorder] setDelegate:self];
        [self setShowPreviewOnCompletion:YES];
        [self setMicrophoneEnabled:enabled];
        
        [self setupState];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    
    return self;
}

- (void)didEnterBackground:(id)sender
{
    [self stopRecordingByInterruption:nil];
}

- (void)willEnterForeground:(id)sender
{
    [self setupState];
}

- (void)setupState
{
    [self setPhotoCapturing:NO];
    
    RecordState state;
    
    if ([self checkDeviceAvailable] == NO)
    {
        state = RecordStateDisabled;
    }
    else if ([self checkAuthAvailable] == NO)
    {
        state = RecordStateAuthDisabled;
    }
    else
    {
        state = RecordStateIsReady;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [self action](state);
                   });
}

- (BOOL)cameraAvailable
{
    return [self checkDeviceAvailable] && [self checkAuthAvailable];
}

- (BOOL)checkDeviceAvailable
{
    return [[self recorder] isAvailable];
}

- (BOOL)checkAuthAvailable
{
    return
    ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) &&
    ([PHPhotoLibrary authorizationStatus] == AVAuthorizationStatusAuthorized);
}

- (void)requestAuthorizationWithCompletion:(RequestAuthAction)completionAction
{
    __weak typeof (self) blockSelf = self;
    
    AVAuthorizationStatus avStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (avStatus == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                [blockSelf setupState];
                                
                                if (completionAction != NULL)
                                {
                                    completionAction(blockSelf);
                                }
                            });
         }];
    }
    else if (avStatus != AVAuthorizationStatusAuthorized)
    {
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           if (completionAction != NULL)
                           {
                               completionAction(blockSelf);
                           }
                           else
                           {
                               [self authAction](blockSelf);
                           }
                       });
    }
    
    PHAuthorizationStatus phStatus = [PHPhotoLibrary authorizationStatus];
    
    if (phStatus == PHAuthorizationStatusNotDetermined)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
         {
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                [blockSelf setupState];
                                
                                if (completionAction != NULL)
                                {
                                    completionAction(blockSelf);
                                }
                            });
         }];
    }
    else if (phStatus != PHAuthorizationStatusAuthorized)
    {
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           if (completionAction != NULL)
                           {
                               completionAction(blockSelf);
                           }
                           else
                           {
                               [self authAction](blockSelf);
                           }
                       });
    }
}

- (BOOL)isRecording
{
    return [[self recorder] isRecording];
}

- (void)stopRecordingByInterruption:(id)sender
{
    if ([self isRecording])
    {
        __weak typeof (self) blockSelf = self;
        
        if ([self photoCapturing])
        {
            [[self recorder] stopCaptureWithHandler:^(NSError * _Nullable error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    if ([error code] == USER_DECLINED_RECORD_CODE)
                                    {
                                        [self action](RecordStateIsReady);
                                    }
                                    else
                                    {
                                        [self action](RecordStateError);
                                    }
                                    
                                    [blockSelf setPhotoCapturing:NO];
                                    
                                    DDLogError(@"Error Recording by interruption !");
                                });
             }];
        }
        else
        {
            [[self recorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    if ([error code] == USER_DECLINED_RECORD_CODE)
                                    {
                                        [self action](RecordStateIsReady);
                                    }
                                    else
                                    {
                                        [self action](RecordStateError);
                                    }
                                    
                                    DDLogError(@"Error Recording by interruption !");
                                });
             }];
        }
    }
}

- (void)setMicEnabled:(BOOL)enabled
{
    if ([self checkAuthAvailable] == NO)
    {
        [self requestAuthorizationWithCompletion:NULL];
        return;
    }
    
    [self setMicrophoneEnabled:enabled];
}

- (void)shotAction:(id)sender
{
    if ([self checkAuthAvailable] == NO)
    {
        [self requestAuthorizationWithCompletion:NULL];
        return;
    }
    
    if ([[self recorder] isRecording])
    {
        return;
    }
    
    [self action](RecordStatePhoto);
    
    [[self recorder] setMicrophoneEnabled:NO];
    
    _shotCounter = 0;
    
    _photoCapturing = YES;
    
    __weak typeof (self) blockSelf = self;
    
    [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodTap object:EventObjectRecordPictureButton];
    [[self recorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error)
     {
         if ((++_shotCounter) == _frameToShot)
         {
             DDLogDebug(@"SHOT");
             
             UIImage *image = [blockSelf imageTFromSampleBuffer:sampleBuffer];
             [[blockSelf recorder] stopCaptureWithHandler:^(NSError * _Nullable error)
              {
                  dispatch_async(dispatch_get_main_queue(), ^
                                 {
                                     [blockSelf setPhotoCapturing:NO];
                                     
                                     if (image)
                                     {
                                         AudioServicesPlaySystemSound(CAMERA_SHUTTER_SOUND_ID);
                                         
                                         UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
                                     }
                                     else
                                     {
                                         [blockSelf action](RecordStateError);
                                         
                                         DDLogError(@"Error Shot Image !");
                                     }
                                 });
              }];
             
         }
     }
                           completionHandler:^(NSError * _Nullable error) {}];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       if (error)
                       {
                           [self action](RecordStateError);
                           DDLogError(@"Shot image saving with error - %@", error);
                       }
                       else
                       {
                           [self action](RecordStateIsReady);
                           DDLogInfo(@"Shot image saving with success");
                       }
                   });
}

- (void)recordAction:(id)sender
{
    if ([self checkAuthAvailable] == NO)
    {
        [self requestAuthorizationWithCompletion:NULL];
        return;
    }
    
    __weak typeof (self) blockSelf = self;
    
    if ([[self recorder] isRecording])
    {
        AudioServicesPlaySystemSound(END_RECORDING_SOUND_ID);
        
        [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodTap object:EventObjectReleaseVideoButton];
        [[self recorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error)
         {
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                if (error || !previewViewController)
                                {
                                    DDLogError(@"Error/preview - %@", error);
                                    [blockSelf action](RecordStateError);
                                }
                                else if ([blockSelf showPreviewOnCompletion])
                                {
                                    [blockSelf action](RecordStatePreviewing);
                                    
                                    [previewViewController setPreviewControllerDelegate:self];
                                    
                                    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                                    {
                                        UIPopoverPresentationController *pc = [previewViewController popoverPresentationController];
                                        
                                        [pc setDelegate:self];
                                        [pc setSourceView:[previewViewController view]];
                                        CGRect rect = recordFrameIn([[UIScreen mainScreen] bounds]);
                                        CGFloat statusBarInfluence = 20;
                                        rect.origin.x -= statusBarInfluence / 2;
                                        rect.origin.y -= statusBarInfluence / 2;
                                        [pc setSourceRect:rect];
                                    }
                                    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:previewViewController animated:YES completion:^
                                     {
                                         DDLogInfo(@"Stop Recording With Preview");
                                     }];
                                }
                                else
                                {
                                    [blockSelf action](RecordStateIsReady);
                                    DDLogInfo(@"Stop Recording Without Preview");
                                }
                            });
         }];
    }
    else
    {
        [[self recorder] setMicrophoneEnabled:[self microphoneEnabled]];
        
        [self action](RecordStateGoingToRecording);
        
        [[AnalyticsManager sharedInstance] sendEventWithCategory:EventCategoryAction method:EventMethodTap object:EventObjectRecordVideoButton];
        [[self recorder] startRecordingWithHandler:^(NSError * _Nullable error)
         {
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                if (error )
                                {
                                    if ([error code] == USER_DECLINED_RECORD_CODE)
                                    {
                                        [self action](RecordStateIsReady);
                                    }
                                    else
                                    {
                                        [self action](RecordStateError);
                                    }
                                    DDLogError(@"Start Error - %@", error);
                                }
                                else
                                {
                                    AudioServicesPlaySystemSound(BEGIN_RECORDING_SOUND_ID);
                                    
                                    [blockSelf setMicrophoneEnabled:[[blockSelf recorder] isMicrophoneEnabled]];
                                    
                                    if ([blockSelf microphoneEnabled])
                                    {
                                        [blockSelf action](RecordStateRecordingWithMicrophone);
                                        DDLogInfo(@"Start recording with microphone");
                                    }
                                    else
                                    {
                                        [blockSelf action](RecordStateRecording);
                                        DDLogInfo(@"Start recording");
                                    }
                                }
                            });
         }];
    }
}

- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithPreviewViewController:(nullable RPPreviewViewController *)previewViewController error:(nullable NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       if ([error code] == USER_DECLINED_RECORD_CODE)
                       {
                           [self action](RecordStateIsReady);
                       }
                       else
                       {
                           [self action](RecordStateError);
                       }
                       
                       DDLogError(@"Stop recording with error - %@", error);
                   });
}

- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder
{
    [self action](screenRecorder.available ? RecordStateIsReady : RecordStateDisabled);
    DDLogDebug(@"RPScreenRecorder - available - %d", screenRecorder.available);
}

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    DDLogDebug(@"RPPreviewViewController did Finish");
    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [previewController dismissViewControllerAnimated:YES completion:^
                        {
                            [self action](RecordStateIsReady);
                            DDLogInfo(@"Preview did Dissmiss");
                        }];
                   });
}

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    DDLogDebug(@"prepareForPopoverPresentation");
}

// https://stackoverflow.com/questions/13201084/how-to-convert-a-kcvpixelformattype-420ypcbcr8biplanarfullrange-buffer-to-uiimag
- (UIImage *)imageTFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *bufferInfo = (CVPlanarPixelBufferInfo_YCbCrBiPlanar *)baseAddress;
    uint8_t* cbrBuff = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    UIImage *image = [self makeUIImage:baseAddress cBCrBuffer:cbrBuff bufferInfo:bufferInfo width:width height:height bytesPerRow:bytesPerRow];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    return image;
}

- (UIImage *)makeUIImage:(uint8_t *)inBaseAddress cBCrBuffer:(uint8_t*)cbCrBuffer bufferInfo:(CVPlanarPixelBufferInfo_YCbCrBiPlanar *)inBufferInfo width:(size_t)inWidth height:(size_t)inHeight bytesPerRow:(size_t)inBytesPerRow
{
    NSUInteger yPitch = EndianU32_BtoN(inBufferInfo->componentInfoY.rowBytes);
    uint8_t *rgbBuffer = (uint8_t *)malloc(inWidth * inHeight * 4);
    NSUInteger cbCrPitch = EndianU32_BtoN(inBufferInfo->componentInfoCbCr.rowBytes);
    uint8_t *yBuffer = (uint8_t *)inBaseAddress;
    int bytesPerPixel = 4;
    
    for(int y = 0; y < inHeight; y++)
    {
        uint8_t *rgbBufferLine = &rgbBuffer[y * inWidth * bytesPerPixel];
        uint8_t *yBufferLine = &yBuffer[y * yPitch];
        uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
        
        for(int x = 0; x < inWidth; x++)
        {
            int16_t y = yBufferLine[x];
            int16_t cb = cbCrBufferLine[x & ~1] - 128;
            int16_t cr = cbCrBufferLine[x | 1] - 128;
            
            uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
            
            int16_t r = (int16_t)roundf( y + cr *  1.4 );
            int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
            int16_t b = (int16_t)roundf( y + cb *  1.765);
            
            //ABGR
            rgbOutput[0] = 0xff;
            rgbOutput[1] = clamp(b);
            rgbOutput[2] = clamp(g);
            rgbOutput[3] = clamp(r);
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbBuffer, inWidth, inHeight, 8,
                                                 inWidth*bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    CGImageRelease(quartzImage);
    free(rgbBuffer);
    
    return  image;
}

@end
