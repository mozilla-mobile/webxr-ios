#ifndef ARKHelper_h
#define ARKHelper_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ARKit/ARKit.h>
#import "WebARKHeader.h"
#import "UserAnchor.h"

#define BOX_SIZE 0.05

static inline vector_float4 vectorWithDict(NSDictionary *dict)
{
    vector_float4 vector = 0;
    
    if(dict.count != 4)
    {
        return vector;
    }
    
    vector.x = [dict[WEB_AR_TRANSFORM_X_OPTION] floatValue];
    vector.y = [dict[WEB_AR_TRANSFORM_Y_OPTION] floatValue];
    vector.z = [dict[WEB_AR_TRANSFORM_Z_OPTION] floatValue];
    vector.w = [dict[WEB_AR_TRANSFORM_W_OPTION] floatValue];
    
    return vector;
}

static inline matrix_float4x4 matrixWithDict(NSDictionary *dict)
{
    matrix_float4x4 matrix = matrix_identity_float4x4;
    
    if(dict.allKeys.count != 4)
    {
        return matrix;
    }
    
    for(NSString *vector in dict.allKeys)
    {
        if([vector isEqualToString:WEB_AR_TRANSFORM_COLUMN_V0_OPTION])
        {
            matrix.columns[0] = vectorWithDict(dict[vector]);
        }
        else if([vector isEqualToString:WEB_AR_TRANSFORM_COLUMN_V1_OPTION])
        {
            matrix.columns[1] = vectorWithDict(dict[vector]);
        }
        else if([vector isEqualToString:WEB_AR_TRANSFORM_COLUMN_V2_OPTION])
        {
            matrix.columns[2] = vectorWithDict(dict[vector]);
        }
        else if([vector isEqualToString:WEB_AR_TRANSFORM_COLUMN_V3_OPTION])
        {
            matrix.columns[3] = vectorWithDict(dict[vector]);
        }
    }
    
    return matrix;
}

static inline NSDictionary* dictWithVector4(vector_float4 vector)
{
    return @{
             WEB_AR_TRANSFORM_X_OPTION : @(vector.x),
             WEB_AR_TRANSFORM_Y_OPTION : @(vector.y),
             WEB_AR_TRANSFORM_Z_OPTION : @(vector.z),
             WEB_AR_TRANSFORM_W_OPTION : @(vector.w),
             };
}

static inline NSDictionary* dictWithMatrix4(matrix_float4x4 matrix)
{
    return @{
             WEB_AR_TRANSFORM_COLUMN_V0_OPTION : dictWithVector4(matrix.columns[0]),
             WEB_AR_TRANSFORM_COLUMN_V1_OPTION : dictWithVector4(matrix.columns[1]),
             WEB_AR_TRANSFORM_COLUMN_V2_OPTION : dictWithVector4(matrix.columns[2]),
             WEB_AR_TRANSFORM_COLUMN_V3_OPTION : dictWithVector4(matrix.columns[3]),
             };
}

static inline NSDictionary * userAnchorDictWith(UserAnchor *anchor)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    if([anchor name] != nil)
    {
        dict[WEB_AR_NAME_OPTION] = [anchor name];
    }
    
    dict[WEB_AR_UUID_OPTION] = [[anchor identifier] UUIDString];
    dict[WEB_AR_TRANSFORM_OPTION] = dictWithMatrix4([anchor transform]);
    
    return dict;
}




/*static inline NSArray * arrayFromMatrix4x4(matrix_float4x4  matrix)
{
    return @[@(matrix.columns[0][0]),
             @(matrix.columns[0][1]),
             @(matrix.columns[0][2]),
             @(matrix.columns[0][3]),
             @(matrix.columns[1][0]),
             @(matrix.columns[1][1]),
             @(matrix.columns[1][2]),
             @(matrix.columns[1][3]),
             @(matrix.columns[2][0]),
             @(matrix.columns[2][1]),
             @(matrix.columns[2][2]),
             @(matrix.columns[2][3]),
             @(matrix.columns[3][0]),
             @(matrix.columns[3][1]),
             @(matrix.columns[3][2]),
             @(matrix.columns[3][3])];
}

static inline matrix_float4x4 matrixFromArray(NSArray *arr)
{
    matrix_float4x4 matrix;
    
    matrix.columns[0][0] = [arr[0] floatValue];
    matrix.columns[0][1] = [arr[1] floatValue];
    matrix.columns[0][2] = [arr[2] floatValue];
    matrix.columns[0][3] = [arr[3] floatValue];
    matrix.columns[1][0] = [arr[4] floatValue];
    matrix.columns[1][1] = [arr[5] floatValue];
    matrix.columns[1][2] = [arr[6] floatValue];
    matrix.columns[1][3] = [arr[7] floatValue];
    matrix.columns[2][0] = [arr[8] floatValue];
    matrix.columns[2][1] = [arr[9] floatValue];
    matrix.columns[2][2] = [arr[10] floatValue];
    matrix.columns[2][3] = [arr[11] floatValue];
    matrix.columns[3][0] = [arr[12] floatValue];
    matrix.columns[3][1] = [arr[13] floatValue];
    matrix.columns[3][2] = [arr[14] floatValue];
    matrix.columns[3][3] = [arr[15] floatValue];
    
    return matrix;
}*/

