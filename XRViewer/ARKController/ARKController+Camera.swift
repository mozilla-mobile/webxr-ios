@objc extension ARKController {
    
    // MARK: - Camera Device
    
    func setupDeviceCamera() {
        device = AVCaptureDevice.default(for: .video)
        
        if device == nil {
            DDLogError("Camera device is NIL")
            return
        }
        
        do {
            try device.lockForConfiguration()
        } catch {
            DDLogError("Camera lock error")
            return
        }
        
        if device.isFocusModeSupported(.continuousAutoFocus) {
            DDLogDebug("AVCaptureFocusModeContinuousAutoFocus Supported")
            device.focusMode = .continuousAutoFocus
        }
        
        if device.isFocusPointOfInterestSupported {
            DDLogDebug("FocusPointOfInterest Supported")
            device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
        }
        
        if device.isSmoothAutoFocusSupported {
            DDLogDebug("SmoothAutoFocus Supported")
            device.isSmoothAutoFocusEnabled = true
        }
        
        device.unlockForConfiguration()
    }
    
    // MARK: - Camera Button
    
    /**
     Removes all the anchors in the current session.
     
     If the current session is not of class ARFaceTrackingConfiguration, create a
     ARFaceTrackingConfiguration and run the session with it.
     
     Otherwise, create an ARWorldTrackingConfiguration, add the images that were not detected
     in the previous ARWorldTrackingConfiguration session, and run the session.
     */
    func switchCameraButtonTapped(_ state: AppState) { // numberOfTrackedImages: Int) {
        guard let currentFrame = session.currentFrame else { return }
        for anchor in currentFrame.anchors {
            session.remove(anchor: anchor)
        }
        
        if !(configuration is ARFaceTrackingConfiguration) {
            let faceTrackingConfiguration = ARFaceTrackingConfiguration()
            configuration = faceTrackingConfiguration
            //session.run(configuration, options: [])
            runSession(with: state)
        } else {
            let worldTrackingConfiguration = ARWorldTrackingConfiguration()
            worldTrackingConfiguration.planeDetection = [.horizontal, .vertical]
            
            // these are set in runSession()
            //worldTrackingConfiguration.worldAlignment = .gravityAndHeading
            //worldTrackingConfiguration.maximumNumberOfTrackedImages = state.numberOfTrackedImages
            
            // Configure all the active images that weren't detected in the previous back camera session
            let undetectedImageNames = detectionImageActivationPromises.allKeys
            var newDetectionImages = Set<ARReferenceImage>()
            for imageName: String in undetectedImageNames as? [String] ?? [] {
                if let referenceImage = referenceImageMap[imageName] as? ARReferenceImage {
                    _ = newDetectionImages.insert(referenceImage)
                }
            }
            worldTrackingConfiguration.detectionImages = newDetectionImages
            
            configuration = worldTrackingConfiguration
            
            //session.run(configuration, options: [])
            runSession(with: state)
        }
    }
    
    // MARK: - Helpers
    
    class func supportsARFaceTrackingConfiguration() -> Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
}
