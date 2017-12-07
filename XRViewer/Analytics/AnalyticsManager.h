#import <Foundation/Foundation.h>
#import "AnalyticsEvents.h"

#define USE_ANALYTICS_KEY @"useAnalytics"

/// Analytics manager is a Google Analytics based event analytics manager
@interface AnalyticsManager : NSObject

/// Singleton implementation
/// @return The only instance of the AnalyticsManager
+(AnalyticsManager*)shared;

/// Initializes the Google Analytics tracker
- (void)initialize;

/// Sends an event to the analytics dashboard
/// @param actionName The name of the action of the event to send
- (void)sendEventWithAction:(NSString *)actionName;
@end
