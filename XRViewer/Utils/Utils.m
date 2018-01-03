//
// Created by Roberto Garrido on 19/12/17.
// Copyright (c) 2017 Mozilla. All rights reserved.
//

#import "Utils.h"

@implementation Utils {

}
+ (UIInterfaceOrientation)getInterfaceOrientationFromDeviceOrientation {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait: {
            interfaceOrientation = UIInterfaceOrientationPortrait;
        } break;

        case UIDeviceOrientationPortraitUpsideDown: {
            interfaceOrientation = UIInterfaceOrientationPortraitUpsideDown;
        } break;

        case UIDeviceOrientationLandscapeLeft: {
            interfaceOrientation = UIInterfaceOrientationLandscapeRight;
        } break;

        case UIDeviceOrientationLandscapeRight: {
            interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
        } break;
            
        case UIDeviceOrientationFaceUp: {
            // Without more context, we don't know the interface orientation when the device is oriented flat, so take it from the statusBarOrientation
            interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        } break;
            
        case UIDeviceOrientationFaceDown: {
            // Without more context, we don't know the interface orientation when the device is oriented flat, so take it from the statusBarOrientation
            interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        } break;

        default:
            break;
    }

    return interfaceOrientation;
}
@end