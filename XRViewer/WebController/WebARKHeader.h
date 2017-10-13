#ifndef WebARKHeader_h
#define WebARKHeader_h

#import "AppState.h"

#define INTERNET_OFFLINE_CODE -1009

// URL
#define WEB_URL @"https://mozilla.github.io/webxr-ios/app/"

// MESSAGES
#define WEB_AR_INIT_MESSAGE            @"initAR"
#define WEB_AR_START_WATCH_MESSAGE     @"watchAR"
#define WEB_AR_STOP_WATCH_MESSAGE      @"stopAR"
#define WEB_AR_LOAD_URL_MESSAGE        @"loadUrl"
#define WEB_AR_SET_UI_MESSAGE          @"setUIOptions"
#define WEB_AR_HIT_TEST_MESSAGE        @"hitTest"
#define WEB_AR_ADD_ANCHOR_MESSAGE      @"addAnchor"

#define WEB_AR_ON_JS_UPDATE_MESSAGE    @"onUpdate" // reques from JS

#define WEB_AR_IOS_SHOW_DEBUG          @"arkitShowDebug"

#define WEB_AR_IOS_START_RECORDING_MESSAGE @"arkitStartRecording"
#define WEB_AR_IOS_STOP_RECORDING_MESSAGE  @"arkitStopRecording"

#define WEB_AR_IOS_DID_MOVE_BACK_MESSAGE   @"arkitDidMoveBackground"
#define WEB_AR_IOS_WILL_ENTER_FOR_MESSAGE  @"arkitWillEnterForeground"

#define WEB_AR_IOS_WAS_INTERRUPTED_MESSAGE     @"arkitInterrupted"
#define WEB_AR_IOS_INTERRUPTION_ENDED_MESSAGE  @"arkitInterruptionEnded"

#define WEB_AR_IOS_TRACKING_STATE_MESSAGE       @"ar_tracking_changed"

#define WEB_AR_IOS_DID_RECEIVE_MEMORY_WARNING_MESSAGE   @"ios_did_receive_memory_warning"

#define WEB_AR_IOS_WIEW_WILL_TRANSITION_TO_SIZE_MESSAGE   @"ios_view_will_transition_to_size"

// OPTIONS
#define WEB_AR_CALLBACK_OPTION         @"callback"
#define WEB_AR_REQUEST_OPTION          @"options"
#define WEB_AR_UI_OPTION               @"ui"
#define WEB_AR_UI_BROWSER_OPTION       @"browser"
#define WEB_AR_UI_POINTS_OPTION        @"points"
#define WEB_AR_UI_DEBUG_OPTION         @"debug"
#define WEB_AR_UI_FOCUS_OPTION         @"focus"
#define WEB_AR_UI_CAMERA_OPTION        @"rec"
#define WEB_AR_UI_CAMERA_TIME_OPTION   @"rec_time"
#define WEB_AR_UI_MIC_OPTION           @"mic"
#define WEB_AR_UI_BUILD_OPTION         @"build"
#define WEB_AR_UI_STATISTICS_OPTION    @"statistics"
#define WEB_AR_UI_PLANE_OPTION         @"plane"
#define WEB_AR_UI_WARNINIGS_OPTION     @"warnings"
#define WEB_AR_UI_ANCHORS_OPTION       @"anchors"

#define WEB_AR_ANCHOR_TRANSFORM_OPTION @"anchor_transform"
#define WEB_AR_ANCHOR_CENTER_OPTION    @"anchor_center"
#define WEB_AR_ANCHOR_EXTENT_OPTION    @"anchor_extent"

#define WEB_AR_TEST_OPTION             @"test"
#define WEB_AR_ID_OPTION               @"id"
#define WEB_AR_SHOW_UI_OPTION          @"show"
#define WEB_AR_URL_OPTION              @"url"
#define WEB_AR_JS_FRAME_RATE_OPTION    @"js_frame_rate" // bool

#define WEB_AR_LOCATION_OPTION            @"location"
#define WEB_AR_LOCATION_LON_OPTION        @"longitude"
#define WEB_AR_LOCATION_LAT_OPTION        @"latitude"
#define WEB_AR_LOCATION_ALT_OPTION        @"altitude"
#define WEB_AR_LOCATION_ACCURACY_OPTION   @"accuracy"
#define WEB_AR_LOCATION_ACCURACY_BEST_NAV @"BestForNavigation"
#define WEB_AR_LOCATION_ACCURACY_BEST     @"Best"
#define WEB_AR_LOCATION_ACCURACY_TEN      @"NearestTenMeters"
#define WEB_AR_LOCATION_ACCURACY_HUNDRED  @"HundredMeters"
#define WEB_AR_LOCATION_ACCURACY_KILO     @"Kilometer"
#define WEB_AR_LOCATION_ACCURACY_THREE    @"ThreeKilometers"

#define WEB_AR_LOCATION_HEADING_OPTION          @"heading"
#define WEB_AR_LOCATION_HEADING_MAGNETIC_OPTION @"magnetic"
#define WEB_AR_LOCATION_HEADING_TRUE_OPTION     @"theTrue"
#define WEB_AR_LOCATION_REGION_OPTION           @"region"
#define WEB_AR_LOCATION_REGION_RADIUS_OPTION    @"radius"
#define WEB_AR_LOCATION_REGION_CENTER_OPTION    @"center"

