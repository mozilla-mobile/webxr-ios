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

static inline NSDictionary * dictFromVector3(vector_float3 vector)
{
    return @{WEB_AR_X_POSITION_OPTION : @(vector.x),
             WEB_AR_Y_POSITION_OPTION : @(vector.y),
             WEB_AR_Z_POSITION_OPTION : @(vector.z)};
}

static inline vector_float3 vector3FromDictionary(NSDictionary *dict)
{
    vector_float3 vector;
    
    vector.x = [dict[WEB_AR_X_POSITION_OPTION] floatValue];
    vector.y = [dict[WEB_AR_Y_POSITION_OPTION] floatValue];
    vector.z = [dict[WEB_AR_Z_POSITION_OPTION] floatValue];
    
    return vector;
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

static inline CGPoint pointWithDict(NSDictionary *dict)
{
    if (dict[WEB_AR_X_POSITION_OPTION] && dict[WEB_AR_Y_POSITION_OPTION])
    {
        return CGPointMake([dict[WEB_AR_X_POSITION_OPTION] floatValue], [dict[WEB_AR_Y_POSITION_OPTION] floatValue]);
    }
    
    return CGPointZero;
}

static inline NSDictionary * pointDictWithResult(ARHitTestResult *result)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    
    dict[WEB_AR_TYPE_OPTION] = @([result type]);
    dict[WEB_AR_W_TRANSFORM_OPTION] = dictWithMatrix4([result worldTransform]);
    dict[WEB_AR_L_TRANSFORM_OPTION] = dictWithMatrix4([result localTransform]);
    dict[WEB_AR_DISTANCE_OPTION] = @([result distance]);
    
    return [dict copy];
}

static inline NSDictionary * planeDictWithAnchor(ARPlaneAnchor *planeAnchor)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    
    dict[WEB_AR_UUID_OPTION] = [[planeAnchor identifier] UUIDString];
    dict[WEB_AR_ANCHOR_CENTER_OPTION] = dictFromVector3([planeAnchor center]);
    dict[WEB_AR_ANCHOR_EXTENT_OPTION] = dictFromVector3([planeAnchor extent]);
    dict[WEB_AR_ANCHOR_TRANSFORM_OPTION] = dictWithMatrix4([planeAnchor transform]);
    
    return [dict copy];
}

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

static inline NSDictionary * dictWithLight(ARLightEstimate *light)
{
    return @{
             WEB_AR_LIGHT_INTENSITY_OPTION : @([light ambientIntensity]),
             WEB_AR_LIGHT_COLOR_OPTION : @([light ambientColorTemperature])
             };
}

#endif /* ARKHelper_h */

