#ifndef WebARKHeader_h
#define WebARKHeader_h

#import "AppState.h"

#define INTERNET_OFFLINE_CODE -1009

// URL
#define WEB_URL @"https://ios-viewer.webxrexperiments.com/viewer.html"
#define LAST_URL_KEY @"lastURL"

// MESSAGES
#define WEB_AR_INIT_MESSAGE            @"initAR"
#define WEB_AR_START_WATCH_MESSAGE     @"watchAR"
#define WEB_AR_STOP_WATCH_MESSAGE      @"stopAR"
#define WEB_AR_LOAD_URL_MESSAGE        @"loadUrl"
#define WEB_AR_SET_UI_MESSAGE          @"setUIOptions"
#define WEB_AR_HIT_TEST_MESSAGE        @"hitTest"
#define WEB_AR_ADD_ANCHOR_MESSAGE      @"addAnchor"
#define WEB_AR_REMOVE_ANCHORS_MESSAGE   @"removeAnchors"
#define WEB_AR_ADD_IMAGE_ANCHOR_MESSAGE   @"addImageAnchor"
#define WEB_AR_CREATE_IMAGE_ANCHOR_MESSAGE   @"createImageAnchor"
#define WEB_AR_ACTIVATE_DETECTION_IMAGE_MESSAGE   @"activateDetectionImage"
#define WEB_AR_DEACTIVATE_DETECTION_IMAGE_MESSAGE   @"deactivateDetectionImage"
#define WEB_AR_DESTROY_DETECTION_IMAGE_MESSAGE   @"destroyDetectionImage"
#define WEB_AR_REQUEST_CV_DATA_MESSAGE @"requestComputerVisionData"
#define WEB_AR_START_SENDING_CV_DATA_MESSAGE    @"startSendingComputerVisionData"
#define WEB_AR_STOP_SENDING_CV_DATA_MESSAGE     @"stopSendingComputerVisionData"
#define WEB_AR_ADD_IMAGE_ANCHOR         @"addImageAnchor"

#define WEB_AR_ON_JS_UPDATE_MESSAGE    @"onUpdate" // reques from JS

#define WEB_AR_IOS_SHOW_DEBUG          @"arkitShowDebug"

#define WEB_AR_IOS_START_RECORDING_MESSAGE @"arkitStartRecording"
#define WEB_AR_IOS_STOP_RECORDING_MESSAGE  @"arkitStopRecording"

#define WEB_AR_IOS_DID_MOVE_BACK_MESSAGE   @"arkitDidMoveBackground"
#define WEB_AR_IOS_WILL_ENTER_FOR_MESSAGE  @"arkitWillEnterForeground"

#define WEB_AR_IOS_WAS_INTERRUPTED_MESSAGE     @"arkitInterrupted"
#define WEB_AR_IOS_INTERRUPTION_ENDED_MESSAGE  @"arkitInterruptionEnded"

#define WEB_AR_IOS_TRACKING_STATE_MESSAGE       @"arTrackingChanged"

#define WEB_AR_IOS_DID_RECEIVE_MEMORY_WARNING_MESSAGE   @"ios_did_receive_memory_warning"
#define WEB_AR_IOS_USER_GRANTED_CV_DATA         @"userGrantedComputerVisionData"
#define WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA         @"userGrantedWorldSensingData"

// This message is not being used by the polyfill
// #define WEB_AR_IOS_VIEW_WILL_TRANSITION_TO_SIZE_MESSAGE   @"ios_view_will_transition_to_size"

#define WEB_AR_IOS_WINDOW_RESIZE_MESSAGE   @"arkitWindowResize"
#define WEB_AR_IOS_ERROR_MESSAGE           @"onError"
#define WEB_AR_IOS_SIZE_WIDTH_PARAMETER   @"width"
#define WEB_AR_IOS_SIZE_HEIGHT_PARAMETER   @"height"
#define WEB_AR_IOS_ERROR_DOMAIN_PARAMETER   @"domain"
#define WEB_AR_IOS_ERROR_CODE_PARAMETER   @"code"
#define WEB_AR_IOS_ERROR_MESSAGE_PARAMETER   @"message"

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
#define WEB_AR_UI_WARNINGS_OPTION     @"warnings"
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

#define WEB_AR_PLANE_OPTION            @"plane"
#define WEB_AR_PLANE_CENTER_OPTION     @"plane_center"
#define WEB_AR_PLANE_EXTENT_OPTION     @"plane_extent"
#define WEB_AR_PLANE_ALIGNMENT_OPTION  @"plane_alignment"
#define WEB_AR_PLANE_ID_OPTION         @"plane_id"
#define WEB_AR_PLANE_GEOMETRY_OPTION   @"geometry"
#define WEB_AR_SHOW_PLANE_OPTION       @"show_plane"
#define WEB_AR_IMAGE_NAME_OPTION       @"image_name"

#define WEB_AR_HIT_TEST_RESULT_OPTION  @"hit_test_result"
#define WEB_AR_HIT_TEST_PLANE_OPTION   @"hit_test_plane"
#define WEB_AR_HIT_TEST_POINTS_OPTION  @"hit_test_points"
#define WEB_AR_HIT_TEST_ALL_OPTION     @"hit_test_all"


#define WEB_AR_3D_OBJECTS_OPTION       @"objects" // from IOS - [ {name , matrix} ]
#define WEB_AR_3D_REMOVED_OBJECTS_OPTION @"removedObjects"
#define WEB_AR_3D_NEW_OBJECTS_OPTION   @"newObjects"
#define WEB_AR_3D_GEOALIGNED_OPTION    @"geoaligned"
#define WEB_AR_3D_VIDEO_ACCESS_OPTION  @"videoAccess"
#define WEB_AR_CV_INFORMATION_OPTION   @"computer_vision_data"
#define WEB_AR_WORLD_SENSING_DATA_OPTION @"worldSensing"

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
#define WEB_AR_MUST_SEND_OPTION        @"mustSend"

#define WEB_AR_LIGHT_INTENSITY_OPTION  @"light_intensity"
#define WEB_AR_WORLD_ALIGNMENT         @"alignEUS"

#define WEB_AR_CAMERA_OPTION           @"camera"
#define WEB_AR_PROJ_CAMERA_OPTION      @"projection_camera"
#define WEB_AR_CAMERA_TRANSFORM_OPTION @"camera_transform"
#define WEB_AR_CAMERA_VIEW_OPTION      @"camera_view"

#define WEB_AR_TRACKING_STATE_NORMAL               @"ar_tracking_normal"
#define WEB_AR_TRACKING_STATE_LIMITED              @"ar_tracking_limited"
#define WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING @"ar_tracking_limited_initializing"
#define WEB_AR_TRACKING_STATE_LIMITED_MOTION       @"ar_tracking_limited_excessive_motion"
#define WEB_AR_TRACKING_STATE_LIMITED_FEATURES     @"ar_tracking_limited_insufficient_features"
#define WEB_AR_TRACKING_STATE_NOT_AVAILABLE        @"ar_tracking_not_available"

#define WEB_AR_DETECTION_IMAGE_NAME_OPTION  @"uid"

#define AR_CAMERA_PROJECTION_MATRIX_Z_NEAR 0.001f
#define AR_CAMERA_PROJECTION_MATRIX_Z_FAR 1000.0f


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
    
    if ([dict[WEB_AR_UI_WARNINGS_OPTION] boolValue])
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

