#ifndef WebARKHeader_h
#define WebARKHeader_h

#import "AppState.h"

#define INTERNET_OFFLINE_CODE -1009

// URL
#define WEB_URL @"http://ios-viewer.webxrexperiments.com/viewer.html"

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

#define WEB_AR_SHOW_UI_OPTION          @"show"
#define WEB_AR_URL_OPTION              @"url"
#define WEB_AR_JS_FRAME_RATE_OPTION    @"js_frame_rate" // bool

#define WEB_AR_LOCATION_OPTION         @"location"
#define WEB_AR_LOCATION_LON_OPTION     @"longitude"
#define WEB_AR_LOCATION_LAT_OPTION     @"latitude"
#define WEB_AR_LOCATION_ALT_OPTION     @"altitude"

#define WEB_IOS_SCREEN_SIZE_OPTION     @"screenSize"
#define WEB_IOS_SCREEN_SCALE_OPTION    @"screenScale"
#define WEB_IOS_SYSTEM_VERSION_OPTION  @"systemVersion"
#define WEB_IOS_IS_IPAD_OPTION         @"isIpad"
#define WEB_IOS_DEVICE_UUID_OPTION     @"deviceUUID"

#define WEB_AR_H_PLANE_OPTION          @"h_plane"
#define WEB_AR_H_PLANE_CENTER_OPTION   @"h_plane_center"
#define WEB_AR_H_PLANE_EXTENT_OPTION   @"h_plane_extent"
#define WEB_AR_H_PLANE_ID_OPTION       @"h_plane_id"
#define WEB_AR_SHOW_H_PLANE_OPTION     @"show_h_plane"

#define WEB_AR_HIT_TEST_RESULT_OPTION  @"hit_test_result"
#define WEB_AR_HIT_TEST_PLANE_OPTION   @"hit_test_plane"
#define WEB_AR_HIT_TEST_POINTS_OPTION  @"hit_test_points"
#define WEB_AR_HIT_TEST_ALL_OPTION     @"hit_test_all"


#define WEB_AR_3D_OBJECTS_OPTION       @"objects" // from IOS - [ {name , matrix} ]

#define WEB_AR_TYPE_OPTION             @"type"
#define WEB_AR_POSITION_OPTION         @"position"
#define WEB_AR_X_POSITION_OPTION       @"x"
#define WEB_AR_Y_POSITION_OPTION       @"y"
#define WEB_AR_Z_POSITION_OPTION       @"z"
#define WEB_AR_TRANSFORM_OPTION        @"transform"
#define WEB_AR_W_TRANSFORM_OPTION      @"world_transform"
#define WEB_AR_L_TRANSFORM_OPTION      @"local_transform"
#define WEB_AR_DISTANCE_OPTION         @"distance"
#define WEB_AR_ELEMENTS_OPTION         @"elements"
#define WEB_AR_UUID_OPTION             @"uuid"

#define WEB_AR_LIGHT_INTENSITY_OPTION  @"light_intensity"

#define WEB_AR_CAMERA_OPTION           @"camera"
#define WEB_AR_PROJ_CAMERA_OPTION      @"projection_camera"
#define WEB_AR_CAMERA_TRANSFORM_OPTION @"camera_transform"

#define WEB_AR_TRACKING_STATE_NORMAL               @"ar_tracking_normal"
#define WEB_AR_TRACKING_STATE_LIMITED              @"ar_tracking_limited"
#define WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING @"ar_tracking_limited_initializing"
#define WEB_AR_TRACKING_STATE_LIMITED_MOTION       @"ar_tracking_limited_excessive_motion"
#define WEB_AR_TRACKING_STATE_LIMITED_FEATURES     @"ar_tracking_limited_insufficient_features"
#define WEB_AR_TRACKING_STATE_NOT_AVAILABLE        @"ar_tracking_not_available"


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

