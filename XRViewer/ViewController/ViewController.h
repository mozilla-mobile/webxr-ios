#import <UIKit/UIKit.h>

#define UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_MESSAGE @"The selected ARSessionConfiguration is not supported by the current device"
#define SENSOR_UNAVAILABLE_ARKIT_ERROR_MESSAGE @"A sensor required to run the session is not available"
#define SENSOR_FAILED_ARKIT_ERROR_MESSAGE @"A sensor failed to provide the required input"
#define WORLD_TRACKING_FAILED_ARKIT_ERROR_MESSAGE @"World tracking has encountered a fatal error"

@interface ViewController : UIViewController

@end
