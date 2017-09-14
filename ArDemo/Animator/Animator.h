#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AnimationType)
{
    AnimationFromTop,
    AnimationToTop,
    AnimationFromLeft,
    AnimationToLeft,
    AnimationFromRight,
    AnimationToRight,
    AnimationToRightH,
    AnimationFromBottom,
    AnimationToBottom
};

typedef void (^Completion)(BOOL);

@interface Animator : NSObject

@property(nonatomic) CGFloat animationDuration; // 0.5 by default

- (void)animateHidden:(UIView *)view
           onRootView:(UIView *)rootView
             withType:(AnimationType)type;

- (void)animateHidden:(UIView *)view
           onRootView:(UIView *)rootView
             withType:(AnimationType)type
 identityOnCompletion:(BOOL)identity;

- (void)animateHidden:(UIView *)view
           onRootView:(UIView *)rootView
             withType:(AnimationType)type
               offset:(CGFloat)offset;

- (void)animateHidden:(UIView *)view
           onRootView:(UIView *)rootView
             withType:(AnimationType)type
               offset:(CGFloat)offset
 identityOnCompletion:(BOOL)identity;

- (BOOL)isViewToRightAnimated:(UIView *)view;

- (void)startPulseAnimation:(UIView *)view;
- (void)stopPulseAnimation:(UIView *)view;

- (void)animate:(UIView *)view frame:(CGRect)frame;

- (void)animate:(UIView *)view toFade:(BOOL)fade;
- (void)animate:(UIView *)view toFade:(BOOL)fade completion:(Completion)completion;

@end

static inline NSString *typeString(AnimationType type)
{
    switch (type)
    {
        case AnimationFromTop:
            return @"AnimationFromTop";
        case AnimationToTop:
            return @"AnimationToTop";
        case AnimationFromLeft:
            return @"AnimationFromLeft";
        case AnimationFromRight:
            return @"AnimationFromRight";
        case AnimationToLeft:
            return @"AnimationToLeft";
        case AnimationToRightH:
            return @"AnimationToRightH";
        case AnimationToRight:
            return @"AnimationToRight";
        case AnimationFromBottom:
            return @"AnimationFromBottom";
        case AnimationToBottom:
            return @"AnimationToBottom";
    }
}
