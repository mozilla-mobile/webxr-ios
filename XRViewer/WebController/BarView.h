#import <UIKit/UIKit.h>

#define URL_FIELD_HEIGHT 29

typedef void (^BackAction)(id sender);
typedef void (^ForwardAction)(id sender);
typedef void (^HomeAction)(id sender);
typedef void (^ReloadAction)(id sender);
typedef void (^CancelAction)(id sender);
typedef void (^GoAction)(NSString *url);


@interface BarView : UIView

@property (nonatomic, copy) BackAction backActionBlock;
@property (nonatomic, copy) ForwardAction forwardActionBlock;
@property (nonatomic, copy) HomeAction homeActionBlock;
@property (nonatomic, copy) ReloadAction reloadActionBlock;
@property (nonatomic, copy) CancelAction cancelActionBlock;
@property (nonatomic, copy) GoAction goActionBlock;

- (NSString *)urlFieldText;

- (void)startLoading:(NSString *)url;
- (void)finishLoading:(NSString *)url;

- (void)setBackEnabled:(BOOL)enabled;
- (void)setForwardEnabled:(BOOL)enabled;

@end
