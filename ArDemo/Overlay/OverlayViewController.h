#import <UIKit/UIKit.h>
#import "OverlayHeader.h"
#import "RecordController.h"
#import "Animator.h"

@interface OverlayViewController : UIViewController

@property (nonatomic, strong) Animator *animator;

- (void)setShowMode:(ShowMode)showMode withAnimationCompletion:(Completion)completion;
- (void)setShowOptions:(ShowOptions)showOptions withAnimationCompletion:(Completion)completion;
- (void)setRecordState:(RecordState)recordState withAnimationCompletion:(Completion)completion;
- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled withAnimationCompletion:(Completion)completion;;
- (void)setTrackingState:(NSString *)state withAnimationCompletion:(Completion)completion;

@end
