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
    
- (void)loadURL:(NSString *)theUrl
{
    NSURL *url = [NSURL URLWithString:theUrl];
    
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
    
- (void)showBar:(BOOL)showBar
{
    CGRect rect = [[self barView] bounds];
    rect.origin.y = showBar ? 0 : 0 - [[self barView] bounds].size.height;
    
    [[self animator] animate:[self barView] toFrame:rect];
}

- (void)reload
{
    NSString *url = [[[self barView] urlFieldText] length] > 0 ? [[self barView] urlFieldText] : [self lastURL];
    [self loadURL:url];
}
    
- (void)clean
{
    [self cleanWebContent];
    
    [[self webView] stopLoading];
    
    [[[self webView] configuration] setProcessPool:[WKProcessPool new]];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)setupForApp:(Application)app
{
    dispatch_async(dispatch_get_main_queue(), ^
       {
           CGRect rect = [[[self webView] superview] bounds];
           
           UIColor *backColor;
           
           if (app == Trivial)
           {
               rect.origin.y += [[self barView] bounds].size.height;
               backColor = [UIColor whiteColor];
           }
           else
           {
               backColor = [UIColor clearColor];
           }
           
           [[self animator] animate:[self webView] toFrame:rect];
           
           [[[self webView] superview] setBackgroundColor:backColor];
           
           [[self animator] animate:[[self webView] superview] toColor:backColor];
       });
}
    
// xr
- (void)showDebug:(BOOL)showDebug
{
    [self callWebMethod:WEB_AR_SHOW_DEBUG_MESSAGE paramJSON:@{WEB_AR_UI_DEBUG_OPTION : (showDebug ? @YES : @NO)} webCompletion:debugCompletion(WEB_AR_SHOW_DEBUG_MESSAGE)];
}
    
- (void)didBackgroundAction:(BOOL)background
{
    NSString *message = background ? WEB_AR_MOVE_BACKGROUND_MESSAGE : WEB_AR_ENTER_FOREGROUND_MESSAGE;
    
    [self callWebMethod:message param:@"" webCompletion:debugCompletion(message)];
}
    
- (void)didReceiveMemoryWarning
{
    [self callWebMethod:WEB_AR_MEMORY_WARNING_MESSAGE param:@"" webCompletion:debugCompletion(WEB_AR_TRACKING_CHANGED_MESSAGE)];
}
    
- (void)viewWillTransitionToSize:(CGSize)size
{
    [self layout];
    
    [self callWebMethod:WEB_AR_TRANSITION_TO_SIZE_MESSAGE
                  param:NSStringFromCGSize(size)
          webCompletion:debugCompletion(WEB_AR_TRANSITION_TO_SIZE_MESSAGE)];
}
    
- (void)didRegion:(NSDictionary *)param enter:(BOOL)enter;
{
    NSString *message = enter ? WEB_AR_ENTER_REGION_MESSAGE : WEB_AR_EXIT_REGION_MESSAGE;
    
    [self callWebMethod:message paramJSON:param webCompletion:debugCompletion(message)];
}
    
- (void)didUpdateHeading:(NSDictionary *)dict
{
    [self callWebMethod:WEB_AR_UPDATE_HEADING_MESSAGE paramJSON:dict webCompletion:debugCompletion(WEB_AR_UPDATE_HEADING_MESSAGE)];
}
    
- (void)didUpdateLocation:(NSDictionary *)dict
{
    [self callWebMethod:WEB_AR_UPDATE_LOCATION_MESSAGE paramJSON:dict webCompletion:debugCompletion(WEB_AR_UPDATE_LOCATION_MESSAGE)];
}
    
- (void)wasARInterruption:(BOOL)interruption
{
    NSString *message = interruption ? WEB_AR_INTERRUPTION_MESSAGE : WEB_AR_INTERRUPTION_ENDED_MESSAGE;
    
    [self callWebMethod:message param:@"" webCompletion:debugCompletion(message)];
}

- (void)didChangeARTrackingState:(NSString *)state
{
    [self callWebMethod:WEB_AR_TRACKING_CHANGED_MESSAGE param:state webCompletion:debugCompletion(WEB_AR_TRACKING_CHANGED_MESSAGE)];
}
    
- (void)didSessionFails
{
    [self callWebMethod:WEB_AR_SESSION_FAILS_MESSAGE param:@"" webCompletion:debugCompletion(WEB_AR_SESSION_FAILS_MESSAGE)];
}
    
- (void)didUpdateAnchors:(NSDictionary *)dict
{
    [self callWebMethod:WEB_AR_UPDATED_ANCHORS_MESSAGE paramJSON:dict webCompletion:debugCompletion(WEB_AR_UPDATED_ANCHORS_MESSAGE)];
}
    
- (void)didAddPlanes:(NSDictionary *)dict
{
    [self callWebMethod:WEB_AR_ADD_PLANES_MESSAGE paramJSON:dict webCompletion:debugCompletion(WEB_AR_ADD_PLANES_MESSAGE)];
}
    
- (void)didRemovePlanes:(NSDictionary *)dict
{
    [self callWebMethod:WEB_AR_REMOVE_PLANES_MESSAGE paramJSON:dict webCompletion:debugCompletion(WEB_AR_REMOVE_PLANES_MESSAGE)];
}
    
- (void)startRecording:(BOOL)start
{
    NSString *message = start ? WEB_AR_START_RECORDING_MESSAGE : WEB_AR_STOP_RECORDING_MESSAGE;
    
    [self callWebMethod:message param:@"" webCompletion:debugCompletion(message)];
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

#pragma mark WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    DDLogDebug(@"Received message: %@ , body: %@", [message name], [message body]);
    
    __weak typeof (self) blockSelf = self;
    
    if ([[message name] isEqualToString:WEB_JS_INIT_MESSAGE])
    {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        CGSize viewportSize = self.webView.frame.size;
        NSDictionary *params = @{ WEB_IOS_DEVICE_UUID_OPTION : [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                  WEB_IOS_IS_IPAD_OPTION : @([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad),
                                  WEB_IOS_SYSTEM_VERSION_OPTION : [[UIDevice currentDevice] systemVersion],
                                  WEB_IOS_SCREEN_SCALE_OPTION : @([[UIScreen mainScreen] nativeScale]),
                                  WEB_IOS_VIEWPORT_SIZE_OPTION : @{ WEB_IOS_WIDTH_OPTION : @(viewportSize.width),
                                                                  WEB_IOS_HEIGHT_OPTION : @(viewportSize.height) },
                                  WEB_IOS_SCREEN_SIZE_OPTION : @{ WEB_IOS_WIDTH_OPTION : @(screenSize.width),
                                                                WEB_IOS_HEIGHT_OPTION : @(screenSize.height)}};
        
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
    else if ([[message name] isEqualToString:WEB_JS_LOAD_URL_MESSAGE])
    {
        [self onLoadURL]([[message body] objectForKey:WEB_AR_URL_OPTION]);
    }
    else if ([[message name] isEqualToString:WEB_JS_START_WATCH_MESSAGE])
    {
        [self setTransferCallback:[[message body] objectForKey:WEB_AR_CALLBACK_OPTION]];
        
        [self onWatch]([[message body] objectForKey:WEB_AR_REQUEST_OPTION]);
    }
    else if ([[message name] isEqualToString:WEB_JS_STOP_WATCH_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        
        [self setTransferCallback:nil];
        
        [self onWatch](nil);
                
        [self callWebMethod:callback param:@"" webCompletion:NULL];
    }
    else if ([[message name] isEqualToString:WEB_JS_SET_UI_MESSAGE])
    {
        [self onSetUI]([[message body] objectForKey:WEB_AR_REQUEST_OPTION]);
    }
    else if ([[message name] isEqualToString:WEB_JS_HIT_TEST_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onHitTest]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                         {
                             [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_HIT_TEST_MESSAGE)];
                         });
    }
    else if ([[message name] isEqualToString:WEB_JS_ADD_ANCHOR_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onAddAnchor]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                         {
                             [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_ADD_ANCHOR_MESSAGE)];
                         });
    }
    else if ([[message name] isEqualToString:WEB_JS_REMOVE_ANCHOR_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onRemoveAnchor]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                           {
                               [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_REMOVE_ANCHOR_MESSAGE)];
                           });
    }
    else if ([[message name] isEqualToString:WEB_JS_UPDATE_ANCHOR_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onUpdateAnchor]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                              {
                                  [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_UPDATE_ANCHOR_MESSAGE)];
                              });
    }
    else if ([[message name] isEqualToString:WEB_JS_START_HOLD_ANCHOR_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onStartHold]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                              {
                                  [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_START_HOLD_ANCHOR_MESSAGE)];
                              });
    }
    else if ([[message name] isEqualToString:WEB_JS_STOP_HOLD_ANCHOR_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onStopHold]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                           {
                               [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_STOP_HOLD_ANCHOR_MESSAGE)];
                           });
    }
    else if ([[message name] isEqualToString:WEB_JS_ADD_REGION_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onAddRegion]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                          {
                              [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_ADD_REGION_MESSAGE)];
                          });
    }
    else if ([[message name] isEqualToString:WEB_JS_REMOVE_REGION_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onRemoveRegion]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                           {
                               [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_REMOVE_REGION_MESSAGE)];
                           });
    }
    else if ([[message name] isEqualToString:WEB_JS_IN_REGION_MESSAGE])
    {
        NSString *callback = [[message body] objectForKey:WEB_AR_CALLBACK_OPTION];
        [self onInRegion]([[message body] objectForKey:WEB_AR_REQUEST_OPTION], ^(NSDictionary *results)
                              {
                                  [blockSelf callWebMethod:callback paramJSON:results webCompletion:debugCompletion(WEB_JS_IN_REGION_MESSAGE)];
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
    return
    (([error code] > SERVER_STOP_CODE) || ([error code] < SERVER_START_CODE)) &&
    ([error code] != CANCELLED_CODE);
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
    for(NSString *message in jsMessages())
    {
        [[self contentController] addScriptMessageHandler:self name:message];
    }
}

- (void)cleanWebContent
{
    for(NSString *message in jsMessages())
    {
        [[self contentController] removeScriptMessageHandlerForName:message];
    }
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

