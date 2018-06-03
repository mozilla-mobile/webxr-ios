#import "Animator.h"
#import <pop/POP.h>

#define ANIMATION_PULSE_KEY @"pulse"
#define ANIMATION_FRAME_KEY @"frame"
#define ANIMATION_COLOR_KEY @"color"

@interface AnimationDelegate : NSObject<CAAnimationDelegate>
@property(nonatomic, copy) Completion completion;
@end

@interface Animator () <CAAnimationDelegate>
@property(nonatomic, strong) NSMutableArray *animationCompletions;
@end

@implementation Animator

- (void)dealloc
{
    DDLogDebug(@"Animator dealloc");
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setAnimationCompletions:[NSMutableArray new]];
        [self setAnimationDuration:DEFAULT_ANIMATION_DURATION];
    }
    
    return self;
}

- (void)clean
{
    [[self animationCompletions] removeAllObjects];
    [[[UIApplication sharedApplication] keyWindow] pop_removeAllAnimations];
    [[[[UIApplication sharedApplication] keyWindow] layer] pop_removeAllAnimations];
    [[[[UIApplication sharedApplication] keyWindow] layer] removeAllAnimations];
}

- (void)startPulseAnimation:(UIView *)view
{
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    anim.toValue = @(CGPointMake(1.1, 1.1));
    anim.fromValue = @(CGPointMake(0.9 , 0.9));
    anim.repeatForever = YES;
    anim.autoreverses = YES;
    
    [view pop_addAnimation:anim forKey:ANIMATION_PULSE_KEY];
}

- (void)stopPulseAnimation:(UIView *)view
{
    [view pop_removeAnimationForKey:ANIMATION_PULSE_KEY];
}

- (void)animate:(UIView *)view toFrame:(CGRect)frame
{
    [self animate:view toFrame:frame completion:NULL];
}

- (void)animate:(UIView *)view toFrame:(CGRect)frame completion:(Completion)completion
{
    if (CGRectEqualToRect(frame, [view frame]))
    {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               completion(NO);
                           });
        }
        
        return;
    }
    
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    anim.toValue = @(frame);
    anim.fromValue = @([view frame]);
    [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
     {
         [view setFrame:frame];
         
         if (completion)
         {
             completion(finished);
         }
     }];
    
    [view pop_addAnimation:anim forKey:ANIMATION_FRAME_KEY];
}

- (void)animate:(UIView *)view toFade:(BOOL)fade
{
    [self animate:view toFade:fade completion:NULL];
}

- (void)animate:(UIView *)view toFade:(BOOL)fade completion:(Completion)completion
{
    CGFloat newOpacity = fade? 0 : 1;
    
    if ([[view layer] opacity] == newOpacity)
    {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               completion(NO);
                           });
        }
        
        return;
    }
    
    [[view layer] setOpacity:newOpacity];
    
    NSString *key = [NSString stringWithFormat:@"FADE-%@", view];
    [[view layer] removeAnimationForKey:key];
    
    CATransition *transition = [CATransition animation];
    [transition setDuration:[self animationDuration]];
    [transition setType:kCATransitionFade];
    
    AnimationDelegate *ad = [AnimationDelegate new];
    __weak AnimationDelegate *blockAd = ad;
    __weak Animator *blockSelf = self;
    
    [ad setCompletion:^(BOOL f)
     {
         if (completion)
         {
             completion(f);
         }
         
         [[blockSelf animationCompletions] removeObject:blockAd];
     }];
    
    [transition setDelegate:ad];
    [[self animationCompletions] addObject:ad];
    
    [[view layer] addAnimation:transition forKey:key];
}

- (void)animate:(UIView *)view toColor:(UIColor *)color
{
    if ( [view backgroundColor] == color )
    {
        return;
    }
    
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPViewBackgroundColor];
    anim.toValue = color;
    anim.fromValue = [view backgroundColor];
    [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
     {
         [view setBackgroundColor:color];
     }];
    
    [view pop_addAnimation:anim forKey:ANIMATION_COLOR_KEY];
}

@end



@implementation AnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([self completion])
    {
        [self completion](flag);
    }
}
@end

