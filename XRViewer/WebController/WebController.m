#import <Foundation/Foundation.h>
#import "WebController.h"
#import "WebARKHeader.h"
#import "ARKHelper.h"
#import "OverlayHeader.h"
#import "BarView.h"

@interface WebController () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, weak) UIView *rootView;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) WKUserContentController *contentController;
@property (nonatomic, copy) NSString *transferCallback;
@property (nonatomic, copy) NSString *lastURL;

@property (nonatomic, weak) BarView *barView;

@end

typedef void (^WebCompletion)(id _Nullable param, NSError * _Nullable error);

inline static WebCompletion debugCompletion(NSString *name)
{
    return ^(id  _Nullable param, NSError * _Nullable error)
    {
        DDLogDebug(@"%@ : %@", name, error ? @"error" : @"success");
    };
}

@implementation WebController

#pragma mark Interface

- (void)dealloc
{
    DDLogDebug(@"WebController dealloc");
}

- (instancetype)initWithRootView:(UIView *)rootView
{
    self = [super init];
    
    if (self)
    {
        [self setupWebViewWithRootView:rootView];
        [self setupWebContent];
        [self setupWebUI];
        [self setupBarView];
    }
    
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size
{
    [self layout];
    
    [self callWebMethod:WEB_AR_IOS_WIEW_WILL_TRANSITION_TO_SIZE_MESSAGE param:NSStringFromCGSize(size) webCompletion:debugCompletion(@"viewWillTransitionToSize")];
}

- (void)clean
{
    [self cleanWebContent];
    
    [[self webView] stopLoading];
    
    [[[self webView] configuration] setProcessPool:[WKProcessPool new]];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (BOOL)sendARData:(NSDictionary *)data
{
#define CHECK_UPDATE_CALL NO
    if ([self transferCallback] && data)
    {
        [self callWebMethod:[self transferCallback] paramJSON:data webCompletion:CHECK_UPDATE_CALL ? debugCompletion(@"sendARData") : NULL];
        
        return YES;
    }
    
    return NO;
}

- (void)reload
{
    NSString *url = [[[self barView] urlFieldText] length] > 0 ? [[self barView] urlFieldText] : [self lastURL];
    [self loadURL:url];
}

- (void)loadURL:(NSString *)theUrl
{
    NSURL *url;
    if([theUrl hasPrefix:@"http://"] || [theUrl hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:theUrl];
    } else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", theUrl]];
    }
    
    if (url)
    {
        NSString *scheme = [url scheme];
        
        if (scheme && [WKWebView handlesURLScheme:scheme])
        {
            NSURLRequest *r = [NSURLRequest requestWithURL:url
                                               cachePolicy:NSURLRequestReloadIgnoringCacheData
                                           timeoutInterval:60];
            
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
            
            
            [[self webView] loadRequest:r];
            
            [self setLastURL:[url absoluteString]];
            
            return;
        }
    }
    
    if ([self onError])
    {
        [self onError](nil);
    }
}

- (void)startRecording:(BOOL)start
{
    NSString *message = start ? WEB_AR_IOS_START_RECORDING_MESSAGE : WEB_AR_IOS_STOP_RECORDING_MESSAGE;
    
    [self callWebMethod:message param:@"" webCompletion:debugCompletion(@"setRecordState")];
}

- (void)setupForWebXR:(BOOL)webXR
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        CGRect rect = [[[self webView] superview] bounds];
        
        if (webXR == NO)
        {
            rect.origin.y += [[self barView] bounds].size.height;
        }
        
        [[self animator] animate:[self webView] toFrame:rect];
        
        UIColor *backColor = webXR ? [UIColor clearColor] : [UIColor whiteColor];
        [[[self webView] superview] setBackgroundColor:backColor];
        
        [[self animator] animate:[[self webView] superview] toColor:backColor];
    });
}

- (void)showBar:(BOOL)showBar
{
    CGRect rect = [[self barView] bounds];
    rect.origin.y = showBar ? 0 : 0 - [[self barView] bounds].size.height;
    
    [[self animator] animate:[self barView] toFrame:rect];
}

- (void)showDebug:(BOOL)showDebug
{
    [self callWebMethod:WEB_AR_IOS_SHOW_DEBUG paramJSON:@{WEB_AR_UI_DEBUG_OPTION : (showDebug ? @YES : @NO)} webCompletion:debugCompletion(@"showDebug")];
}