static inline NSDictionary * dictFromVector3(vector_float3 vector)
{
    return @{WEB_AR_X_POSITION_OPTION : @(vector.x),  WEB_AR_Y_POSITION_OPTION : @(vector.y), WEB_AR_Z_POSITION_OPTION : @(vector.z)};
}

static inline vector_float3 vector3FromDictionary(NSDictionary *dict)
{
    vector_float3 vector;
    
    vector.x = [dict[WEB_AR_X_POSITION_OPTION] floatValue];
    vector.y = [dict[WEB_AR_Y_POSITION_OPTION] floatValue];
    vector.z = [dict[WEB_AR_Z_POSITION_OPTION] floatValue];
    
    return vector;
}

static inline ARHitTestResultType hitTypeFromString(NSString *string)
{
    if ([string isEqualToString:WEB_AR_HIT_TEST_PLANE_OPTION])
    {
        return ARHitTestResultTypeExistingPlaneUsingExtent;
    }
    else if ([string isEqualToString:WEB_AR_HIT_TEST_POINTS_OPTION])
    {
        return ARHitTestResultTypeFeaturePoint;
    }
    else if ([string isEqualToString:WEB_AR_HIT_TEST_ALL_OPTION])
    {
        return ARHitTestResultTypeExistingPlaneUsingExtent | ARHitTestResultTypeFeaturePoint;
    }
    
    return ARHitTestResultTypeExistingPlaneUsingExtent;
}

/*static inline NSDictionary * dictFromMatrix4x4(matrix_float4x4  matrix)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:16];
    
    dict[@"00"] = @(matrix.columns[0][0]);
    dict[@"01"] = @(matrix.columns[0][1]);
    dict[@"02"] = @(matrix.columns[0][2]);
    dict[@"03"] = @(matrix.columns[0][3]);
    dict[@"10"] = @(matrix.columns[1][0]);
    dict[@"11"] = @(matrix.columns[1][1]);
    dict[@"12"] = @(matrix.columns[1][2]);
    dict[@"13"] = @(matrix.columns[1][3]);
    dict[@"20"] = @(matrix.columns[2][0]);
    dict[@"21"] = @(matrix.columns[2][1]);
    dict[@"22"] = @(matrix.columns[2][2]);
    dict[@"23"] = @(matrix.columns[2][3]);
    dict[@"30"] = @(matrix.columns[3][0]);
    dict[@"31"] = @(matrix.columns[3][1]);
    dict[@"32"] = @(matrix.columns[3][2]);
    dict[@"33"] = @(matrix.columns[3][3]);
    
    return [dict copy];
}

static inline matrix_float4x4 matrixFromKeyedArrayDictionary(NSDictionary *dict);

static inline matrix_float4x4 matrixFromDictionary(NSDictionary *dict)
{
    if (dict[@"33"] == nil)
    {
        return matrixFromKeyedArrayDictionary(dict);
    }
    
    matrix_float4x4 matrix;
    NSString *stringValue = dict[@"00"] ? dict[@"00"] : dict[@"0"];
    matrix.columns[0][0] = [stringValue floatValue];
    
    stringValue = dict[@"01"] ? dict[@"01"] : dict[@"1"];
    matrix.columns[0][1] = [stringValue floatValue];
    
    stringValue = dict[@"02"] ? dict[@"02"] : dict[@"2"];
    matrix.columns[0][2] = [stringValue floatValue];
    
    stringValue = dict[@"03"] ? dict[@"03"] : dict[@"3"];
    matrix.columns[0][3] = [stringValue floatValue];
    
    matrix.columns[1][0] = [dict[@"10"] floatValue];
    matrix.columns[1][1] = [dict[@"11"] floatValue];
    matrix.columns[1][2] = [dict[@"12"] floatValue];
    matrix.columns[1][3] = [dict[@"13"] floatValue];
    matrix.columns[2][0] = [dict[@"20"] floatValue];
    matrix.columns[2][1] = [dict[@"21"] floatValue];
    matrix.columns[2][2] = [dict[@"22"] floatValue];
    matrix.columns[2][3] = [dict[@"23"] floatValue];
    matrix.columns[3][0] = [dict[@"30"] floatValue];
    matrix.columns[3][1] = [dict[@"31"] floatValue];
    matrix.columns[3][2] = [dict[@"32"] floatValue];
    matrix.columns[3][3] = [dict[@"33"] floatValue];
    
    return matrix;
}

static inline matrix_float4x4 matrixFromKeyedArrayDictionary(NSDictionary *dict)
{
    matrix_float4x4 matrix;
    
    matrix.columns[0][0] = [dict[@"0"] floatValue];
    matrix.columns[0][1] = [dict[@"1"] floatValue];
    matrix.columns[0][2] = [dict[@"2"] floatValue];
    matrix.columns[0][3] = [dict[@"3"] floatValue];
    matrix.columns[1][0] = [dict[@"4"] floatValue];
    matrix.columns[1][1] = [dict[@"5"] floatValue];
    matrix.columns[1][2] = [dict[@"6"] floatValue];
    matrix.columns[1][3] = [dict[@"7"] floatValue];
    matrix.columns[2][0] = [dict[@"8"] floatValue];
    matrix.columns[2][1] = [dict[@"9"] floatValue];
    matrix.columns[2][2] = [dict[@"10"] floatValue];
    matrix.columns[2][3] = [dict[@"11"] floatValue];
    matrix.columns[3][0] = [dict[@"12"] floatValue];
    matrix.columns[3][1] = [dict[@"13"] floatValue];
    matrix.columns[3][2] = [dict[@"14"] floatValue];
    matrix.columns[3][3] = [dict[@"15"] floatValue];
    
    return matrix;
}*/

