//
//  RecordButton.m
//  XRViewer
//
//  Created by Vasil_OK on 20.10.17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import "RecordButton.h"
#import "OverlayHeader.h"

@implementation RecordButton

+ (instancetype)new
{
    return [[self alloc] initWithFrame:CGRectMake(0, 0, FULL_SIZE, FULL_SIZE)];
}

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer
{
    return (CAShapeLayer *)[self layer];
}

- (CAShapeLayer *)ringLayer
{
    return (CAShapeLayer *)[[[self layer] sublayers] firstObject];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    [[self shapeLayer] setFillColor:[UIColor whiteColor].CGColor];
    [[self shapeLayer] setPath:[self normalPath]];
    [[self layer] addSublayer:[self ringShape]];
    
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if ([super isSelected] == selected) return;
    
    [super setSelected:selected];
    
    [[self shapeLayer] setPath:selected ? [self selectedPath] : [self normalPath]];
    
    [self animate];
}

- (CAShapeLayer *)ringShape
{
    CAShapeLayer *ring = [CAShapeLayer layer];
    CGRect rect = CGRectMake(0, 0, FULL_SIZE, FULL_SIZE);
    ring.frame = rect;
    ring.geometryFlipped = YES;
    ring.path = CGPathCreateWithRoundedRect(rect, FULL_SIZE / 2, FULL_SIZE / 2, nil);
    ring.strokeColor = [[UIColor whiteColor] CGColor];
    ring.fillColor = nil;
    ring.lineWidth = RING_WIDTH;
    ring.opacity = .5;
    ring.lineJoin = kCALineJoinBevel;
    
    return ring;
}

- (CGPathRef)selectedPath
{
    CGFloat padding = (FULL_SIZE - SELECTED_SIZE) / 2;
    CGRect selectedRect = CGRectMake(padding, padding, SELECTED_SIZE, SELECTED_SIZE);
    return CGPathCreateWithRoundedRect(selectedRect, SELECTED_RADIUS, SELECTED_RADIUS, nil);
}

- (CGPathRef)normalPath
{
    CGFloat padding = (FULL_SIZE - NORMAL_SIZE) / 2;
    CGRect normalRect = CGRectMake(padding, padding, NORMAL_SIZE, NORMAL_SIZE);
    return CGPathCreateWithRoundedRect(normalRect, normalRect.size.width / 2, normalRect.size.height / 2, nil);
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    // stub
}

- (void)animate
{
    [[self shapeLayer] removeAllAnimations];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.duration = ANIMATION_DURATION;
    pathAnimation.fromValue = (id)([self isSelected] ? [self normalPath] : [self selectedPath]);
    pathAnimation.toValue = (id)([self isSelected] ? [self selectedPath] : [self normalPath]);
    [[self shapeLayer] addAnimation:pathAnimation forKey:@"pathAnimation"];
    
    if ([self isSelected])
    {
        CABasicAnimation *ringAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        ringAnimation.duration = ANIMATION_DURATION / 2;
        ringAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        ringAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [[self ringLayer] addAnimation:ringAnimation forKey:@"ringAnimation"];
    }
    else
    {
        CABasicAnimation *ringAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        ringAnimation.duration = ANIMATION_DURATION / 2;
        ringAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        ringAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        [[self ringLayer] addAnimation:ringAnimation forKey:@"ringAnimation"];
    }
}

@end