- (void)wasARInterruption:(BOOL)interruption
{
    NSString *message = interruption ? WEB_AR_IOS_START_RECORDING_MESSAGE : WEB_AR_IOS_INTERRUPTION_ENDED_MESSAGE;
    
    [self callWebMethod:message param:@"" webCompletion:debugCompletion(@"ARinterruption")];
}

- (void)didBackgroundAction:(BOOL)background
{
    NSString *message = background ? WEB_AR_IOS_DID_MOVE_BACK_MESSAGE : WEB_AR_IOS_WILL_ENTER_FOR_MESSAGE;
    
    [self callWebMethod:message param:@"" webCompletion:debugCompletion(@"backgroundAction")];
}

- (void)didReceiveMemoryWarning
{
    [self callWebMethod:WEB_AR_IOS_DID_RECEIVE_MEMORY_WARNING_MESSAGE param:@"" webCompletion:debugCompletion(@"iosDidReceiveMemoryWarning")];
}

- (void)didChangeARTrackingState:(NSString *)state
{
    [self callWebMethod:WEB_AR_IOS_TRACKING_STATE_MESSAGE param:state webCompletion:debugCompletion(@"arkitDidChangeTrackingState")];
}

#pragma mark WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    DDLogDebug(@"Received message: %@ , body: %@", [message name], [message body]);
    
    __weak typeof (self) blockSelf = self;
    
    if ([[message name] isEqualToString:WEB_AR_INIT_MESSAGE])
    {
        NSDictionary *params = @{ WEB_IOS_DEVICE_UUID_OPTION : [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                  WEB_IOS_IS_IPAD_OPTION : @([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad),
                                  WEB_IOS_SYSTEM_VERSION_OPTION : [[UIDevice currentDevice] systemVersion],
                                  WEB_IOS_SCREEN_SCALE_OPTION : @([[UIScreen mainScreen] nativeScale]),
                                  WEB_IOS_SCREEN_SIZE_OPTION : NSStringFromCGSize([[UIScreen mainScreen] nativeBounds].size)};
        
        DDLogDebug(@"Init AR send - %@", [params debugDescription]);
        
        [self callWebMethod:[[message body] objectForKey:WEB_AR_CALLBACK_OPTION]
                  paramJSON:params
              webCompletion:^(id  _Nullable param, NSError * _Nullable error)
         {
             DDLogDebug(@"Init AR %@", error ? @"error" : @"success");
             
             if (error == nil)
             {
                 [blockSelf onInit]([message body][WEB_AR_REQUEST_OPTION][WEB_AR_UI_OPTION]);
             }
             else
             {
                 [blockSelf onError](error);
             }
         }];
    }
    else if ([[message name] isEqualToString:WEB_AR_LOAD_URL_MESSAGE])
    {
        [self loadURL]([[message body] objectForKey:WEB_AR_URL_OPTION]);
    }
    else if ([[message name] isEqualToString:WEB_AR_START_WATCH_MESSAGE])
    {
        [self setTransferCallback:[[message body] objectForKey:WEB_AR_CALLBACK_OPTION]];
        
        if ([[[message body] objectForKey:WEB_AR_JS_FRAME_RATE_OPTION] boolValue])
        {
            [self onJSUpdate]([[message body] objectForKey:WEB_AR_REQUEST_OPTION]);
        }
        else
        {
            [self onIOSUpdate]([[message body] objectForKey:WEB_AR_REQUEST_OPTION]);
        }
    }
    else if ([[message name] isEqualToString:WEB_AR_ON_JS_UPDATE_MESSAGE])
    {
        [self sendARData:[blockSelf onJSUpdateData]()];
    }
    else if ([[message name] isEqualToString:WEB_AR_STOP_WATCH_MESSAGE])
    {
        [self setTransferCallback:nil];
        
        [self onIOSUpdate](nil);
        
        [self onJSUpdate](nil);
        
        [self callWebMethod:[[message body] objectForKey:WEB_AR_CALLBACK_OPTION] param:@"" webCompletion:NULL];
    }
    else if ([[message name] isEqualToString:WEB_AR_SET_UI_MESSAGE])
    {
        [self onSetUI]([message body]);
    }
    else if ([[message name] isEqualToString:WEB_AR_HIT_TEST_MESSAGE])
    {
        NSString *hitCallback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        NSUInteger type = [[[message body] objectForKey:WEB_AR_TYPE_OPTION] integerValue];
        CGFloat x = [[[message body] objectForKey:WEB_AR_X_POSITION_OPTION] floatValue];
        CGFloat y = [[[message body] objectForKey:WEB_AR_Y_POSITION_OPTION] floatValue];
        
        [self onHitTest](type, x, y, ^(NSArray *results)
                         {
                             DDLogDebug(@"Hit test - %@", [results debugDescription]);
                             [blockSelf callWebMethod:hitCallback paramJSON:results webCompletion:debugCompletion(@"onHitTest")];
                         });
    }
    else if ([[message name] isEqualToString:WEB_AR_ADD_ANCHOR_MESSAGE])
    {
        NSString *hitCallback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        NSString *name = [[message body] objectForKey:WEB_AR_UUID_OPTION];
        NSArray *transform = [[message body] objectForKey:WEB_AR_TRANSFORM_OPTION];
        
        [self onAddAnchor](name, transform,^(NSDictionary *results)
                           {
                               [blockSelf callWebMethod:hitCallback paramJSON:results webCompletion:debugCompletion(@"onAddAnchor")];
                           });
    }
    else
    {
        DDLogError(@"Unknown message: %@ ,for name: %@", [message body], [message name]);
    }
}

- (void)callWebMethod:(NSString *)name param:(NSString *)param webCompletion:(WebCompletion)completion
{
    NSData *jsonData = param ? [NSJSONSerialization dataWithJSONObject:@[param] options:0 error:nil] : [NSData data];
    [self callWebMethod:name jsonData:jsonData  webCompletion:completion];
}

- (void)callWebMethod:(NSString *)name paramJSON:(id)paramJSON webCompletion:(WebCompletion)completion
{
    NSData *jsonData = paramJSON ? [NSJSONSerialization dataWithJSONObject:paramJSON options:0 error:nil] : [NSData data];
    [self callWebMethod:name jsonData:jsonData webCompletion:completion];
}

- (void)callWebMethod:(NSString *)name jsonData:(NSData *)jsonData webCompletion:(WebCompletion)completion
{
    NSAssert(name, @" Web Massage name is nil !");
    
    NSString *jsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsScript = [NSString stringWithFormat:@"%@(%@)", name, jsString];
    
    [[self webView] evaluateJavaScript:jsScript completionHandler:completion];
}

#pragma mark WKUIDelegate, WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    DDLogDebug(@"didStartProvisionalNavigation - %@", navigation);
    
    [self onStartLoad]();
    
    [[self barView] startLoading:[[[self webView] URL] absoluteString]];
    [[self barView] setBackEnabled:[[self webView] canGoBack]];
    [[self barView] setForwardEnabled:[[self webView] canGoForward]];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    DDLogDebug(@"didFinishNavigation - %@", navigation);
    [self setLastURL:[[[self webView] URL] absoluteString]];
    
    [self onFinishLoad]();
    
    [[self barView] finishLoading:[[[self webView] URL] absoluteString]];
    [[self barView] setBackEnabled:[[self webView] canGoBack]];
    [[self barView] setForwardEnabled:[[self webView] canGoForward]];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    DDLogError(@"Web Error - %@", error);
    
    if ([self shouldShowError:error])
    {
        [self onError](error);
    }
    
    [[self barView] finishLoading:[[[self webView] URL] absoluteString]];
    [[self barView] setBackEnabled:[[self webView] canGoBack]];
    [[self barView] setForwardEnabled:[[self webView] canGoForward]];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    DDLogError(@"Web Error - %@", error);
    
    if ([self shouldShowError:error])
    {
        [self onError](error);
    }
    
    [[self barView] finishLoading:[[[self webView] URL] absoluteString]];
    [[self barView] setBackEnabled:[[self webView] canGoBack]];
    [[self barView] setForwardEnabled:[[self webView] canGoForward]];
}

- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo
{
    return NO;
}

#pragma mark Private

- (BOOL)shouldShowError:(NSError *)error
{
    return (([error code] > 600) || ([error code] < 200));
}

- (void)layout
{
    [[self webView] layoutIfNeeded];
    
    [[self barView] layoutIfNeeded];
}

- (void)setupWebUI
{
    [[self webView] setAutoresizingMask:
     UIViewAutoresizingFlexibleRightMargin |
     UIViewAutoresizingFlexibleLeftMargin |
     UIViewAutoresizingFlexibleBottomMargin |
     UIViewAutoresizingFlexibleTopMargin |
     UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight];
    
    [[self webView] setAutoresizesSubviews:YES];
    
    [[self webView] setAllowsLinkPreview:NO];
    [[self webView] setOpaque:NO];
    [[self webView] setBackgroundColor:[UIColor clearColor]];
    [[self webView] setUserInteractionEnabled:YES];
    [[[self webView] scrollView] setBounces:NO];
    [[[self webView] scrollView] setBouncesZoom:NO];
}

- (void)setupBarView
{
    BarView *barView = [[[NSBundle mainBundle] loadNibNamed:@"BarView" owner:self options:nil] firstObject];
    [barView setFrame:CGRectMake(0, 0, [[self webView] bounds].size.width, URL_BAR_HEIGHT)];
    [barView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin |
     UIViewAutoresizingFlexibleLeftMargin |
     UIViewAutoresizingFlexibleWidth];
    [[[self webView] superview] addSubview:barView];
    [self setBarView:barView];
    
    __weak typeof (self) blockSelf = self;
    __weak typeof (BarView *) blockBar = barView;
    
    [barView setBackActionBlock:^(id sender)
     {
         if ([[blockSelf webView] canGoBack])
         {
             [[blockSelf webView] goBack];
         }
         else
         {
             [blockBar setBackEnabled:NO];
         }
     }];
    
    [barView setForwardActionBlock:^(id sender)
     {
         if ([[blockSelf webView] canGoForward])
         {
             [[blockSelf webView] goForward];
         }
         else
         {
             [blockBar setForwardEnabled:NO];
         }
     }];
    
    [barView setCancelActionBlock:^(id sender)
     {
         [[blockSelf webView] stopLoading];
     }];
    
    [barView setReloadActionBlock:^(id sender)
     {
         [blockSelf loadURL:[blockBar urlFieldText]];
     }];
    
    [barView setGoActionBlock:^(NSString *url)
     {
         [blockSelf loadURL:url];
     }];
}

