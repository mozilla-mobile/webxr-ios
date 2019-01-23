@objc extension ARKController {
    
    func createReferenceImage(fromDictionary referenceImageDictionary: [AnyHashable: Any]) -> ARReferenceImage {
        let physicalWidth: CGFloat = referenceImageDictionary["physicalWidth"] as? CGFloat ?? 0
        let b64String = referenceImageDictionary["buffer"] as? String
        let width = size_t(referenceImageDictionary["imageWidth"] as? Int ?? 0)
        let height = size_t(referenceImageDictionary["imageHeight"] as? Int ?? 0)
        let bitsPerComponent: size_t = 8
        let bitsPerPixel: size_t = 32
        let bytesPerRow = size_t(width * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        let bitmapInfo = CGBitmapInfo(rawValue: 0)
        let data = Data(base64Encoded: b64String ?? "", options: .ignoreUnknownCharacters)
        let bridgedData: CFData = data! as CFData
        let dataProvider = CGDataProvider.init(data: bridgedData)
        let shouldInterpolate = true
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: bitsPerComponent,
                              bitsPerPixel: bitsPerPixel,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace!,
                              bitmapInfo: bitmapInfo,
                              provider: dataProvider!,
                              decode: nil,
                              shouldInterpolate: shouldInterpolate,
                              intent: CGColorRenderingIntent.defaultIntent)
        let result = ARReferenceImage(cgImage!, orientation: .up, physicalWidth: physicalWidth)
        result.name = referenceImageDictionary["uid"] as? String
        
        return result
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
}
