#import "LocationManager.h"
#import <os/lock.h>
#import "WebARKHeader.h"

@interface LocationManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, copy) NSDictionary *request;
@property (nonatomic, copy) DidRequestAuth authBlock;
    @property (nonatomic, strong) NSMutableArray *regions;
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
        _manager = [[CLLocationManager alloc] init];
        [_manager setDelegate:self];
        _regions = [NSMutableArray new];
        
        [self requestAuthorization];
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
    
    [_manager requestLocation];
    
    [_manager startUpdatingLocation];
}
    
- (void)startUpdateHeading
{
    [_manager startUpdatingHeading];
}

- (void)stopUpdateLocation
{
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        DDLogError(@"Location isn't allowed !");
        return;
    }
    
    [_manager stopUpdatingLocation];
}
    
- (void)stopUpdateHeading
{
    [_manager stopUpdatingHeading];
}
    
- (void)setupForRequest:(NSDictionary *)request
{
    [self setRequest:request[WEB_AR_LOCATION_OPTION]];
    
    if ([self request] != nil)
    {
        NSString *accuracyString = [self request][WEB_AR_LOCATION_ACCURACY_OPTION];
        if (accuracyString != nil)
        {
            [[self manager] setDesiredAccuracy:accuracyFrom(accuracyString)];
            [[self manager] setDistanceFilter:accuracyFrom(accuracyString)];
            [self startUpdateLocation];
         }
        
        NSDictionary *heading = [self request][WEB_AR_LOCATION_HEADING_OPTION];
        if (heading != nil)
        {
            NSString *headingAccuracy = heading[WEB_AR_LOCATION_ACCURACY_OPTION];
            [[self manager] setHeadingFilter:[headingAccuracy floatValue]];
            [self startUpdateHeading];
        }
    }
    else
    {
        [self stopUpdateLocation];
        [self stopUpdateHeading];
    }
}
    
- (BOOL)addRegion:(NSDictionary *)req
{
    NSDictionary *regionDict = req[WEB_AR_LOCATION_REGION_OPTION];
    
    if (regionDict == nil) {return NO;}

    NSDictionary *centerDict = regionDict[WEB_AR_LOCATION_REGION_CENTER_OPTION];
    CLLocationCoordinate2D center;
    center.longitude = [centerDict[WEB_AR_LOCATION_LON_OPTION] longLongValue];
    center.latitude = [centerDict[WEB_AR_LOCATION_LAT_OPTION] longLongValue];
    
    CLLocationDistance radius = [regionDict[WEB_AR_LOCATION_REGION_RADIUS_OPTION] longLongValue];
    NSString *identifier = regionDict[WEB_AR_ID_OPTION];
    
    if (identifier != nil && radius > 0)
    {
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:identifier];
        [_regions addObject:region];
        [_manager startMonitoringForRegion:region];
        
        return YES;
    }
    
    return NO;
}
- (BOOL)removeRegion:(NSDictionary *)req
{
    NSDictionary *regionDict = req[WEB_AR_LOCATION_REGION_OPTION];
    
    if (regionDict == nil) {return NO;}
    
    NSString *identifier = (req[WEB_AR_LOCATION_REGION_OPTION])[WEB_AR_ID_OPTION];
    
    if (identifier != nil)
    {
        CLCircularRegion *region = [self regionByID:identifier];
        
        if (region != nil)
        {
            [_manager stopMonitoringForRegion:region];
            [_regions removeObject:region];
            
            return YES;
        }
    }
    
    return NO;
}

- (CLCircularRegion *)regionByID:(NSString *)identifier
{
    for (CLCircularRegion *region in _regions)
    {
        if ([region.identifier isEqualToString:identifier])
        {
            return region;
        }
    }
    
    return  nil;
}
    