- (void)setupWebContent
{
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_INIT_MESSAGE];
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_START_WATCH_MESSAGE];
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_STOP_WATCH_MESSAGE];
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_ON_JS_UPDATE_MESSAGE];
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_LOAD_URL_MESSAGE];
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_SET_UI_MESSAGE];
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_HIT_TEST_MESSAGE];
    [[self contentController] addScriptMessageHandler:self name:WEB_AR_ADD_ANCHOR_MESSAGE];
}

- (void)cleanWebContent
{
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_INIT_MESSAGE];
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_START_WATCH_MESSAGE];
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_STOP_WATCH_MESSAGE];
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_ON_JS_UPDATE_MESSAGE];
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_LOAD_URL_MESSAGE];
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_SET_UI_MESSAGE];
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_HIT_TEST_MESSAGE];
    [[self contentController] removeScriptMessageHandlerForName:WEB_AR_ADD_ANCHOR_MESSAGE];
}

- (void)setupWebViewWithRootView:(__autoreleasing UIView*)rootView
{
    WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *contentController = [WKUserContentController new];
    [conf setUserContentController:contentController];
    [self setContentController:contentController];
    
    WKPreferences *pref = [[WKPreferences alloc] init];
    [pref setJavaScriptEnabled:YES];
    [conf setPreferences:pref];
    
    [conf setProcessPool:[WKProcessPool new]];

    [conf setAllowsInlineMediaPlayback: YES];
    [conf setAllowsAirPlayForMediaPlayback: YES];
    [conf setAllowsPictureInPictureMediaPlayback: YES];
    [conf setMediaTypesRequiringUserActionForPlayback: WKAudiovisualMediaTypeNone];
    
    WKWebView *wv = [[WKWebView alloc] initWithFrame:[rootView bounds] configuration:conf];
    [rootView addSubview:wv];
    [wv setNavigationDelegate:self];
    [wv setUIDelegate:self];
    [self setWebView:wv];
}

@end

