#import <UIKit/UIKit.h>

#define UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_MESSAGE @"The selected ARSessionConfiguration is not supported by the current device"
#define SENSOR_UNAVAILABLE_ARKIT_ERROR_MESSAGE @"A sensor required to run the session is not available"
#define SENSOR_FAILED_ARKIT_ERROR_MESSAGE @"A sensor failed to provide the required input"
#define WORLD_TRACKING_FAILED_ARKIT_ERROR_MESSAGE @"World tracking has encountered a fatal error"

#define AR_SESSION_STARTED_POPUP_TITLE @"AR Session Started"
#define AR_SESSION_STARTED_POPUP_MESSAGE @"Swipe down to show the URL bar"
#define AR_SESSION_STARTED_POPUP_TIME_IN_SECONDS 2

#define URL_TO_LOAD_AFTER_ERROR @"https://ios-viewer.webxrexperiments.com/viewer.html"

#define MEMORY_ERROR_DOMAIN     @"Memory"
#define MEMORY_ERROR_CODE       0
#define MEMORY_ERROR_MESSAGE    @"Memory warning received"

#define

@interface ViewController : UIViewController

@end
