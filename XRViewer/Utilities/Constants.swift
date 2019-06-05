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
/// The NSUserDefaults key for the Date telling us when the app last
/// started a new ARSession or .resetTracking/.removeExistingAnchors of a session
let LastResetSessionTrackingDateKey = "lastResetSessionTrackingDate"
/// The default time in seconds the app waits since the last ARSession
/// .resetTracking/.removeExistingAnchors to reset tracking on next requestSession
let ThresholdTimeInSecondsSinceLastTrackingReset: Double = 600.0
/// The NSUserDefaults key for the boolean that tells us whether
/// the user allowed minimal WebXR access (globally)
let MinimalWebXREnabledKey = "minimalWebXREnabled"
/// The NSUserDefaults key for the boolean that tells us whether
/// the allow minimal WebXR dialog should be shown for sites
let AllowedMinimalSitesKey = "allowedMinimalSites"
/// The NSUserDefaults key for the boolean that tells us whether
/// the user activated WebXR Lite Mode (globally)
let LiteModeWebXREnabledKey = "liteModeWebXREnabled"
/// The NSUserDefaults key for the boolean that tells us whether
/// the user has enabled world sensing
let WorldSensingWebXREnabledKey = "worldSensingWebXREnabled"
/// The NSUserDefaults key for the boolean that tells us whether
/// the allow world sensing dialog should be shown for sites
let AllowedWorldSensingSitesKey = "allowedWorldSensingSites"
/// The NSUserDefaults key for the boolean that tells us whether
/// the allow world sensing dialog should be shown (globally)
let AlwaysAllowWorldSensingKey = "alwaysAllowWorldSensing"
/// The NSUserDefaults key for the boolean that tells us whether
/// the user has enabled video camera access
let VideoCameraAccessWebXREnabledKey = "videoCameraAccessWebXREnabled"
/// The NSUserDefaults key for the boolean that tells us whether
/// the site has been approved to always allow video camera access
let AllowedVideoCameraSitesKey = "allowedVideoCameraSites"
/// The NSUserDefaults key for the boolean that tells us whether
/// we should preload the webxr.js file to expose a WebXR API
let ExposeWebXRAPIKey = "exposeWebXRAPI"
let BOX_SIZE: CGFloat = 0.05

@objc class Constant: NSObject {
    override private init() {}
    
    @objc static func permissionsUIAlreadyShownKey() -> String { return PermissionsUIAlreadyShownKey}
    static func useAnalyticsKey() -> String { return UseAnalyticsKey }
    @objc static func homeURLKey() -> String { return HomeURLKey }
    @objc static func secondsInBackgroundKey() -> String { return SecondsInBackgroundKey }
    @objc static func distantAnchorsDistanceKey() -> String { return DistantAnchorsDistanceKey }
    @objc static func backgroundOrPausedDateKey() -> String { return BackgroundOrPausedDateKey }
    static func lastResetSessionTrackingDateKey() -> String { return LastResetSessionTrackingDateKey }
    static func thresholdTimeInSecondsSinceLastTrackingReset() -> Double { return ThresholdTimeInSecondsSinceLastTrackingReset }
    static func sessionInBackgroundDefaultTimeInSeconds() -> Int { return SessionInBackgroundDefaultTimeInSeconds }
    static func distantAnchorsDefaultDistanceInMeters() -> Float { return DistantAnchorsDefaultDistanceInMeters }
    @objc static func pauseTimeInSecondsToRemoveAnchors() -> Double { return PauseTimeInSecondsToRemoveAnchors }
    static func minimalWebXREnabled() -> String { return MinimalWebXREnabledKey }
    static func allowedMinimalSitesKey() -> String { return AllowedMinimalSitesKey }
    static func liteModeWebXREnabled() -> String { return LiteModeWebXREnabledKey }
    static func worldSensingWebXREnabled() -> String { return WorldSensingWebXREnabledKey }
    static func allowedWorldSensingSitesKey() -> String { return AllowedWorldSensingSitesKey }
    static func alwaysAllowWorldSensingKey() -> String { return AlwaysAllowWorldSensingKey }
    static func videoCameraAccessWebXREnabled() -> String { return VideoCameraAccessWebXREnabledKey }
    static func allowedVideoCameraSitesKey() -> String { return AllowedVideoCameraSitesKey }
    static func exposeWebXRAPIKey() -> String { return ExposeWebXRAPIKey }
    
