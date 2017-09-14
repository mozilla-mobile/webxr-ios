#import <UIKit/UIKit.h>
#import "OverlayHeader.h"
#import "Animator.h"

typedef NS_ENUM(NSUInteger, RecordState);

@interface UIOverlayController : NSObject

@property (nonatomic, strong) Animator *animator;

- (instancetype)initWithRootView:(UIView *)rootView
                         atIndex:(NSUInteger)index
                    cameraAction:(HotAction)cameraAction
                       micAction:(HotAction)micAction
                      showAction:(HotAction)showAction
                     debugAction:(HotAction)debugAction;

- (void)setMode:(ShowMode)mode;
- (void)setOptions:(ShowOptions)options;
- (void)setRecordState:(RecordState)state;
- (void)setMicrophoneEnabled:(BOOL)microphoneEnabled;
- (void)setTrackingState:(NSString *)state;
- (void)setARKitInterruption:(BOOL)interruption;
- (void)viewWillTransitionToSize:(CGSize)size;

@end
