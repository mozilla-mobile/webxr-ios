#import <UIKit/UIKit.h>
#import "OverlayHeader.h"
#import "RecordController.h"
#import "Animator.h"

@interface OverlayViewController : UIViewController

@property (nonatomic) RecordState recordState;
@property (nonatomic) ShowMode showMode;
@property (nonatomic) ShowOptions showOptions;
@property (nonatomic) BOOL microphoneEnabled;

@property (nonatomic, strong) Animator *animator;

- (void)setTrackingState:(NSString *)state;

@end
