#import <UIKit/UIKit.h>
#import "OverlayHeader.h"

@interface TouchView : UIView

// It allows the Touch view to receive UITouches, but nothing to do
// It prevents to process touches on JS side
@property BOOL holdTouch;

- (instancetype)initWithFrame:(CGRect)frame
                 cameraAction:(HotAction)cameraAction
                    micAction:(HotAction)micAction
                   showAction:(HotAction)showAction
                  debugAction:(HotAction)debugAction;

- (void)setCameraRect:(CGRect)cameraRect
              micRect:(CGRect)micRect
             showRect:(CGRect)showRect
            debugRect:(CGRect)debugRect;

- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;

@end
