#import <UIKit/UIKit.h>

#define URL_FIELD_HEIGHT 29

typedef void (^BackAction)(id sender);
typedef void (^ForwardAction)(id sender);
typedef void (^HomeAction)(id sender);
typedef void (^ReloadAction)(id sender);
typedef void (^CancelAction)(id sender);
typedef void (^GoAction)(NSString *url);
typedef void (^DebugButtonToggledAction)(BOOL selected);
typedef void (^SettingsAction)(void);
typedef void (^ResetTrackingAction)(void);
typedef void (^SwitchCameraAction)(void);


@interface BarView : UIView

@property (nonatomic, copy) BackAction backActionBlock;
@property (nonatomic, copy) ForwardAction forwardActionBlock;
@property (nonatomic, copy) HomeAction homeActionBlock;
@property (nonatomic, copy) ReloadAction reloadActionBlock;
@property (nonatomic, copy) CancelAction cancelActionBlock;
@property (nonatomic, copy) GoAction goActionBlock;
@property (nonatomic, copy) DebugButtonToggledAction debugButtonToggledAction;
@property (nonatomic, copy) SettingsAction settingsActionBlock;
@property (nonatomic, copy) ResetTrackingAction restartTrackingActionBlock;
@property (nonatomic, copy) SwitchCameraAction switchCameraActionBlock;

- (NSString *)urlFieldText;

- (void)startLoading:(NSString *)url;
- (void)finishLoading:(NSString *)url;

- (void)setBackEnabled:(BOOL)enabled;
- (void)setForwardEnabled:(BOOL)enabled;

- (void)setDebugSelected:(BOOL)selected;
- (void)setDebugVisible:(BOOL)visible;

- (void)setRestartTrackingVisible:(BOOL)visible;

- (void)hideKeyboard;

- (BOOL)isDebugButtonSelected;
@end
