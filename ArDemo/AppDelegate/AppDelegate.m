#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    return YES;
}

@end
