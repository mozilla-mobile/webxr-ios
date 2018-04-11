#import "LocationManager.h"
#import <os/lock.h>
#import "WebARKHeader.h"

@interface LocationManager() <CLLocationManagerDelegate>
{
    os_unfair_lock _lock;
}

@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, copy) NSDictionary *request;
@property (nonatomic, copy) DidRequestAuth authBlock;
@end

@implementation LocationManager

- (void)dealloc
{
    DDLogDebug(@"LocationManager dealloc");
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _lock = OS_UNFAIR_LOCK_INIT;
        
        _manager = [[CLLocationManager alloc] init];
        [_manager setDelegate:self];
    }
    
    return self;
}

- (BOOL)requestAuthorization
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        [_manager requestWhenInUseAuthorization];
        return NO;
    }
    
    return YES;
}

- (void)requestAuthorizationWithCompletion:(DidRequestAuth)authBlock
{
    [self setAuthBlock:authBlock];
    
    if ([self requestAuthorization])
    {
        if (authBlock)
        {
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
            {
                authBlock(YES);
            }
            else
            {
                authBlock(NO);
            }
        }
    }
}

- (void)startUpdateLocation
{
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        DDLogError(@"Location isn't allowed !");
        return;
    }
    
#warning LOCATION TEMP SOLUTION ( waiting for geofencing )
    [_manager requestLocation];
    
    //[_manager startUpdatingLocation];
}

- (void)stopUpdateLocation
{
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        DDLogError(@"Location isn't allowed !");
        return;
    }
    
#warning LOCATION TEMP SOLUTION ( waiting for geofencing )
    //[_manager stopUpdatingLocation];
}

- (CLLocationCoordinate2D)currentCoordinate
{
    CLLocationCoordinate2D coordinate;
    
    os_unfair_lock_lock(&(_lock));
    coordinate = [_currentLocation coordinate];
    os_unfair_lock_unlock(&(_lock));
    
    return coordinate;
}

- (CLLocationDistance)currentAltitude
{
    CLLocationDistance altitude;
    
    os_unfair_lock_lock(&(_lock));
    altitude = [_currentLocation altitude];
    os_unfair_lock_unlock(&(_lock));
    
    return altitude;
}

- (NSDictionary *)currentCoordinateDict
{
    CLLocationCoordinate2D coord = [self currentCoordinate];
    CLLocationDistance altitude = [self currentAltitude];
    
    return @{WEB_AR_LOCATION_LON_OPTION : @(coord.longitude), WEB_AR_LOCATION_LAT_OPTION : @(coord.latitude), WEB_AR_LOCATION_ALT_OPTION : @(altitude)};
}

- (void)setupForRequest:(NSDictionary *)request
{
    [self setRequest:request];
    
    if ([request[WEB_AR_LOCATION_OPTION] boolValue])
    {
        [self startUpdateLocation];
    }
    else
    {
        [self stopUpdateLocation];
    }
}

- (NSDictionary *)locationData
{
    if ([[self request][WEB_AR_LOCATION_OPTION] boolValue])
    {
        return @{WEB_AR_LOCATION_OPTION : [self currentCoordinateDict]};
    }
    
    return @{};
}

#pragma mark Location Manager

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    os_unfair_lock_lock(&(_lock));
    _currentLocation = [[locations lastObject] copy];
    os_unfair_lock_unlock(&(_lock));
    
    if ([self updateLocation])
    {
        [self updateLocation]([locations lastObject]);
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    DDLogError(@"Location error - %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DDLogDebug(@"locationManager didChangeAuthorizationStatus - %d", status);
    
    if ([self authBlock])
    {
        switch (status)
        {
            case kCLAuthorizationStatusNotDetermined:
                
                break;
            case kCLAuthorizationStatusRestricted:
            case kCLAuthorizationStatusDenied:
                [self authBlock](NO);
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self authBlock](YES);
                break;
        }
    }
}

@end

