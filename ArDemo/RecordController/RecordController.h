#import <Foundation/Foundation.h>
#import "Animator.h"
#import "AppState.h"

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

- (void)setMicEnabled:(BOOL)enabled;

- (BOOL)isRecording;
- (BOOL)microphoneEnabled;
- (void)stopRecordingByInterruption:(id)sender;

@end