- (BOOL)inRegion:(NSDictionary *)req
{
    NSDictionary *regionDict = req[WEB_AR_LOCATION_REGION_OPTION];
    
    if (regionDict == nil) {return NO;}
    
    NSString *identifier = (req[WEB_AR_LOCATION_REGION_OPTION])[WEB_AR_ID_OPTION];
    
    if (identifier != nil)
    {
        CLCircularRegion *region = [self regionByID:identifier];
        
        CLLocationCoordinate2D coord = [[_manager location] coordinate];
        
        if ([region containsCoordinate:coord])
        {
            return YES;
        }
    }
    
    return  NO;
}

#pragma mark Location Manager

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [self updateLocation](dictFromLocation([locations lastObject]));
}
    
- (void)locationManager:(CLLocationManager *)manager
    didUpdateHeading:(nonnull CLHeading *)newHeading
{
    [self updateHeading](dictFromHeading(newHeading));
}
    
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    DDLogError(@"Location error - %@", error);
    [self fail](error);
}

- (void)locationManager:(CLLocationManager *)manager
    didEnterRegion:(nonnull CLRegion *)region
{
    [self enterRegion](dictFromRegion((CLCircularRegion *)region));
}
    
- (void)locationManager:(CLLocationManager *)manager
    didExitRegion:(nonnull CLRegion *)region
{
    [self exitRegion](dictFromRegion((CLCircularRegion *)region));
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

static NSDictionary * dictFromLocation(CLLocation *location)
{
    NSDictionary *locOption = @{WEB_AR_LOCATION_LON_OPTION : @(location.coordinate.longitude), WEB_AR_LOCATION_LAT_OPTION : @(location.coordinate.latitude), WEB_AR_LOCATION_ALT_OPTION : @(location.altitude)};
    
    return @{WEB_AR_LOCATION_OPTION: locOption};
}

static NSDictionary * dictFromHeading(CLHeading *heading)
{
    NSDictionary *headOption = @{WEB_AR_LOCATION_HEADING_TRUE_OPTION : @(heading.trueHeading), WEB_AR_LOCATION_HEADING_MAGNETIC_OPTION : @(heading.magneticHeading)};
    
    return @{WEB_AR_LOCATION_HEADING_OPTION: headOption};
}

static NSDictionary * dictFromRegion(CLCircularRegion *region)
{
    NSDictionary *center = @{WEB_AR_LOCATION_LON_OPTION : @(region.center.longitude), WEB_AR_LOCATION_LAT_OPTION : @(region.center.latitude)};
    
    NSDictionary *regionOption = @{WEB_AR_LOCATION_REGION_RADIUS_OPTION : @(region.radius),
                                   WEB_AR_LOCATION_REGION_CENTER_OPTION : center,
                                   WEB_AR_ID_OPTION : region.identifier};
    
    return @{WEB_AR_LOCATION_REGION_OPTION: regionOption};
}

static CLLocationAccuracy accuracyFrom(NSString *string)
{
    if ([string isEqualToString:WEB_AR_LOCATION_ACCURACY_BEST_NAV]) {
        return kCLLocationAccuracyBestForNavigation;
    }
    else if ([string isEqualToString:WEB_AR_LOCATION_ACCURACY_BEST]) {
        return kCLLocationAccuracyBest;
    }
    else if ([string isEqualToString:WEB_AR_LOCATION_ACCURACY_TEN]) {
        return kCLLocationAccuracyNearestTenMeters;
    }
    else if ([string isEqualToString:WEB_AR_LOCATION_ACCURACY_HUNDRED]) {
        return kCLLocationAccuracyHundredMeters;
    }
    else if ([string isEqualToString:WEB_AR_LOCATION_ACCURACY_KILO]) {
        return kCLLocationAccuracyKilometer;
    }
    else if ([string isEqualToString:WEB_AR_LOCATION_ACCURACY_THREE]) {
        return kCLLocationAccuracyThreeKilometers;
    }
    
    return -1;
}
    
@end

