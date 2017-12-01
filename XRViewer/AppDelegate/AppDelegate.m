#import "AppDelegate.h"
#import "AnalyticsEvents.h"
#import <Google/Analytics.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // Configure tracker from GoogleService-Info.plist
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory: CATEGORY
                                                          action: ACTION_APP_LAUNCHED
                                                           label: nil
                                                           value: nil] build]];
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    //Be ready to open URLs like "wxrv://ios-viewer.webxrexperiments.com/viewer.html"
    if ([[url scheme] isEqualToString:@"wxrv"]) {
        // Extract the scheme part of the URL
        NSString* urlString = [[url absoluteString] substringFromIndex:7];
        urlString = [NSString stringWithFormat:@"https://%@", urlString];
        
        DDLogDebug(@"WebXR-iOS viewer opened with URL: %@", urlString);
        
        [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:REQUESTED_URL_KEY];

        return YES;
    }
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory: CATEGORY
                                                          action: ACTION_APP_DID_BECOME_ACTIVE
                                                           label: nil
                                                           value: nil] build]];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory: CATEGORY
                                                          action: ACTION_APP_DID_ENTER_BACKGROUND
                                                           label: nil
                                                           value: nil] build]];
}

@end
