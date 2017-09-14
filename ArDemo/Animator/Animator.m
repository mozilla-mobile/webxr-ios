#import "Animator.h"
#import <pop/POP.h>

#define TRANSLATION_KOEF 2

#define ANIMATION_POSITION_KEY @"position"
#define ANIMATION_TO_RIGHT_POSITION_KEY @"toRightPosition"
#define ANIMATION_PULSE_KEY @"pulse"

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
        [self setAnimationDuration:.5];
    }
    
    return self;
}

- (void)animateHidden:(UIView *)view onRootView:(UIView *)rootView withType:(AnimationType)type
{
    BOOL width;
    
    switch (type)
    {
        case AnimationFromTop:
        case AnimationToTop:
        case AnimationFromBottom:
        case AnimationToBottom:
            width = NO;
            break;
            
        default:
            width = YES;
            break;
    }
    
    [self animateHidden:view
             onRootView:rootView
               withType:type
                 offset:[self offsetView:view forType:type]];
}

- (CGFloat)offsetView:(UIView *)view forType:(AnimationType)type
{
    BOOL width;
    
    switch (type)
    {
        case AnimationFromTop:
        case AnimationToTop:
        case AnimationFromBottom:
        case AnimationToBottom:
            width = NO;
            break;
            
        default:
            width = YES;
            break;
    }
    
    return width ? [view bounds].size.width * TRANSLATION_KOEF : [view bounds].size.height * TRANSLATION_KOEF;
}

- (void)animateHidden:(UIView *)view onRootView:(UIView *)rootView withType:(AnimationType)type identityOnCompletion:(BOOL)identity
{
    [self animateHidden:view
             onRootView:rootView
               withType:type
                 offset:[self offsetView:view forType:type]
   identityOnCompletion:identity];
}

- (void)animateHidden:(UIView *)view onRootView:(UIView *)rootView withType:(AnimationType)type offset:(CGFloat)offset
{
    [self animateHidden:view
             onRootView:rootView
               withType:type
                 offset:offset
   identityOnCompletion:YES];
}

- (void)animateHidden:(UIView *)view
           onRootView:(UIView *)rootView
             withType:(AnimationType)type
               offset:(CGFloat)offset
 identityOnCompletion:(BOOL)identity
{
    [[view layer] removeAllAnimations];
    [[view layer] pop_removeAllAnimations];
    
    CATransform3D completionTransform = identity ? CATransform3DIdentity : [[view layer] transform];
    
    POPSpringAnimation *anim;
    
    [[view layer] setTransform:completionTransform];
    
    switch (type)
    {
        case AnimationFromTop:
        {
            if ([view isHidden])
            {
                [view setHidden:NO];
                
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
                anim.fromValue = @(0 - offset);
                anim.toValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [[view layer] setTransform:completionTransform];
                 }];
            }
            break;
        }
        case AnimationToTop:
        {
            if ([view isHidden] == NO)
            {
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
                anim.toValue = @(0 - offset);
                anim.fromValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [[view layer] setTransform:completionTransform];
                     [view setHidden:YES];
                 }];
            }
            break;
        }
        case AnimationFromBottom:
        {
            if ([view isHidden])
            {
                [view setHidden:NO];
                
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
                anim.fromValue = @(offset);
                anim.toValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [[view layer] setTransform:completionTransform];
                 }];
            }
            break;
        }
        case AnimationToBottom:
        {
            if ([view isHidden] == NO)
            {
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
                anim.toValue = @(offset);
                anim.fromValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [view setHidden:YES];
                     [[view layer] setTransform:completionTransform];
                 }];
            }
            break;
        }
        case AnimationFromLeft:
        {
            if ([view isHidden])
            {
                [view setHidden:NO];
                
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationX];
                anim.fromValue = @(0 - offset);
                anim.toValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [[view layer] setTransform:completionTransform];
                 }];
            }
            break;
        }
        case AnimationToLeft:
        {
            if ([view isHidden] == NO)
            {
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationX];
                anim.toValue = @(offset);
                anim.fromValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [view setHidden:YES];
                     [[view layer] setTransform:completionTransform];
                 }];
            }
            break;
        }
        case AnimationFromRight:
        {
            if ([view isHidden])
            {
                [view setHidden:NO];
                
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationX];
                anim.fromValue = @(offset);
                anim.toValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [[view layer] setTransform:completionTransform];
                 }];
            }
            break;
        }
        case AnimationToRightH:
        {
            if ([view isHidden] == NO)
            {
                [view setHidden:NO];
                
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationX];
                anim.toValue = @(offset);
                anim.fromValue = @(0);
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [view setHidden:YES];
                     [[view layer] setTransform:completionTransform];
                 }];
            }
            break;
        }
        case AnimationToRight:
        {
            if ([view isHidden] == NO)
            {
                anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationXY];
                anim.toValue = @(CGPointMake(offset, 0));
                anim.fromValue = @(CGPointMake(0 , 0));
                [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished)
                 {
                     [view setHidden:YES];
                     [[view layer] setTransform:completionTransform];
                 }];
                
                anim.removedOnCompletion = YES;
                [[view layer] pop_addAnimation:anim forKey:ANIMATION_TO_RIGHT_POSITION_KEY];
                
                return;
            }
            break;
        }
    }
    anim.removedOnCompletion = YES;
    [[view layer] pop_addAnimation:anim forKey:typeString(type)];
        
    //});
}

- (BOOL)isViewToRightAnimated:(UIView *)view
{
    return [[[view layer] pop_animationKeys] containsObject:ANIMATION_TO_RIGHT_POSITION_KEY];
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

- (void)animate:(UIView *)view frame:(CGRect)frame
{
    [UIView animateWithDuration:[self animationDuration]
                     animations:^
     {
         [view setFrame:frame];
     }
                     completion:^(BOOL finished)
     {}];
}

- (void)animate:(UIView *)view toFade:(BOOL)fade
{
    [self animate:view toFade:fade completion:NULL];
}

- (void)animate:(UIView *)view toFade:(BOOL)fade completion:(Completion)completion
{
    [[view layer] setOpacity:fade? 0 : 1];
    
    NSString *key = [NSString stringWithFormat:@"FADE-%@", view];
    [[view layer] removeAnimationForKey:key];
    
    CATransition *transition = [CATransition animation];
    transition.duration = [self animationDuration];
    transition.type = kCATransitionFade;
    
    [[view layer] addAnimation:transition forKey:key];
}


@end
