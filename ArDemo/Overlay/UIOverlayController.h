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

- (void)setTrackingState:(NSString *)state;
- (void)setARKitInterruption:(BOOL)interruption;

@end
