#import "LayerView.h"

@implementation LayerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{    
    if ([self processTouchInSubview])
    {
        return [[[self subviews] firstObject] hitTest:point withEvent:event];;
    }
    
    return [super hitTest:point withEvent:event];
}

@end
