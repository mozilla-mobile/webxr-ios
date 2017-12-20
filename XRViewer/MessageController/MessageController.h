#import <UIKit/UIKit.h>

typedef void (^DidShowMessage)(void);
typedef void (^DidHideMessage)(void);
typedef void (^DidHideMessageByUser)(void);

@interface MessageController : NSObject

@property(nonatomic, copy) DidShowMessage didShowMessage;
@property(nonatomic, copy) DidHideMessage didHideMessage;
@property(nonatomic, copy) DidHideMessageByUser didHideMessageByUser;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)arMessageShowing;

- (void)clean;

- (instancetype)initWithViewController:(UIViewController *)vc;

- (void)showMessageAboutWebError:(NSError *)error withCompletion:(void(^)(BOOL reload))reloadCompletion;

- (void)showMessageAboutARInteruption:(BOOL)interupt;

- (void)showMessageAboutFailSessionWithMessage:(NSString *)message completion:(void (^)(void))completion;

- (void)showMessageWithTitle:(NSString*)title message:(NSString*)message hideAfter:(NSInteger)seconds;

- (void)showMessageAboutFailSessionWithCompletion:(void(^)(void))completion;

- (void)showMessageAboutMemoryWarningWithCompletion:(void(^)(void))completion;

- (void)showMessageAboutConnectionRequired;

@end
