import CoreLocation
import Foundation
import os
import XCGLogger

typealias DidUpdateLocation = (CLLocation?) -> Void
typealias DidRequestAuth = (Bool) -> Void

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private var manager: CLLocationManager
    private var currentLocation: CLLocation?
    private var request: [AnyHashable : Any] = [:]
    private var authBlock: DidRequestAuth?
    var updateLocation: DidUpdateLocation?
    private var lock: os_unfair_lock
    
    override init() {
        lock = os_unfair_lock()
        manager = CLLocationManager()
        
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = kCLHeadingFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        
        manager.delegate = self
    }
    
    deinit {
        appDelegate().logger.debug("LocationManager dealloc")
    }

    func startUpdateLocation() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            appDelegate().logger.error("Location isn't allowed !")
            return
        }

        manager.startUpdatingLocation()
    }

    func stopUpdateLocation() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            appDelegate().logger.error("Location isn't allowed !")
            return
        }
        manager.stopUpdatingLocation()
    }

    func startUpdateHeading() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            appDelegate().logger.error("Location isn't allowed !")
            return
        }
        
        manager.startUpdatingHeading()
    }
    
    func stopUpdateHeading() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            appDelegate().logger.error("Location isn't allowed !")
            return
        }
        manager.stopUpdatingHeading()
    }

    func currentCoordinate() -> CLLocationCoordinate2D {
        var coordinate = CLLocationCoordinate2D()

        os_unfair_lock_lock(&(lock))
        if let aCoordinate = currentLocation?.coordinate {
            coordinate = aCoordinate
        }
        os_unfair_lock_unlock(&(lock))

        return coordinate
    }

    func currentAltitude() -> CLLocationDistance {
        var altitude: CLLocationDistance

        os_unfair_lock_lock(&(lock))
        altitude = currentLocation?.altitude ?? 0
        os_unfair_lock_unlock(&(lock))

        return altitude
    }

    func setup(forRequest request: [AnyHashable : Any]?) {
        guard let request = request else { return }
        self.request = request

        guard let locationOption = request[WEB_AR_LOCATION_OPTION] as? Bool else { return }
        if locationOption {
            startUpdateLocation()
        } else {
            stopUpdateLocation()
        }
        
        guard let orientationOptions = request[WEB_AR_WORLD_ALIGNMENT] as? Bool else {return}
        if orientationOptions {
            startUpdateHeading()
        } else {
            stopUpdateHeading()
        }
    }

    func locationData() -> [AnyHashable : Any]? {
        guard let locationOption = self.request[WEB_AR_LOCATION_OPTION] as? Bool else { return [:] }
        if locationOption {
            if let aDict = currentCoordinateDict() {
                return [WEB_AR_LOCATION_OPTION: aDict]
            }
            return [:]
        }
        return [:]
    }

    func requestAuthorization(withCompletion authBlock: @escaping DidRequestAuth) {
        self.authBlock = authBlock

        if requestAuthorization() {
            //if authBlock

            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                authBlock(true)
            } else {
                authBlock(false)
            }
        }
    }

    func requestAuthorization() -> Bool {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return false
        }

        return true
    }

    func currentCoordinateDict() -> [AnyHashable : Any]? {
        let coord: CLLocationCoordinate2D = currentCoordinate()
        let altitude: CLLocationDistance = currentAltitude()

        return [WEB_AR_LOCATION_LON_OPTION: coord.longitude, WEB_AR_LOCATION_LAT_OPTION: coord.latitude, WEB_AR_LOCATION_ALT_OPTION: altitude]
    }

// MARK: Location Manager

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        os_unfair_lock_lock(&(lock))
        currentLocation = locations.last
        os_unfair_lock_unlock(&(lock))
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    }
    
    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        appDelegate().logger.error("Location error - \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        appDelegate().logger.debug("locationManager didChangeAuthorizationStatus - \(status)")

        //if authBlock

        switch status {
            case .notDetermined:
                break
            case .restricted, .denied:
                authBlock?(false)
            case .authorizedAlways, .authorizedWhenInUse:
                authBlock?(true)
            default:
                break
        }
    }
}
