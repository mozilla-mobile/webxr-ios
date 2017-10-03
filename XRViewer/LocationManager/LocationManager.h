#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^DidUpdateLocation)(CLLocation *);
typedef void (^DidRequestAuth)(BOOL);

@interface LocationManager : NSObject

@property(nonatomic, copy) DidUpdateLocation updateLocation;

- (void)startUpdateLocation;
- (void)stopUpdateLocation;

- (CLLocationCoordinate2D)currentCoordinate;
- (CLLocationDistance)currentAltitude;

- (void)setupForRequest:(NSDictionary *)request;
- (NSDictionary *)locationData;

- (void)requestAuthorizationWithCompletion:(DidRequestAuth)authBlock;

@end
