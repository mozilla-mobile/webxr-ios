#import <WebKit/WebKit.h>
#import "RecordController.h"
#import "Animator.h"
#import "AppState.h"

typedef void (^OnLoad)(void);
typedef void (^OnInit)(NSDictionary *);
typedef void (^OnWebError)(NSError *);
typedef void (^OnUpdateTransfer)(NSDictionary * );

typedef void (^ResultBlock)(NSDictionary *);
typedef void (^ResultArrayBlock)(NSArray *);

typedef void (^OnRemoveObjects)(NSArray * );
typedef NSDictionary * (^OnJSUpdateData)(void);
typedef void (^OnLoadURL)(NSString *);
typedef void (^OnSetUI)(NSDictionary *);

typedef void (^OnHitTest)(NSUInteger, CGFloat, CGFloat, ResultArrayBlock);
typedef void (^OnAddAnchor)(NSString *, NSArray *, ResultBlock);


@interface WebController : NSObject

@property(nonatomic, copy) OnInit onInit;
@property(nonatomic, copy) OnWebError onError;
@property(nonatomic, copy) OnUpdateTransfer onIOSUpdate;
@property(nonatomic, copy) OnLoadURL loadURL;
@property(nonatomic, copy) OnUpdateTransfer onJSUpdate;
@property(nonatomic, copy) OnJSUpdateData onJSUpdateData;
@property(nonatomic, copy) OnRemoveObjects onRemoveObjects;
@property(nonatomic, copy) OnSetUI onSetUI;
@property(nonatomic, copy) OnHitTest onHitTest;
@property(nonatomic, copy) OnAddAnchor onAddAnchor;
@property(nonatomic, copy) OnLoad onStartLoad;
@property(nonatomic, copy) OnLoad onFinishLoad;

@property (nonatomic, strong) Animator *animator;

@property (nonatomic, weak) NSLayoutConstraint *barViewHeightAnchorConstraint;

@property (nonatomic, weak) NSLayoutConstraint* webViewTopAnchorConstraint;

@property(nonatomic, strong) NSLayoutConstraint *webViewLeftAnchorConstraint;

- (instancetype)initWithRootView:(UIView *)rootView;
- (void)viewWillTransitionToSize:(CGSize)size;

- (void)loadURL:(NSString *)url;

- (NSString *)lastURL;

- (void)reload;
- (void)clean;

- (void)setupForWebXR:(BOOL)webXR;

- (void)showBar:(BOOL)showBar;
- (void)showDebug:(BOOL)showDebug;
- (void)startRecording:(BOOL)start;
- (void)wasARInterruption:(BOOL)interruption;
- (void)didBackgroundAction:(BOOL)background;
- (void)didChangeARTrackingState:(NSString *)state;

- (void)updateWindowSize;

- (void)didReceiveMemoryWarning;

- (WKWebView *)webView;

- (BOOL)sendARData:(NSDictionary *)data;

@end

