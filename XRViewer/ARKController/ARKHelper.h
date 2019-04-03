#ifndef ARKHelper_h
#define ARKHelper_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ARKit/ARKit.h>

/**
 Enum representing the WebXR authorization status
 
 - WebXRAuthorizationStateNotDetermined: The user didn't say anything about the world sensing
 - WebXRAuthorizationStateDenied: The user denied sending world sensing data
 - WebXRAuthorizationStateMinimal: The user allowed sending wold sensing data
 - WebXRAuthorizationStateLite: The user allowed sending wold sensing data
 - WebXRAuthorizationStateWorldSensing: The user allowed sending wold sensing data
 - WebXRAuthorizationStateVideoCameraAccess: The user allowed access to the video camera and sending wold sensing data
 
 */
typedef NS_ENUM(NSUInteger, WebXRAuthorizationState)
{
    WebXRAuthorizationStateNotDetermined,
    WebXRAuthorizationStateDenied,
    WebXRAuthorizationStateMinimal,
    WebXRAuthorizationStateLite,
    WebXRAuthorizationStateWorldSensing,
    WebXRAuthorizationStateVideoCameraAccess
};

/**
 An enum representing the state of the app UI at a given time
 
 - ShowNothing: Shows the warning labels
 - ShowDebug: Shows the helper and build label, and the AR debug info
 - ShowURL: Shows the URL Bar
 - ShowURLDebug: Shows the URL Bar and the AR debug info
 */
// Tony (2/12/19): In making the ShowMode enum more descriptive, there's temporary
//      awkwardness & bad style when using the enum in Swift (.URL & .urlDebug).
//      This will be resolved when fully converted to Swift.
typedef NS_ENUM(NSUInteger, ShowMode)
{
    ShowNothing,
    ShowDebug,
    ShowURL,
    ShowURLDebug
};

/**
 Show options. This option set is built from the AR Request dictionary received on initAR
 
 - None: Shows nothing
 - Browser: Shows in browser mode
 - ARWarnings: Shows warnings reported by ARKit
 - ARFocus: Shows a focus node
 - ARObject: Shows AR objects
 - Debug: Not used
 - ARPlanes: Shows AR planes
 - ARPoints: Shows AR feature points
 - ARStatistics: Shows AR Statistics
 - BuildNumber: Shows the app build number
 - Full: Shows everything
 */
typedef NS_OPTIONS(NSUInteger, ShowOptions)
{
    None         = 0,
    Browser      = (1 << 0),
    ARWarnings   = (1 << 1),
    ARFocus      = (1 << 2),
    ARObject     = (1 << 3),
    Debug        = (1 << 4),
    ARPlanes     = (1 << 5),
    ARPoints     = (1 << 6),
    ARStatistics = (1 << 7),
    BuildNumber  = (1 << 8),
    Full         = NSUIntegerMax
};

static inline NSDictionary * dictFromVector3(vector_float3 vector)
{
    return @{@"x" : @(vector.x), @"y" : @(vector.y), @"z" : @(vector.z)};
}

#endif /* ARKHelper_h */
