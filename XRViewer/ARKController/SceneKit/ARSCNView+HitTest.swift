import ARKit

typealias HitTestResultBlock = (HitTestResult?) -> Void

extension ARSCNView {
    
    // MARK: - Types
    
    struct HitTestRay {
        let origin: float3
        let direction: float3
    }
    
    struct FeatureHitTestResult {
        let position: float3
        let distanceToRayOrigin: Float
        let featureHit: float3
        let featureDistanceToHitResult: Float
    }
    
    func unprojectPoint(_ point: float3) -> float3 {
        return float3(self.unprojectPoint(SCNVector3(point)))
    }
    
    // MARK: - Hit Tests
    
    func hitTest(point: CGPoint, withResult resultBlock: HitTestResultBlock) -> [Any]? {
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)

        let planeHitTestResult = hitTest(point, types: .existingPlaneUsingExtent)

        if planeHitTestResult.count > 0 {
            let result: ARHitTestResult? = planeHitTestResult.first

            let planeAnchor = result?.anchor as? ARPlaneAnchor
            let planeHitTestPosition: SCNVector3 = SCNVector3Make(result?.worldTransform.columns.3.x ?? 0.0, result?.worldTransform.columns.3.y ?? 0.0, result?.worldTransform.columns.3.z ?? 0.0)

            let r = HitTestResult()
            r.anchor = planeAnchor
            r.position = planeHitTestPosition
            r.hightQuality = true

            resultBlock(r)

            return planeHitTestResult
        }

        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.

        let hightQualityFeatureHitTestResult = hitTestWithFeatures(point, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2, maxResults: 1)

        var featureHitTestPosition: SCNVector3 = SCNVector3Zero
        var highQualityFeatureHitTestResult = false

        if (hightQualityFeatureHitTestResult.count) > 0 {
            let result = hightQualityFeatureHitTestResult.first
            if let aPosition = result?.position {
                featureHitTestPosition = SCNVector3(aPosition)
            }
            highQualityFeatureHitTestResult = true
        }

        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        /*BOOL useInfinite = NO;
            
            if (useInfinite || highQualityFeatureHitTestResult == NO)
            {
                SCNVector3 pointOnInfinitePlane = [self hitTestWithInfiniteHorizontalPlane:point pointOnPlane:[_focus position]];
                
                if (SCNVector3EqualToVector3(pointOnInfinitePlane, SCNVector3Zero))
                {
                    //[_focus unhide];
                    //[_focus updateForPosition:pointOnInfinitePlane planeAnchor:nil camera:[[[self session] currentFrame] camera]];
                    
                    //[self setHiTestResults:planeHitTestResult];
                    
                    resultBlock(YES, pointOnInfinitePlane, nil);
                    
                    return;
                }
            }*/

        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.

        if highQualityFeatureHitTestResult {
            let r = HitTestResult()
            r.position = featureHitTestPosition
            r.hightQuality = true

            resultBlock(r)

            return planeHitTestResult
        }


        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.

        let unfilteredFeatureHitTestResults = hitTestWithFeatures(point)

        if (unfilteredFeatureHitTestResults.count) > 0 {
            guard let result = unfilteredFeatureHitTestResults.first else {
                resultBlock(nil)
                return planeHitTestResult
            }

            let r = HitTestResult()
            r.position = SCNVector3(result.position)
            r.hightQuality = false

            resultBlock(r)

            return planeHitTestResult
        }

        resultBlock(nil)

