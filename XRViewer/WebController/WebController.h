#import <WebKit/WebKit.h>
#import "RecordController.h"
#import "Animator.h"
#import "AppState.h"

typedef void (^OnURL)(NSString *);
typedef void (^OnAction)(NSDictionary *);
typedef void (^OnActionWithResult)(NSDictionary *, OnAction);

typedef void (^OnWebAction)(void);
typedef void (^OnWebError)(NSError *);

@interface WebController : NSObject

// xr handler
@property(nonatomic, copy) OnAction onInit;
@property(nonatomic, copy) OnURL onLoadURL;
@property(nonatomic, copy) OnAction onWatch;
@property(nonatomic, copy) OnAction onSetUI;
@property(nonatomic, copy) OnActionWithResult onHitTest;
@property(nonatomic, copy) OnActionWithResult onAddAnchor;
@property(nonatomic, copy) OnActionWithResult onRemoveAnchor;
@property(nonatomic, copy) OnActionWithResult onUpdateAnchor;
@property(nonatomic, copy) OnActionWithResult onStartHold;
@property(nonatomic, copy) OnActionWithResult onStopHold;
@property(nonatomic, copy) OnActionWithResult onAddRegion;
@property(nonatomic, copy) OnActionWithResult onRemoveRegion;
@property(nonatomic, copy) OnActionWithResult onInRegion;
    
// webview handler
@property(nonatomic, copy) OnWebError onError;
@property(nonatomic, copy) OnWebAction onStartLoad;
@property(nonatomic, copy) OnWebAction onFinishLoad;

@property (nonatomic, strong) Animator *animator;

- (instancetype)initWithRootView:(UIView *)rootView;
- (WKWebView *)webView;
- (void)loadURL:(NSString *)url;
- (NSString *)lastURL;

- (void)reload;
- (void)clean;
    
- (void)showBar:(BOOL)showBar;
    
- (void)setupForApp:(UIStyle)app;
    
// xr
- (void)showDebug:(BOOL)showDebug;
- (void)didBackgroundAction:(BOOL)background;
- (void)didReceiveMemoryWarning;
- (void)viewWillTransitionToSize:(CGSize)size rotation:(CGFloat)rotation;
- (void)didChangeOrientation:(UIInterfaceOrientation)orientation withSize:(CGSize)size;
- (void)didRegion:(NSDictionary *)param enter:(BOOL)enter;
- (void)didUpdateHeading:(NSDictionary *)dict;
- (void)didUpdateLocation:(NSDictionary *)dict;
- (void)wasARInterruption:(BOOL)interruption;
- (void)didChangeARTrackingState:(NSString *)state;
- (void)didSessionFails;
- (void)didUpdateAnchors:(NSDictionary *)dict;
- (void)didAddPlanes:(NSDictionary *)dict;
- (void)didRemovePlanes:(NSDictionary *)dict;
- (void)startRecording:(BOOL)start;
  
- (BOOL)sendARData:(NSDictionary *)data;

@end

