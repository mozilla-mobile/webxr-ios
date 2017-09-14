#import <Foundation/Foundation.h>
#import "Animator.h"

typedef NS_ENUM(NSUInteger, RecordState)
{
    RecordStateIsReady,
    RecordStatePhoto,
    RecordStateGoingToRecording, // for preparing UI (JS) for capturing(important for first frame)
    RecordStateRecording,
    RecordStateRecordingWithMicrophone,
    RecordStatePreviewing,
    RecordStateDisabled, // by hardware
    RecordStateAuthDisabled, // by user
    RecordStateError
};

typedef void (^RecordAction)(RecordState);
typedef void (^RequestAuthAction)(id);

@interface RecordController : NSObject

@property (nonatomic, strong) Animator *animator;

@property(nonatomic, assign) BOOL showPreviewOnCompletion;

@property(nonatomic, copy) RequestAuthAction authAction;

- (instancetype)initWithAction:(RecordAction)action micEnabled:(BOOL)enabled;

- (BOOL)cameraAvailable;

- (void)requestAuthorizationWithCompletion:(RequestAuthAction)completionAction;

- (void)shotAction:(id)sender;
- (void)recordAction:(id)sender;
- (void)micAction:(id)sender;

- (BOOL)isRecording;
- (BOOL)microphoneEnabled;
- (void)stopRecordingByInterruption:(id)sender;

@end
