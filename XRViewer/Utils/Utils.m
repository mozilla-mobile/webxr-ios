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

        default:
            break;
    }

    return interfaceOrientation;
}
@end