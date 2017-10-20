//
//  MicButton.m
//  XRViewer
//
//  Created by Vasil_OK on 20.10.17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import "MicButton.h"
#import "OverlayHeader.h"

@interface MicButton ()

@property(weak) CAShapeLayer *ringLayer;
@property(weak) CAShapeLayer *lineLayer;
@property(weak) CALayer *micLayer;

@end

@implementation MicButton

+ (instancetype)new
{
    return [[self alloc] initWithFrame:CGRectMake(0, 0, MIC_SIZE, MIC_SIZE)];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    self.micLayer = [self micImage];
    [[self layer] addSublayer:self.micLayer];
    
    self.lineLayer = [self lineShape];
    [[self layer] addSublayer:self.lineLayer];
    
    self.ringLayer = [self ringShape];
    [[self layer] addSublayer:self.ringLayer];
    
    return self;
}

- (void)setSelected:(BOOL)selected
{
    //if ([super isSelected] == selected) return;
    DDLogDebug(@"Mic selected - %d", selected);
#warning TEMP DESIGN !
    [super setSelected:![self isSelected]];
    
    [self animate];
}

- (CALayer *)micImage
{
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, MIC_SIZE, MIC_SIZE);
    layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"microphone"].CGImage);
    
    return layer;
}

- (CAShapeLayer *)ringShape
{
    CAShapeLayer *ring = [CAShapeLayer layer];
    CGRect rect = CGRectMake(0, 0, MIC_SIZE, MIC_SIZE);
    ring.frame = rect;
    ring.geometryFlipped = YES;
    ring.path = CGPathCreateWithRoundedRect(rect, MIC_SIZE / 2, MIC_SIZE / 2, nil);
    ring.strokeColor = [[UIColor whiteColor] CGColor];
    ring.fillColor = nil;
    ring.lineWidth = MIC_RING_WIDTH;
    ring.opacity = 1;
    ring.lineJoin = kCALineJoinBevel;
    
    return ring;
}

- (CAShapeLayer *)lineShape
{
    CAShapeLayer *line = [CAShapeLayer layer];
    CGRect rect = CGRectMake(0, 0, MIC_SIZE, MIC_SIZE);
    line.frame = rect;
    line.geometryFlipped = YES;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, MIC_INNER_OFFSET, MIC_INNER_OFFSET);
    CGPathAddLineToPoint (path, NULL, MIC_SIZE - MIC_INNER_OFFSET, MIC_SIZE - MIC_INNER_OFFSET);
    line.path = CGPathCreateCopy(path);
    CGPathRelease(path);
    
    line.strokeColor = [[UIColor whiteColor] CGColor];
    line.fillColor = nil;
    line.lineWidth = MIC_RING_WIDTH;
    line.opacity = 1;
    line.lineJoin = kCALineJoinBevel;
    
    return line;
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    // stub
}

- (void)animate
{
    [[self layer] removeAllAnimations];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pathAnimation.duration = ANIMATION_DURATION;
    pathAnimation.fromValue = [self isSelected] ? @0.5 : @1;
    pathAnimation.toValue = [self isSelected] ? @1 : @0.5;
    [[self micLayer] addAnimation:pathAnimation forKey:@"micAnimation"];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [[self micLayer] setOpacity:[self isSelected] ? 1 : 0.5];
    [CATransaction commit];
    
    if ([self isSelected])
    {
        CABasicAnimation *lineAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        lineAnimation.duration = ANIMATION_DURATION / 2;
        lineAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        lineAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [[self lineLayer] addAnimation:lineAnimation forKey:@"strokeStartLine"];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [[self lineLayer] setStrokeStart:1];
        [[self lineLayer] setStrokeEnd:1];
        [CATransaction commit];
        
        CABasicAnimation *ringAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        ringAnimation.duration = ANIMATION_DURATION / 2;
        ringAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        ringAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [[self ringLayer] addAnimation:ringAnimation forKey:@"ringEndAnimation"];
    }
    else
    {
        CABasicAnimation *lineAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        lineAnimation.duration = ANIMATION_DURATION / 2;
        lineAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        lineAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [[self lineLayer] addAnimation:lineAnimation forKey:@"strokeEndLine"];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [[self lineLayer] setStrokeStart:0];
        [[self lineLayer] setStrokeEnd:1];
        [CATransaction commit];
        
        CABasicAnimation *ringAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        ringAnimation.duration = ANIMATION_DURATION / 2;
        ringAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        ringAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [[self ringLayer] addAnimation:ringAnimation forKey:@"ringStartAnimation"];
    }
}

@end
