#import <UIKit/UIKit.h>
#import "OverlayHeader.h"

@interface TouchView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                 cameraAction:(HotAction)cameraAction
                    micAction:(HotAction)micAction
                   showAction:(HotAction)showAction
                  debugAction:(HotAction)debugAction;

- (void)setProcessTouches:(BOOL)process;

- (void)setCameraRect:(CGRect)cameraRect
              micRect:(CGRect)micRect
             showRect:(CGRect)showRect
            debugRect:(CGRect)debugRect;

- (void)setShowMode:(ShowMode)mode;
- (void)setShowOptions:(ShowOptions)options;
- (void)setRecordState:(RecordState)state;

@end
