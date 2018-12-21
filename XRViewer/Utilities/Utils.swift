import Foundation
import UIKit

class Utils: NSObject {
    /**
     Gets the interface orientation taking the device orientation as input
     
     @return the UIInterfaceOrientation of the app
     */

    @objc class func getInterfaceOrientationFromDeviceOrientation() -> UIInterfaceOrientation {
        let deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
        var interfaceOrientation: UIInterfaceOrientation = .landscapeLeft
        switch deviceOrientation {
            case .portrait:
                interfaceOrientation = .portrait
            case .portraitUpsideDown:
                interfaceOrientation = .portraitUpsideDown
            case .landscapeLeft:
                interfaceOrientation = .landscapeRight
            case .landscapeRight:
                interfaceOrientation = .landscapeLeft
            case .faceUp:
                // Without more context, we don't know the interface orientation when the device is oriented flat, so take it from the statusBarOrientation
                interfaceOrientation = UIApplication.shared.statusBarOrientation
            case .faceDown:
                // Without more context, we don't know the interface orientation when the device is oriented flat, so take it from the statusBarOrientation
                interfaceOrientation = UIApplication.shared.statusBarOrientation
            default:
                break
        }

        return interfaceOrientation
    }
}
