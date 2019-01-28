extension ARKController: ARSessionDelegate {
    
    // Tony: Per SO, a bug that's been around for 3+ years necessitates these @objc calls
    // to the same functions. It's annoying the workaround doesn't resolve the warnings,
    // but it works for now.
    @objc(session:didUpdateFrame:)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateARKData(with: frame)
        
        didUpdate(self)
        
        if shouldUpdateWindowSize {
            self.shouldUpdateWindowSize = false
            didUpdateWindowSize()
        }
    }
    
    @objc(session:didAddAnchors:)
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        DDLogDebug("Add Anchors - \(anchors.debugDescription)")
        for addedAnchor: ARAnchor in anchors {
            if addedAnchor is ARFaceAnchor && !(configuration is ARFaceTrackingConfiguration) {
                print("Trying to add a face anchor to a session configuration that's not ARFaceTrackingConfiguration")
                continue
            }
            
            if shouldSend(addedAnchor) || sendingWorldSensingDataAuthorizationStatus == .authorized
            // Tony: Initially I implemented this line to allow face-based and image-based AR
            // experiences to work when operating in .singlePlane/AR Lite Mode.  However
            // if the user is choosing to operate in AR Lite Mode (i.e. a mode focused on
            // restricting the amount of data shared), they likely wouldn't want the website to
            // utilize any recognized ARFaceAnchors nor, potentially, ARImageAnchors
            //            || (self.sendingWorldSensingDataAuthorizationStatus == SendWorldSensingDataAuthorizationStateSinglePlane && ([addedAnchor isKindOfClass:[ARImageAnchor class]] || [addedAnchor isKindOfClass:[ARFaceAnchor class]]))
            {
                
                let addedAnchorDictionary = createDictionary(for: addedAnchor)
                addedAnchorsSinceLastFrame.add(addedAnchorDictionary)
                objects[anchorID(for: addedAnchor)] = addedAnchorDictionary
                
                if addedAnchor is ARImageAnchor {
                    let addedImageAnchor = addedAnchor as? ARImageAnchor
                    guard let name = addedImageAnchor?.referenceImage.name else { return }
                    if detectionImageActivationPromises[name] != nil {
                        let promise = detectionImageActivationPromises[name] as? ActivateDetectionImageCompletionBlock
                        // Call the detection image block
                        promise?(true, nil, addedAnchorDictionary as? [AnyHashable : Any])
                        detectionImageActivationPromises[name] = nil
                    }
                }
            }
        }
        
        if sendingWorldSensingDataAuthorizationStatus == .singlePlane {
            
            let allFrameAnchors = self.session?.currentFrame?.anchors
            let planeAnchors = allFrameAnchors?.filter { $0 is ARPlaneAnchor }
            
            if planeAnchors?.count == 1 {
                guard let firstPlane = allFrameAnchors?.first as? ARPlaneAnchor else { return }
                let addedAnchorDictionary = createDictionary(for: firstPlane)
                addedAnchorsSinceLastFrame.add(addedAnchorDictionary)
                objects[anchorID(for: firstPlane)] = addedAnchorDictionary
            }
        }
    }
}