        return planeHitTestResult
    }

    func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
        
        guard let frame = self.session.currentFrame else {
            return nil
        }
        
        let cameraPos = frame.camera.transform.translation
        
        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = float3(x: Float(point.x), y: Float(point.y), z: 1.0)
        let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
        
        let rayDirection = simd_normalize(screenPosOnFarClippingPlane - cameraPos)
        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }

    func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: float3) -> float3? {
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return nil
        }
        
        // Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
        if ray.direction.y > -0.03 {
            return nil
        }
        
        // Return the intersection of a ray from the camera through the screen position with a horizontal plane
        // at height (Y axis).
        return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
    }

    func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {
        
        let direction = simd_normalize(direction)
        
        // Special case handling: Check if the ray is horizontal as well.
        if direction.y == 0 {
            if rayOrigin.y == planeY {
                // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
                // Therefore we simply return the ray origin.
                return rayOrigin
            } else {
                // The ray is parallel to the plane and never intersects.
                return nil
            }
        }
        
        // The distance from the ray's origin to the intersection point on the plane is:
        //   (pointOnPlane - rayOrigin) dot planeNormal
        //  --------------------------------------------
        //          direction dot planeNormal
        
        // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
        let dist = (planeY - rayOrigin.y) / direction.y
        
        // Do not return intersections behind the ray's origin.
        if dist < 0 {
            return nil
        }
        
        // Return the intersection point.
        return rayOrigin + (direction * dist)
    }

    func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float,
                             minDistance: Float = 0,
                             maxDistance: Float = Float.greatestFiniteMagnitude,
                             maxResults: Int = 1) -> [FeatureHitTestResult] {
        
        var results = [FeatureHitTestResult]()
        
        guard let features = self.session.currentFrame?.rawFeaturePoints else {
            return results
        }
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }
        
        let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
        let maxAngle = (maxAngleInDeg / 180) * .pi
        
        let points = features.__points
        
        for i in 0...features.__count {
            
            let feature = points.advanced(by: Int(i))
            let featurePos = feature.pointee
            
            let originToFeature = featurePos - ray.origin
            
            let crossProduct = simd_cross(originToFeature, ray.direction)
            let featureDistanceFromResult = simd_length(crossProduct)
            
            let hitTestResult = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
            let hitTestResultDistance = simd_length(hitTestResult - ray.origin)
            
            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
                // Skip this feature - it is too close or too far away.
                continue
            }
            
            let originToFeatureNormalized = simd_normalize(originToFeature)
            let angleBetweenRayAndFeature = acos(simd_dot(ray.direction, originToFeatureNormalized))
            
            if angleBetweenRayAndFeature > maxAngle {
                // Skip this feature - is is outside of the hit test cone.
                continue
            }
            
            // All tests passed: Add the hit against this feature to the results.
            results.append(FeatureHitTestResult(position: hitTestResult,
                                                distanceToRayOrigin: hitTestResultDistance,
                                                featureHit: featurePos,
                                                featureDistanceToHitResult: featureDistanceFromResult))
        }
        
        // Sort the results by feature distance to the ray.
        results = results.sorted(by: { (first, second) -> Bool in
            return first.distanceToRayOrigin < second.distanceToRayOrigin
        })
        
        // Cap the list to maxResults.
        var cappedResults = [FeatureHitTestResult]()
        var i = 0
        while i < maxResults && i < results.count {
            cappedResults.append(results[i])
            i += 1
        }
        
        return cappedResults
    }

    func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
        
        var results = [FeatureHitTestResult]()
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }
        
        if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
            results.append(result)
        }
        
        return results
    }

    func hitTestFromOrigin(origin: float3, direction: float3) -> FeatureHitTestResult? {
        
        guard let features = self.session.currentFrame?.rawFeaturePoints else {
            return nil
        }
        
        let points = features.__points
        
        // Determine the point from the whole point cloud which is closest to the hit test ray.
        var closestFeaturePoint = origin
        var minDistance = Float.greatestFiniteMagnitude
        
        for i in 0...features.__count {
            let feature = points.advanced(by: Int(i))
            let featurePos = feature.pointee
            
            let originVector = origin - featurePos
            let crossProduct = simd_cross(originVector, direction)
            let featureDistanceFromResult = simd_length(crossProduct)
            
            if featureDistanceFromResult < minDistance {
                closestFeaturePoint = featurePos
                minDistance = featureDistanceFromResult
            }
        }
        
        // Compute the point along the ray that is closest to the selected feature.
        let originToFeature = closestFeaturePoint - origin
        let hitTestResult = origin + (direction * simd_dot(direction, originToFeature))
        let hitTestResultDistance = simd_length(hitTestResult - origin)
        
        return FeatureHitTestResult(position: hitTestResult,
                                    distanceToRayOrigin: hitTestResultDistance,
                                    featureHit: closestFeaturePoint,
                                    featureDistanceToHitResult: minDistance)
    }
    
    // MARK: - Helpers

    func normalize(_ vector: SCNVector3) -> SCNVector3 {
        let length: CGFloat = lengthVector(vector)

        if length == 0 {
            return vector
        }

        return SCNVector3Make(Float(CGFloat(vector.x) / length), Float(CGFloat(vector.y) / length), Float(CGFloat(vector.z) / length))
    }

    func lengthVector(_ vector: SCNVector3) -> CGFloat {
        return CGFloat(sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z))
    }

    func vector(_ vector: SCNVector3, crossWith crossVector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(vector.y * crossVector.z - vector.z * crossVector.y, vector.z * crossVector.x - vector.x * crossVector.z, vector.x * crossVector.y - vector.y * crossVector.x)
    }

    func vector(_ vector: SCNVector3, dotVector: SCNVector3) -> CGFloat {
        return CGFloat((vector.x * dotVector.x) + (vector.y * dotVector.y) + (vector.z * dotVector.z))
    }
}

// MARK: - float4x4 extensions

extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