    @objc static func swipeGestureAreaHeight() -> CGFloat { return 200 }
    @objc static func recordSize() -> CGFloat { return 60.5 }
    @objc static func recordOffsetX() -> CGFloat { return 25.5 }
    @objc static func recordOffsetY() -> CGFloat { return 25.5 }
    @objc static func micSizeW() -> CGFloat { return 27.75 }
    @objc static func micSizeH() -> CGFloat { return 27.75 }
    @objc static func urlBarHeight() -> CGFloat { return 49 }
    @objc static func urlBarAnimationTimeInSeconds() -> TimeInterval { return 0.2 }
    @objc static func boxSize() -> CGFloat { return BOX_SIZE }
}

// Old WebARKHeader.h Constants

// CODES
let INTERNET_OFFLINE_CODE = -1009
let USER_CANCELLED_LOADING_CODE = -999

// URL
let WEB_URL = "https://webxr-ios.webxrexperiments.com/splash.html"
let LAST_URL_KEY = "lastURL"

// MESSAGES
let WEB_AR_INIT_MESSAGE = "initAR"
let WEB_AR_START_WATCH_MESSAGE = "watchAR"
let WEB_AR_REQUEST_MESSAGE = "requestSession"
let WEB_AR_STOP_WATCH_MESSAGE = "stopAR"
let WEB_AR_LOAD_URL_MESSAGE = "loadUrl"
let WEB_AR_SET_UI_MESSAGE = "setUIOptions"
let WEB_AR_HIT_TEST_MESSAGE = "hitTest"
let WEB_AR_ADD_ANCHOR_MESSAGE = "addAnchor"
let WEB_AR_REMOVE_ANCHORS_MESSAGE = "removeAnchors"
let WEB_AR_ADD_IMAGE_ANCHOR_MESSAGE = "addImageAnchor"
let WEB_AR_TRACKED_IMAGES_MESSAGE = "setNumberOfTrackedImages"
let WEB_AR_CREATE_IMAGE_ANCHOR_MESSAGE = "createImageAnchor"
let WEB_AR_ACTIVATE_DETECTION_IMAGE_MESSAGE = "activateDetectionImage"
let WEB_AR_DEACTIVATE_DETECTION_IMAGE_MESSAGE = "deactivateDetectionImage"
let WEB_AR_DESTROY_DETECTION_IMAGE_MESSAGE = "destroyDetectionImage"
let WEB_AR_REQUEST_CV_DATA_MESSAGE = "requestComputerVisionData"
let WEB_AR_START_SENDING_CV_DATA_MESSAGE = "startSendingComputerVisionData"
let WEB_AR_STOP_SENDING_CV_DATA_MESSAGE = "stopSendingComputerVisionData"
let WEB_AR_ADD_IMAGE_ANCHOR = "addImageAnchor"
let WEB_AR_GET_WORLD_MAP_MESSAGE = "getWorldMap"
let WEB_AR_SET_WORLD_MAP_MESSAGE = "setWorldMap"
let WEB_AR_ON_JS_UPDATE_MESSAGE = "onUpdate"
let WEB_AR_IOS_SHOW_DEBUG = "arkitShowDebug"
let WEB_AR_IOS_START_RECORDING_MESSAGE = "arkitStartRecording"
let WEB_AR_IOS_STOP_RECORDING_MESSAGE = "arkitStopRecording"
let WEB_AR_IOS_DID_MOVE_BACK_MESSAGE = "arkitDidMoveBackground"
let WEB_AR_IOS_WILL_ENTER_FOR_MESSAGE = "arkitWillEnterForeground"
let WEB_AR_IOS_WAS_INTERRUPTED_MESSAGE = "arkitInterrupted"
let WEB_AR_IOS_INTERRUPTION_ENDED_MESSAGE = "arkitInterruptionEnded"
let WEB_AR_IOS_TRACKING_STATE_MESSAGE = "arTrackingChanged"
let WEB_AR_WORLDMAPPING_STATUS_MESSAGE = "worldMappingStatus"
let WEB_AR_IOS_DID_RECEIVE_MEMORY_WARNING_MESSAGE = "ios_did_receive_memory_warning"
let WEB_AR_IOS_USER_GRANTED_CV_DATA = "userGrantedComputerVisionData"
let WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA = "userGrantedWorldSensingData"

// This message is not being used by the polyfill
// #define WEB_AR_IOS_VIEW_WILL_TRANSITION_TO_SIZE_MESSAGE   @"ios_view_will_transition_to_size"

