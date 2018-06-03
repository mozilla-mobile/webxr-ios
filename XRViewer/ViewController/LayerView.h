#import <UIKit/UIKit.h>

/**
 A UIView that passes through the touch events to its subviews when
 processTouchInSubview is set to YES
 */
@interface LayerView : UIView

/**
 If set to YES, the touch events of this UIView are passed to the subviews
 */
@property BOOL processTouchInSubview;

@end