static inline NSString *trackingState(ARCamera *camera)
{
    switch ([camera trackingState])
    {
        case ARTrackingStateNormal:
            return WEB_AR_TRACKING_STATE_NORMAL;
        case ARTrackingStateLimited:
        {
            switch ([camera trackingStateReason])
            {
                case ARTrackingStateReasonNone:
                    return WEB_AR_TRACKING_STATE_LIMITED;
                case ARTrackingStateReasonInitializing: //The AR session has not yet gathered enough camera or motion data to provide tracking information.
                    //This value occurs temporarily after starting a new AR session or changing configurations.
                    return WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING;
                case ARTrackingStateReasonExcessiveMotion: //The device is moving too fast for accurate image-based position tracking.
                    return WEB_AR_TRACKING_STATE_LIMITED_MOTION;
                case ARTrackingStateReasonInsufficientFeatures: //The scene visible to the camera does not contain enough distinguishable features for image-based position tracking.
                    return WEB_AR_TRACKING_STATE_LIMITED_FEATURES;
            }
        }
        case ARTrackingStateNotAvailable:
            return WEB_AR_TRACKING_STATE_NOT_AVAILABLE;
    }
}

static inline NSArray *hitTestResultArrayFromResult(NSArray *resultArray)
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resultArray count]];
    
    for (ARHitTestResult *result in resultArray)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
        
        dict[WEB_AR_TYPE_OPTION] = @([result type]);
        //dict[WEB_AR_W_TRANSFORM_OPTION] = arrayFromMatrix4x4([result worldTransform]);
        //dict[WEB_AR_L_TRANSFORM_OPTION] = arrayFromMatrix4x4([result localTransform]);
        dict[WEB_AR_DISTANCE_OPTION] = @([result distance]);
        dict[WEB_AR_UUID_OPTION] = [[[result anchor] identifier] UUIDString];
        
        if ([[result anchor] isKindOfClass:[ARPlaneAnchor class]])
        {
            ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)[result anchor];
            dict[WEB_AR_ANCHOR_CENTER_OPTION] = dictFromVector3([planeAnchor center]);
            dict[WEB_AR_ANCHOR_EXTENT_OPTION] = dictFromVector3([planeAnchor extent]);
            //dict[WEB_AR_ANCHOR_TRANSFORM_OPTION] = arrayFromMatrix4x4([planeAnchor transform]);
        }
        
        [results addObject:dict];
    }
    
    return [results copy];
}

#endif /* ARKHelper_h */

