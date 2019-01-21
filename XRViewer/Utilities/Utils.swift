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

extension vector_float3 {
    func dictionary() -> NSDictionary {
        return [
            WEB_AR_X_POSITION_OPTION: self.x,
            WEB_AR_Y_POSITION_OPTION: self.y,
            WEB_AR_Z_POSITION_OPTION: self.z
        ]
    }
}

extension vector_float2 {
    func dictionary() -> NSDictionary {
        return [
            WEB_AR_X_POSITION_OPTION: self.x,
            WEB_AR_Y_POSITION_OPTION: self.y
        ]
    }
}

extension matrix_float4x4 {
    func array() -> [Float] {
        return [
            self.columns.0.x,
            self.columns.0.y,
            self.columns.0.z,
            self.columns.0.w,
            self.columns.1.x,
            self.columns.1.y,
            self.columns.1.z,
            self.columns.1.w,
            self.columns.2.x,
            self.columns.2.y,
            self.columns.2.z,
            self.columns.2.w,
            self.columns.3.x,
            self.columns.3.y,
            self.columns.3.z,
            self.columns.3.w
        ]
    }
}
