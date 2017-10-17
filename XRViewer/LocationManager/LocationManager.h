#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^Update)(NSDictionary *);
typedef void (^Fail)(NSError *);

typedef void (^DidRequestAuth)(BOOL);

@interface LocationManager : NSObject

@property(nonatomic, copy) Update updateLocation;
@property(nonatomic, copy) Update updateHeading;
@property(nonatomic, copy) Update enterRegion;
@property(nonatomic, copy) Update exitRegion;
@property(nonatomic, copy) Fail fail;

- (NSDictionary *)addRegion:(NSDictionary *)req;
- (NSDictionary *)removeRegion:(NSDictionary *)req;
- (NSDictionary *)inRegion:(NSDictionary *)req;

- (void)setupForRequest:(NSDictionary *)request;
    
- (void)requestAuthorizationWithCompletion:(DidRequestAuth)authBlock;

@end
