#import <WebKit/WebKit.h>
#import "RecordController.h"
#import "Animator.h"

#define INTERNET_OFFLINE_CODE -1009
#define URL_CANT_BE_SHOWN 101

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

#warning Test Memory Warning
typedef void (^OnTestMemoryWarning)(BOOL);

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
@property(nonatomic, copy) OnTestMemoryWarning onMemory;
@property(nonatomic, copy) OnLoad onStartLoad;
@property(nonatomic, copy) OnLoad onFinishLoad;

@property (nonatomic, strong) Animator *animator;

- (instancetype)initWithRootView:(UIView *)rootView atIndex:(NSUInteger)index;
- (void)viewWillTransitionToSize:(CGSize)size;

- (void)loadURL:(NSString *)url;

- (NSString *)lastURL;

- (void)reload;
- (void)clean;

- (void)showBar:(BOOL)showBar;
- (void)showDebug:(BOOL)showDebug;

- (void)didMoveBackground;
- (void)willEnterForeground;

- (void)arkitWasInterrupted;
- (void)arkitInterruptionEnded;

- (void)arkitDidChangeTrackingState:(NSString *)state;
- (void)iosDidReceiveMemoryWarning;

- (WKWebView *)webView;

- (BOOL)sendARData:(NSDictionary *)data;

- (void)setRecordState:(RecordState)state;

@end