let WEB_AR_IOS_WINDOW_RESIZE_MESSAGE = "arkitWindowResize"
let WEB_AR_IOS_ERROR_MESSAGE = "onError"
let WEB_AR_IOS_SIZE_WIDTH_PARAMETER = "width"
let WEB_AR_IOS_SIZE_HEIGHT_PARAMETER = "height"
let WEB_AR_IOS_ERROR_DOMAIN_PARAMETER = "domain"
let WEB_AR_IOS_ERROR_CODE_PARAMETER = "code"
let WEB_AR_IOS_ERROR_MESSAGE_PARAMETER = "message"

// OPTIONS
let WEB_AR_CALLBACK_OPTION = "callback"
let WEB_AR_DATA_CALLBACK_OPTION = "data_callback"

let WEB_AR_REQUEST_OPTION = "options"
let WEB_AR_UI_OPTION = "ui"
let WEB_AR_UI_BROWSER_OPTION = "browser"
let WEB_AR_UI_POINTS_OPTION = "points"
let WEB_AR_UI_DEBUG_OPTION = "debug"
let WEB_AR_UI_FOCUS_OPTION = "focus"
let WEB_AR_UI_CAMERA_OPTION = "rec"
let WEB_AR_UI_CAMERA_TIME_OPTION = "rec_time"
let WEB_AR_UI_MIC_OPTION = "mic"
let WEB_AR_UI_BUILD_OPTION = "build"
let WEB_AR_UI_STATISTICS_OPTION = "statistics"
let WEB_AR_UI_PLANE_OPTION = "plane"
let WEB_AR_UI_WARNINGS_OPTION = "warnings"
let WEB_AR_UI_ANCHORS_OPTION = "anchors"
let WEB_AR_ANCHOR_TYPE = "type"
let WEB_AR_ANCHOR_TRANSFORM_OPTION = "anchor_transform"
let WEB_AR_ANCHOR_CENTER_OPTION = "anchor_center"
let WEB_AR_ANCHOR_EXTENT_OPTION = "anchor_extent"
let WEB_AR_TEST_OPTION = "test"
let WEB_AR_SHOW_UI_OPTION = "show"
let WEB_AR_URL_OPTION = "url"
let WEB_AR_JS_FRAME_RATE_OPTION = "js_frame_rate"
let WEB_AR_LOCATION_OPTION = "location"
let WEB_AR_LOCATION_LON_OPTION = "longitude"
let WEB_AR_LOCATION_LAT_OPTION = "latitude"
let WEB_AR_LOCATION_ALT_OPTION = "altitude"
let WEB_IOS_SCREEN_SIZE_OPTION = "screenSize"
let WEB_IOS_SCREEN_SCALE_OPTION = "screenScale"
let WEB_IOS_SYSTEM_VERSION_OPTION = "systemVersion"
let WEB_IOS_IS_IPAD_OPTION = "isIpad"
let WEB_IOS_DEVICE_UUID_OPTION = "deviceUUID"
let WEB_AR_PLANE_OPTION = "plane"
let WEB_AR_PLANE_CENTER_OPTION = "plane_center"
let WEB_AR_PLANE_EXTENT_OPTION = "plane_extent"
let WEB_AR_PLANE_ALIGNMENT_OPTION = "plane_alignment"
let WEB_AR_PLANE_ID_OPTION = "plane_id"
let WEB_AR_GEOMETRY_OPTION = "geometry"
let WEB_AR_BLEND_SHAPES_OPTION = "blendShapes"
let WEB_AR_SHOW_PLANE_OPTION = "show_plane"
let WEB_AR_IMAGE_NAME_OPTION = "image_name"
let WEB_AR_HIT_TEST_RESULT_OPTION = "hit_test_result"
let WEB_AR_HIT_TEST_PLANE_OPTION = "hit_test_plane"
let WEB_AR_HIT_TEST_POINTS_OPTION = "hit_test_points"
let WEB_AR_HIT_TEST_ALL_OPTION = "hit_test_all"
let WEB_AR_3D_OBJECTS_OPTION = "objects"
let WEB_AR_3D_REMOVED_OBJECTS_OPTION = "removedObjects"
let WEB_AR_3D_NEW_OBJECTS_OPTION = "newObjects"
let WEB_AR_3D_GEOALIGNED_OPTION = "geoaligned"
let WEB_AR_3D_VIDEO_ACCESS_OPTION = "videoAccess"
let WEB_AR_CV_INFORMATION_OPTION = "computer_vision_data"
let WEB_AR_WORLD_SENSING_DATA_OPTION = "worldSensing"
let WEB_AR_TYPE_OPTION = "type"
let WEB_AR_POSITION_OPTION = "position"
let WEB_AR_NUMBER_OF_TRACKED_IMAGES_OPTION = "numberOfTrackedImages"
let WEB_AR_GEOMETRY_ARRAYS = "geometry_arrays"
let WEB_AR_X_POSITION_OPTION = "x"
let WEB_AR_Y_POSITION_OPTION = "y"
let WEB_AR_Z_POSITION_OPTION = "z"
let WEB_AR_TRANSFORM_OPTION = "transform"
let WEB_AR_W_TRANSFORM_OPTION = "world_transform"
let WEB_AR_L_TRANSFORM_OPTION = "local_transform"
let WEB_AR_DISTANCE_OPTION = "distance"
let WEB_AR_ELEMENTS_OPTION = "elements"
let WEB_AR_UUID_OPTION = "uuid"
let WEB_AR_MUST_SEND_OPTION = "mustSend"
let WEB_AR_LIGHT_OBJECT_OPTION = "light"
let WEB_AR_LIGHT_INTENSITY_OPTION = "light_intensity"
let WEB_AR_LIGHT_AMBIENT_OPTION = "light_ambient"
let WEB_AR_PRIMARY_LIGHT_DIRECTION_OPTION = "primary_light_direction"
let WEB_AR_PRIMARY_LIGHT_INTENSITY_OPTION = "primary_light_intensity"
let WEB_AR_LIGHT_AMBIENT_COLOR_TEMPERATURE_OPTION = "ambient_color_temperature"
let WEB_AR_WORLD_ALIGNMENT = "alignEUS"
let WEB_AR_CAMERA_OPTION = "camera"
let WEB_AR_PROJ_CAMERA_OPTION = "projection_camera"
let WEB_AR_CAMERA_TRANSFORM_OPTION = "camera_transform"
let WEB_AR_CAMERA_VIEW_OPTION = "camera_view"
let WEB_AR_WORLDMAPPING_NOT_AVAILABLE = "ar_worldmapping_not_available"
let WEB_AR_WORLDMAPPING_LIMITED = "ar_worldmapping_limited"
let WEB_AR_WORLDMAPPING_EXTENDING = "ar_worldmapping_extending"
let WEB_AR_WORLDMAPPING_MAPPED = "ar_worldmapping_mapped"
let WEB_AR_TRACKING_STATE_NORMAL = "ar_tracking_normal"
let WEB_AR_TRACKING_STATE_LIMITED = "ar_tracking_limited"
let WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING = "ar_tracking_limited_initializing"
let WEB_AR_TRACKING_STATE_LIMITED_MOTION = "ar_tracking_limited_excessive_motion"
let WEB_AR_TRACKING_STATE_LIMITED_FEATURES = "ar_tracking_limited_insufficient_features"
let WEB_AR_TRACKING_STATE_NOT_AVAILABLE = "ar_tracking_not_available"
let WEB_AR_TRACKING_STATE_RELOCALIZING = "ar_tracking_relocalizing"
let WEB_AR_DETECTION_IMAGE_NAME_OPTION = "uid"
let AR_CAMERA_PROJECTION_MATRIX_Z_NEAR = 0.001
let AR_CAMERA_PROJECTION_MATRIX_Z_FAR = 1000.0

// Old ViewController.h Constants

let UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_MESSAGE = "The selected ARSessionConfiguration is not supported by the current device"
let SENSOR_UNAVAILABLE_ARKIT_ERROR_MESSAGE = "A sensor required to run the session is not available"
let SENSOR_FAILED_ARKIT_ERROR_MESSAGE = "A sensor failed to provide the required input.\nWe will try to restart the session using a Gravity World Alignment"
let WORLD_TRACKING_FAILED_ARKIT_ERROR_MESSAGE = "World tracking has encountered a fatal error"

let AR_SESSION_STARTED_POPUP_TITLE = "AR Session Started"
let AR_SESSION_STARTED_POPUP_MESSAGE = "Swipe down to show the URL bar"
let AR_SESSION_STARTED_POPUP_TIME_IN_SECONDS = 2

let MEMORY_ERROR_DOMAIN = "Memory"
let MEMORY_ERROR_CODE = 0
let MEMORY_ERROR_MESSAGE = "Memory warning received"
let WAITING_TIME_ON_MEMORY_WARNING = 0.5
