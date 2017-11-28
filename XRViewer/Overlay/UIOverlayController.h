#import <UIKit/UIKit.h>
#import "OverlayHeader.h"
#import "Animator.h"
#import "AppState.h"

typedef NS_ENUM(NSUInteger, RecordState);

@interface UIOverlayController : NSObject

@property (nonatomic, strong) Animator *animator;

- (instancetype)initWithRootView:(UIView *)rootView
                    cameraAction:(HotAction)cameraAction
                       micAction:(HotAction)micAction
                      showAction:(HotAction)showAction
                     debugAction:(HotAction)debugAction;

- (void)clean;
- (void)viewWillTransitionToSize:(CGSize)size;
- (UIView *)hotView;

- (void)setMode:(ShowMode)mode;
- (void)setOptions:(ShowOptions)options;
- (void)setRecordState:(RecordState)state;
- (void)setMicEnabled:(BOOL)microphoneEnabled;

/***
 * Informs the overlay view controller about a tracking state change
 * @param state The AR tracking state string
 * @param hasPlanes A boolean indicating whether there are any planes in the scene
 */
- (void)setTrackingState:(NSString *)state sceneHasPlanes:(BOOL)planes;
- (void)setARKitInterruption:(BOOL)interruption;

@end
