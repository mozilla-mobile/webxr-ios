#import "AnalyticsManager.h"
#import <Google/Analytics.h>

@implementation AnalyticsManager {

}

- (void)initialize {
    // Configure tracker from GoogleService-Info.plist
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
}

+ (AnalyticsManager *)shared {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)sendEventWithAction:(NSString *)actionName {
    BOOL useAnalytics = [[NSUserDefaults standardUserDefaults] boolForKey:USE_ANALYTICS_KEY];
    if (useAnalytics) {
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory: CATEGORY
                                                                                            action: actionName
                                                                                             label: nil
                                                                                             value: nil] build]];
    }
}
@end
