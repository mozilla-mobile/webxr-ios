@objc extension ARKController {
    
    func createReferenceImage(fromDictionary referenceImageDictionary: [AnyHashable: Any]) -> ARReferenceImage? {
        let physicalWidth: CGFloat = referenceImageDictionary["physicalWidth"] as? CGFloat ?? 0
        let b64String = referenceImageDictionary["buffer"] as? String
        let width = size_t(referenceImageDictionary["imageWidth"] as? Int ?? 0)
        let height = size_t(referenceImageDictionary["imageHeight"] as? Int ?? 0)
        let bitsPerComponent: size_t = 8
        let bitsPerPixel: size_t = 32
        let bytesPerRow = size_t(width * 4)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bitmapInfo = CGBitmapInfo(rawValue: 0)
        guard let data = Data(base64Encoded: b64String ?? "", options: .ignoreUnknownCharacters) else { return nil }
        let bridgedData = data as CFData
        guard let dataProvider = CGDataProvider.init(data: bridgedData) else { return nil }
        let shouldInterpolate = true
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: bitsPerComponent,
                              bitsPerPixel: bitsPerPixel,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: dataProvider,
                              decode: nil,
                              shouldInterpolate: shouldInterpolate,
                              intent: CGColorRenderingIntent.defaultIntent)
        var result: ARReferenceImage? = nil
        if cgImage != nil {
            result = ARReferenceImage(cgImage!, orientation: .up, physicalWidth: physicalWidth)
            result?.name = referenceImageDictionary["uid"] as? String
        }
        
        return result
    }
    
    /**
     If SendWorldSensingDataAuthorizationStateAuthorized, creates an ARImages using the
     information in the dictionary as input. Otherwise, enqueue the request for when the user
     accepts and SendWorldSensingDataAuthorizationStateAuthorized is set
     
     @param referenceImageDictionary the dictionary representing the ARReferenceImage
     @param completion the promise to be resolved when the image is created
     */
    func createDetectionImage(_ referenceImageDictionary: [AnyHashable : Any], completion: @escaping DetectionImageCreatedCompletionType) {
        switch sendingWorldSensingDataAuthorizationStatus {
        case .authorized, .singlePlane:
            detectionImageCreationPromises?[referenceImageDictionary["uid"] as Any] = completion
            _createDetectionImage(referenceImageDictionary)
        case .denied:
            completion(false, "The user denied access to world sensing data")
        case .notDetermined:
            print("Attempt to create a detection image but world sensing data authorization is not determined, enqueue the request")
            detectionImageCreationPromises?[referenceImageDictionary["uid"] as Any] = completion
            detectionImageCreationRequests.add(referenceImageDictionary)
        default:
            break
        }
    }
    
    func _createDetectionImage(_ referenceImageDictionary: [AnyHashable : Any]) {
        let referenceImage: ARReferenceImage? = createReferenceImage(fromDictionary: referenceImageDictionary)
        let block = detectionImageCreationPromises?[referenceImageDictionary["uid"] as Any] as? DetectionImageCreatedCompletionType
        if referenceImage != nil {
            if let referenceImage = referenceImage {
                referenceImageMap?[referenceImage.name ?? ""] = referenceImage
            }
            print("Detection image created: \(referenceImage?.name ?? "")")
            
            if block != nil {
                block?(true, nil)
            }
        } else {
            print("Cannot create detection image from dictionary: \(String(describing: referenceImageDictionary["uid"]))")
            if block != nil {
                block?(false, "Error creating the ARReferenceImage")
            }
        }
        
        detectionImageCreationPromises[referenceImageDictionary["uid"] as Any] = nil
    }
    
    /**
     Adds the image to the set of references images in the configuration object and re-runs the session.
     
     - If the image hasn't been created, it calls the promise with an error string.
     - It also fails when the current session is not of type ARWorldTrackingConfiguration
     - If the image trying to be activated was already activated but not yet detected, respond with an error string in the callback
     - If the image trying to be activated was already activated and yet detected, we remove it from the session, so
     it can be detected again by ARKit
     
     @param imageName the name of the image to be added to the session. It must have been previously created with createImage
     @param completion a completion block acting a promise
     */
    func activateDetectionImage(_ imageName: String?, completion: @escaping ActivateDetectionImageCompletionBlock) {
        if configuration is ARFaceTrackingConfiguration {
            completion(false, "Cannot activate a detection image when using the front facing camera", nil)
            return
        }
        
        let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
        if let referenceImage = referenceImageMap[imageName ?? ""] as? ARReferenceImage {
            var currentDetectionImages = worldTrackingConfiguration?.detectionImages != nil ? worldTrackingConfiguration?.detectionImages : Set<AnyHashable>()
            if !(currentDetectionImages?.contains(referenceImage) ?? false) {
                _ = currentDetectionImages?.insert(referenceImage)
                if let currentDetectionImages = currentDetectionImages as? Set<ARReferenceImage> {
                    worldTrackingConfiguration?.detectionImages = currentDetectionImages
                }
                
                detectionImageActivationPromises[referenceImage.name ?? ""] = completion
                session?.run(configuration, options: [])
            } else {
                if detectionImageActivationPromises?[referenceImage.name ?? ""] != nil {
                    // Trying to activate an image that hasn't been activated yet, return an error on the second promise, but keep the first
                    completion(false, "Trying to activate an image that's already activated but not found yet", nil)
                    return
                } else {
                    // Activating an already activated and found image, remove the anchor from the scene
                    // so it can be detected again
                    guard let anchors = session.currentFrame?.anchors else { return }
                    for anchor in anchors {
                        if anchor is ARImageAnchor {
                            let imageAnchor = anchor as? ARImageAnchor
                            if imageAnchor?.referenceImage.name == imageName {
                                // Remove the reference image from the session configuration and run again
                                currentDetectionImages?.remove(referenceImage)
                                if let currentDetectionImages = currentDetectionImages as? Set<ARReferenceImage> {
                                    worldTrackingConfiguration?.detectionImages = currentDetectionImages
                                }
                                session?.run(configuration, options: [])
                                
                                // When the anchor is removed and didRemoveAnchor callback gets called, look in this map
                                // and see if there is a promise for the recently removed image anchor. If so, call
                                // activateDetectionImage again with the image name of the removed anchor, and the completion set here
                                detectionImageActivationAfterRemovalPromises[referenceImage.name ?? ""] = completion
                                session?.remove(anchor: anchor)
                                return
                            }
                        }
                    }
                }
            }
        } else {
            completion(false, "The image \(imageName ?? "") doesn't exist", nil)
        }
    }
    
    /**
     Destroys the detection image
     
     - Fails if the image to be destroy doesn't exist
     
     @param imageName The name of the image to be destroyed
     @param completion The completion block that will be called with the outcome of the destroy
     */
    func destroyDetectionImage(_ imageName: String, completion: DetectionImageCreatedCompletionType) {
        let referenceImage = referenceImageMap[imageName] as? ARReferenceImage
        if referenceImage != nil {
            referenceImageMap[imageName] = nil
            detectionImageActivationPromises[imageName] = nil
            completion(true, nil)
        } else {
            completion(false, "The image doesn't exist")
        }
    }
    
    func clearImageDetectionDictionaries() {
        detectionImageActivationPromises.removeAllObjects()
        referenceImageMap.removeAllObjects()
        detectionImageCreationRequests.removeAllObjects()
        detectionImageCreationPromises.removeAllObjects()
        detectionImageActivationAfterRemovalPromises.removeAllObjects()
    }
}
