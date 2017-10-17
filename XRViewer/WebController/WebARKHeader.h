#ifndef WebARKHeader_h
#define WebARKHeader_h

#import "AppState.h"

#define INTERNET_OFFLINE_CODE -1009
#define CANCELLED_CODE -999
#define SERVER_START_CODE 200
#define SERVER_STOP_CODE 600

// Start URL
#define WEB_URL @"https://mozilla-mobile.github.io/webxr-ios/app/"

// ##############################  MESSAGES

// JS
#define WEB_JS_INIT_MESSAGE              @"arInitAR"
#define WEB_JS_START_WATCH_MESSAGE       @"arWatchAR"
#define WEB_JS_STOP_WATCH_MESSAGE        @"arStopAR"
#define WEB_JS_LOAD_URL_MESSAGE          @"arLoadURL"
#define WEB_JS_SET_UI_MESSAGE            @"arSetUIOptions"
#define WEB_JS_HIT_TEST_MESSAGE          @"arHitTest"
#define WEB_JS_ADD_ANCHOR_MESSAGE        @"arAddAnchor"
#define WEB_JS_REMOVE_ANCHOR_MESSAGE     @"arRemoveAnchor"
#define WEB_JS_UPDATE_ANCHOR_MESSAGE     @"arUpdateAnchor"
#define WEB_JS_START_HOLD_ANCHOR_MESSAGE @"arStartHoldAnchor"
#define WEB_JS_STOP_HOLD_ANCHOR_MESSAGE  @"arStopHoldAnchor"
#define WEB_JS_ADD_REGION_MESSAGE        @"arAddRegion"
#define WEB_JS_REMOVE_REGION_MESSAGE     @"arRemoveRegion"
#define WEB_JS_IN_REGION_MESSAGE         @"arInRegion"

static inline NSArray * jsMessages()
{
    return @[WEB_JS_INIT_MESSAGE,
             WEB_JS_START_WATCH_MESSAGE,
             WEB_JS_STOP_WATCH_MESSAGE,
             WEB_JS_LOAD_URL_MESSAGE,
             WEB_JS_SET_UI_MESSAGE,
             WEB_JS_HIT_TEST_MESSAGE,
             WEB_JS_ADD_ANCHOR_MESSAGE,
             WEB_JS_REMOVE_ANCHOR_MESSAGE,
             WEB_JS_UPDATE_ANCHOR_MESSAGE,
             WEB_JS_START_HOLD_ANCHOR_MESSAGE,
             WEB_JS_STOP_HOLD_ANCHOR_MESSAGE,
             WEB_JS_ADD_REGION_MESSAGE,
             WEB_JS_REMOVE_REGION_MESSAGE,
             WEB_JS_IN_REGION_MESSAGE
             ];
}

//IOS
#define WEB_AR_SHOW_DEBUG_MESSAGE @"arShowDebug"
#define WEB_AR_MOVE_BACKGROUND_MESSAGE @"arDidMoveBackground"
#define WEB_AR_ENTER_FOREGROUND_MESSAGE @"arWillEnterForeground"
#define WEB_AR_MEMORY_WARNING_MESSAGE @"arReceiveMemoryWarning"
#define WEB_AR_TRANSITION_TO_SIZE_MESSAGE @"arTransitionToSize"
#define WEB_AR_ENTER_REGION_MESSAGE @"arEnterRegion"
#define WEB_AR_EXIT_REGION_MESSAGE @"arExitRegion"
#define WEB_AR_UPDATE_HEADING_MESSAGE @"arUpdateHeading"
#define WEB_AR_UPDATE_LOCATION_MESSAGE @"arUpdateLocation"
//arkit
#define WEB_AR_INTERRUPTION_MESSAGE @"arInterruption"
#define WEB_AR_INTERRUPTION_ENDED_MESSAGE @"arInterruptionEnded"
#define WEB_AR_TRACKING_CHANGED_MESSAGE @"arTrackingChange"
#define WEB_AR_SESSION_FAILS_MESSAGE @"arSessionFails"
#define WEB_AR_UPDATED_ANCHORS_MESSAGE @"arUpdatedAnchors"
#define WEB_AR_ADD_PLANES_MESSAGE @"arAddPlanes"
#define WEB_AR_REMOVE_PLANES_MESSAGE @"arRemovePlanes"
//record
#define WEB_AR_START_RECORDING_MESSAGE @"arStartRecording"
#define WEB_AR_STOP_RECORDING_MESSAGE @"arStopRecording"

