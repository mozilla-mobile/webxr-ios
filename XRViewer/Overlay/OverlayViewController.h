#import <UIKit/UIKit.h>
#import "OverlayHeader.h"
#import "RecordController.h"
#import "Animator.h"

@interface OverlayViewController : UIViewController

@property (nonatomic, strong) Animator *animator;

- (void)setUIStyle:(UIStyle)style;
- (void)setShowMode:(ShowMode)showMode withAnimationCompletion:(Completion)completion;
- (void)setShowOptions:(ShowOptions)showOptions withAnimationCompletion:(Completion)completion;
- (void)setRecordState:(RecordState)recordState withAnimationCompletion:(Completion)completion;
- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled withAnimationCompletion:(Completion)completion;;
- (void)setTrackingState:(NSString *)state withAnimationCompletion:(Completion)completion;

/***
 * Shows the warning message based on the tracking state, and whether the scene has planes or not
 * @param state The current AR tracking state string
 * @param completion
 * @param hasPlanes A boolean indicating whether there is any ARPlaneAnchor in the scene
 */
- (void)setTrackingState:(NSString *)state withAnimationCompletion:(Completion)completion sceneHasPlanes:(BOOL)hasPlanes;

@end
