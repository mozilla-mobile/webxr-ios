#import "WebXR.h"

@interface WebXR ()

@property(copy) NSString *key;

@end


@implementation WebXR

+ (instancetype)sharedWebXR
{
    static WebXR *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[WebXR alloc] init];
    });
    
    return sharedInstance;
}

+ (void)initializeWithKey:(NSString *)key
{
    [[self sharedWebXR] setKey:key];
}

@end
