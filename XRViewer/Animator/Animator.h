#import <UIKit/UIKit.h>

#define DEFAULT_ANIMATION_DURATION .5

typedef void (^Completion)(BOOL);

@interface Animator : NSObject

@property(nonatomic) CGFloat animationDuration;

- (void)startPulseAnimation:(UIView *)view;
- (void)stopPulseAnimation:(UIView *)view;

- (void)animate:(UIView *)view toFrame:(CGRect)frame;
- (void)animate:(UIView *)view toFrame:(CGRect)frame completion:(Completion)completion;

- (void)animate:(UIView *)view toFade:(BOOL)fade;
- (void)animate:(UIView *)view toFade:(BOOL)fade completion:(Completion)completion;

- (void)animate:(UIView *)view toColor:(UIColor *)color;

- (void)clean;

@end
