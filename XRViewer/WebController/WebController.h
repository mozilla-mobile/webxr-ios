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
typedef void (^OnDebugButtonToggled)(BOOL);
typedef void (^OnSettingsButtonTapped)(void);
typedef void (^OnWatchAR)(NSDictionary *);
typedef void (^OnComputerVisionDataRequested)(void);
typedef void (^OnStopAR)(void);
typedef void (^OnResetTrackingButtonTapped)(void);

@interface WebController : NSObject

@property(nonatomic, copy) OnInit onInitAR;
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
@property(nonatomic, copy) OnDebugButtonToggled onDebugButtonToggled;
@property(nonatomic, copy) OnSettingsButtonTapped onSettingsButtonTapped;
@property(nonatomic, copy) OnWatchAR onWatchAR;
@property(nonatomic, copy) OnComputerVisionDataRequested onComputerVisionDataRequested;
@property(nonatomic, copy) OnStopAR onStopAR;
@property(nonatomic, copy) OnResetTrackingButtonTapped onResetTrackingButtonTapped;

@property (nonatomic, strong) Animator *animator;

@property (nonatomic, weak) NSLayoutConstraint *barViewHeightAnchorConstraint;

@property (nonatomic, weak) NSLayoutConstraint* webViewTopAnchorConstraint;

@property(nonatomic, strong) NSLayoutConstraint *webViewLeftAnchorConstraint;

@property(nonatomic, strong) NSLayoutConstraint *webViewRightAnchorConstraint;

@property(nonatomic, strong) NSString *lastXRVisitedURL;

- (instancetype)initWithRootView:(UIView *)rootView;
- (void)viewWillTransitionToSize:(CGSize)size;

- (void)loadURL:(NSString *)url;

- (void)loadBlankHTMLString;

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

- (void)hideKeyboard;

- (void)didReceiveError:(NSError *)error;

- (void)sendComputerVisionData:(NSDictionary *)computerVisionData;
@end

