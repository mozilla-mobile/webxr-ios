//  Constants.swift
//  XRViewer
//
//  Copyright © 2018 Mozilla. All rights reserved.

import Foundation

/// The NSUserDefaults key for the boolean that tells us whether
/// the permissions UI was already shown
let PermissionsUIAlreadyShownKey = "permissionsUIAlreadyShown"
/// The NSUserDefaults key for the boolean that tells us whether
/// the AnalyticsManager should be used
let UseAnalyticsKey = "useAnalytics"
/// The NSUserDefaults key for the string of the default home url
let HomeURLKey = "homeURL"
/// The NSUserDefaults key for the NSNumber telling us the seconds
/// the app should be in background before pausing the session
let SecondsInBackgroundKey = "secondsInBackground"
/// The default time in seconds that the app waits after leaving a
/// XR site before pausing the session
let SessionInBackgroundDefaultTimeInSeconds: Int = 60
/// The NSUserDefaults key for the NSNumber telling us the minimum
/// distance at which the anchors should be in order to be removed
/// on a page refresh
let DistantAnchorsDistanceKey = "distantAnchorsDistance"
/// The dfeault distance at which the anchors should be in order to be
/// removed on a page refresh
let DistantAnchorsDefaultDistanceInMeters: Float = 3.0
/// The NSUserDefaults key for the Date telling us when the app was
/// backgrounded or the session paused
let BackgroundOrPausedDateKey = "backgroundOrPausedDate"
/// The default time the session must be paused in order to remove the
/// anchors on the next session run
let PauseTimeInSecondsToRemoveAnchors: Double = 10.0
/// The NSUserDefaults key for the boolean that tells us whether
/// the allow world sensing dialog should be shown (globally)
let AlwaysAllowWorldSensingKey = "alwaysAllowWorldSensing"
/// The NSUserDefaults key for the boolean that tells us whether
/// the allow world sensing dialog should be shown for sites
let AllowedWorldSensingSitesKey = "allowedWorldSensingSites"
/// The NSUserDefaults key for the boolean that tells us whether
/// we should preload the webxr.js file to expose a WebXR API
let ExposeWebXRAPIKey = "exposeWebXRAPI"

@objc class Constant: NSObject {
    override private init() {}
    
    @objc static func permissionsUIAlreadyShownKey() -> String { return PermissionsUIAlreadyShownKey}
    static func useAnalyticsKey() -> String { return UseAnalyticsKey }
    @objc static func homeURLKey() -> String { return HomeURLKey }
    @objc static func secondsInBackgroundKey() -> String { return SecondsInBackgroundKey }
    @objc static func distantAnchorsDistanceKey() -> String { return DistantAnchorsDistanceKey }
    @objc static func backgroundOrPausedDateKey() -> String { return BackgroundOrPausedDateKey }
    static func sessionInBackgroundDefaultTimeInSeconds() -> Int { return SessionInBackgroundDefaultTimeInSeconds }
    static func distantAnchorsDefaultDistanceInMeters() -> Float { return DistantAnchorsDefaultDistanceInMeters }
    @objc static func pauseTimeInSecondsToRemoveAnchors() -> Double { return PauseTimeInSecondsToRemoveAnchors }
    static func alwaysAllowWorldSensingKey() -> String { return AlwaysAllowWorldSensingKey }
    static func allowedWorldSensingSitesKey() -> String { return AllowedWorldSensingSitesKey }
    static func exposeWebXRAPIKey() -> String { return ExposeWebXRAPIKey }
}