// ##############################  OPTIONS

#define WEB_AR_UI_CUSTOM_OPTION        @"custom"
#define WEB_AR_UI_ARKIT_OPTION         @"arkit"
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

#define WEB_AR_ANCHOR_TRANSFORM_OPTION @"anchorTransform"
#define WEB_AR_ANCHOR_CENTER_OPTION    @"anchorCenter"
#define WEB_AR_ANCHOR_EXTENT_OPTION    @"anchorExtent"

#define WEB_AR_TEST_OPTION             @"test"
#define WEB_AR_ID_OPTION               @"id"
#define WEB_AR_SHOW_UI_OPTION          @"show"
#define WEB_AR_URL_OPTION              @"url"

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

#define WEB_IOS_WIDTH_OPTION  @"width"
#define WEB_IOS_HEIGHT_OPTION @"height"
#define WEB_IOS_VIEWPORT_SIZE_OPTION   @"viewportSize"
#define WEB_IOS_SCREEN_SIZE_OPTION     @"screenSize"
#define WEB_IOS_SCREEN_SCALE_OPTION    @"screenScale"
#define WEB_IOS_SYSTEM_VERSION_OPTION  @"systemVersion"
#define WEB_IOS_IS_IPAD_OPTION         @"isIpad"
#define WEB_IOS_DEVICE_UUID_OPTION     @"uuid"

#define WEB_AR_ERROR_CODE  @"error"

#define WEB_AR_TRANSFORM_COLUMN_V0_OPTION @"v0"
#define WEB_AR_TRANSFORM_COLUMN_V1_OPTION @"v1"
#define WEB_AR_TRANSFORM_COLUMN_V2_OPTION @"v2"
#define WEB_AR_TRANSFORM_COLUMN_V3_OPTION @"v3"
#define WEB_AR_TRANSFORM_X_OPTION @"x"
#define WEB_AR_TRANSFORM_Y_OPTION @"y"
#define WEB_AR_TRANSFORM_Z_OPTION @"z"
#define WEB_AR_TRANSFORM_W_OPTION @"w"

#define WEB_AR_TYPE_OPTION      @"type"
#define WEB_AR_POINT_OPTION     @"point"
#define WEB_AR_PLANE_OPTION     @"plane"
#define WEB_AR_PLANES_OPTION    @"planes"
#define WEB_AR_POINTS_OPTION    @"points"
#define WEB_AR_ANCHORS_OPTION   @"anchors"

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
    
    NSMutableDictionary *common = [NSMutableDictionary dictionaryWithDictionary: dict[WEB_AR_UI_CUSTOM_OPTION]];
    [common addEntriesFromDictionary:dict[WEB_AR_UI_ARKIT_OPTION]];
    
    ShowOptions options = None;
    
    if ([common[WEB_AR_UI_BROWSER_OPTION] boolValue])
    {
        options = options | Browser;
    }
    
    if ([common[WEB_AR_UI_POINTS_OPTION] boolValue])
    {
        options = options | ARPoints;
    }
    
    if ([common[WEB_AR_UI_DEBUG_OPTION] boolValue])
    {
        options = options | Debug;
    }
    
    if ([common[WEB_AR_UI_STATISTICS_OPTION] boolValue])
    {
        options = options | ARStatistics;
    }
    
    if ([common[WEB_AR_UI_FOCUS_OPTION] boolValue])
    {
        options = options | ARFocus;
    }
    
    if ([common[WEB_AR_UI_CAMERA_OPTION] boolValue])
    {
        options = options | Capture;
    }
    
    if ([common[WEB_AR_UI_MIC_OPTION] boolValue])
    {
        options = options | Mic;
    }
    
    if ([common[WEB_AR_UI_CAMERA_TIME_OPTION] boolValue])
    {
        options = options | CaptureTime;
    }
    
    if ([common[WEB_AR_UI_BUILD_OPTION] boolValue])
    {
        options = options | BuildNumber;
    }
    
    if ([common[WEB_AR_UI_PLANE_OPTION] boolValue])
    {
        options = options | ARPlanes;
    }
    
    if ([common[WEB_AR_UI_WARNINIGS_OPTION] boolValue])
    {
        options = options | ARWarnings;
    }
    
    if ([common[WEB_AR_UI_ANCHORS_OPTION] boolValue])
    {
        options = options | ARObject;
    }
    
    return options;
}

#endif /* WebARKHeader_h */