#define WEB_IOS_SCREEN_SIZE_OPTION     @"screenSize"
#define WEB_IOS_SCREEN_SCALE_OPTION    @"screenScale"
#define WEB_IOS_SYSTEM_VERSION_OPTION  @"systemVersion"
#define WEB_IOS_IS_IPAD_OPTION         @"isIpad"
#define WEB_IOS_DEVICE_UUID_OPTION     @"deviceUUID"


#define WEB_AR_ANCHORS_OPTION       @"anchors"

#define WEB_AR_ERROR_CODE  @"error"

#define WEB_AR_TRANSFORM_COLUMN_V0_OPTION @"v0"
#define WEB_AR_TRANSFORM_COLUMN_V1_OPTION @"v1"
#define WEB_AR_TRANSFORM_COLUMN_V2_OPTION @"v2"
#define WEB_AR_TRANSFORM_COLUMN_V3_OPTION @"v3"
#define WEB_AR_TRANSFORM_X_OPTION @"x"
#define WEB_AR_TRANSFORM_Y_OPTION @"y"
#define WEB_AR_TRANSFORM_Z_OPTION @"z"
#define WEB_AR_TRANSFORM_W_OPTION @"w"

#define WEB_AR_TYPE_OPTION             @"type"
#define WEB_AR_POINT_OPTION            @"point"
#define WEB_AR_PLANE_OPTION @"plane"
#define WEB_AR_PLANES_OPTION @"planes"
#define WEB_AR_POINTS_OPTION @"points"


#define WEB_AR_POSITION_OPTION         @"position"
#define WEB_AR_X_POSITION_OPTION       @"x"
#define WEB_AR_Y_POSITION_OPTION       @"y"
#define WEB_AR_Z_POSITION_OPTION       @"z"
#define WEB_AR_TRANSFORM_OPTION        @"transform"
#define WEB_AR_W_TRANSFORM_OPTION      @"worldTransform"
#define WEB_AR_L_TRANSFORM_OPTION      @"localTransform"
#define WEB_AR_DISTANCE_OPTION         @"distance"
#define WEB_AR_ELEMENTS_OPTION         @"elements"
#define WEB_AR_UUID_OPTION             @"uuid"
#define WEB_AR_NAME_OPTION             @"name"

#define WEB_AR_LIGHT_OPTION            @"light"
#define WEB_AR_LIGHT_INTENSITY_OPTION  @"ambientIntensity"
#define WEB_AR_LIGHT_COLOR_OPTION      @"ambientColorTemperature"

#define WEB_AR_CAMERA_OPTION           @"camera"
#define WEB_AR_PROJ_CAMERA_OPTION      @"projectionCamera"
#define WEB_AR_CAMERA_TRANSFORM_OPTION @"cameraTransform"

#define WEB_AR_TRACKING_STATE_NORMAL               @"arTrackingNormal"
#define WEB_AR_TRACKING_STATE_LIMITED              @"arTrackingLimited"
#define WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING @"arTrackingLimitedInitializing"
#define WEB_AR_TRACKING_STATE_LIMITED_MOTION       @"arTrackingLimitedExcessiveMotion"
#define WEB_AR_TRACKING_STATE_LIMITED_FEATURES     @"arTrackingLimitedInsufficientFeatures"
#define WEB_AR_TRACKING_STATE_NOT_AVAILABLE        @"arTrackingNotAvailable"

typedef NS_ENUM(NSInteger, ErrorCodes)
{
    Unknown,
    InvalidFormat,
    InvalidURL,
    InvalidAnchor,
    InvalidHitTest,
    InvalidRegion
};

static inline ShowOptions showOptionsFormDict(NSDictionary *dict)
{
    if (dict == nil)
    {
        return Browser;
    }
    
    ShowOptions options = None;
    
    if ([dict[WEB_AR_UI_BROWSER_OPTION] boolValue])
    {
        options = options | Browser;
    }
    
    if ([dict[WEB_AR_UI_POINTS_OPTION] boolValue])
    {
        options = options | ARPoints;
    }
    
    if ([dict[WEB_AR_UI_DEBUG_OPTION] boolValue])
    {
        options = options | Debug;
    }
    
    if ([dict[WEB_AR_UI_STATISTICS_OPTION] boolValue])
    {
        options = options | ARStatistics;
    }
    
    if ([dict[WEB_AR_UI_FOCUS_OPTION] boolValue])
    {
        options = options | ARFocus;
    }
    
    if ([dict[WEB_AR_UI_CAMERA_OPTION] boolValue])
    {
        options = options | Capture;
    }
    
    if ([dict[WEB_AR_UI_MIC_OPTION] boolValue])
    {
        options = options | Mic;
    }
    
    if ([dict[WEB_AR_UI_CAMERA_TIME_OPTION] boolValue])
    {
        options = options | CaptureTime;
    }
    
    if ([dict[WEB_AR_UI_BUILD_OPTION] boolValue])
    {
        options = options | BuildNumber;
    }
    
    if ([dict[WEB_AR_UI_PLANE_OPTION] boolValue])
    {
        options = options | ARPlanes;
    }
    
    if ([dict[WEB_AR_UI_WARNINIGS_OPTION] boolValue])
    {
        options = options | ARWarnings;
    }
    
    if ([dict[WEB_AR_UI_ANCHORS_OPTION] boolValue])
    {
        options = options | ARObject;
    }
    
    return options;
}

#endif /* WebARKHeader_h */

