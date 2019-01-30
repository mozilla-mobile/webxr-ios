@objc extension ARKController {
    
    // MARK: - Saving
    
    /**
     Save the current tracker World Map in local storage
     
     - Fails if tracking isn't initialized, or if the acquisition of a World Map fails for some other reason
     */
    func saveWorldMap() {
        if !trackingStateNormal() {
            DDLogError("Can't save WorldMap to local storage until tracking is initialized")
            return
        }
        
        if !worldMappingAvailable() {
            DDLogError("Can't save WorldMap to local storage until World Mapping has started")
            return
        }
        
        session?.getCurrentWorldMap(completionHandler: { worldMap, error in
            if let worldMap = worldMap {
                DDLogError("saving WorldMap to local storage")
                self._save(worldMap)
            } else {
                // try to get rid of an old one if it exists.  Don't care if this fails.
                if let worldSaveURL = self.worldSaveURL {
                    try? FileManager.default.trashItem(at: worldSaveURL, resultingItemURL: nil)
                }
                DDLogError("moving saved WorldMap to trash")
            }
        })
    }
    
    func _save(_ worldMap: ARWorldMap) {
        if let worldSaveURL = worldSaveURL {
            var data: Data? = nil
            data = try? NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            do {
                try data?.write(to: worldSaveURL, options: .atomic)
                DDLogError("saved WorldMap to load storage at \(worldSaveURL)")
            } catch {
                DDLogError("Failed saving WorldMap to persistent storage")
            }
        }
    }
    
    // MARK: - Loading
    
    // MARK: - Helpers
    
    func printWorldMapInfo(_ worldMap: ARWorldMap) {
        let anchors = worldMap.anchors
        for anchor in anchors {
            var anchorID: String
            if anchor is ARPlaneAnchor {
                // ARKit system plane anchor; probably shouldn't happen!
                anchorID = anchor.identifier.uuidString
                DDLogWarn("saved WorldMap: contained PlaneAnchor")
            } else if anchor is ARImageAnchor {
                // User generated ARImageAnchor; probably shouldn't happen!
                let imageAnchor = anchor as? ARImageAnchor
                anchorID = imageAnchor?.referenceImage.name ?? "No name stored for this imageAnchor's referenceImage"
                DDLogWarn("saved WorldMap: contained trackable ImageAnchor")
            } else if anchor is ARFaceAnchor {
                // System generated ARFaceAnchor; probably shouldn't happen!
                anchorID = anchor.identifier.uuidString
                DDLogWarn("saved WorldMap: contained trackable FaceAnchor")
            } else {
                anchorID = anchor.name ?? "No name stored for this anchor"
            }
            print("WorldMap contains anchor: \(anchorID)")
        }
        let center: simd_float3 = worldMap.center
        let extent: simd_float3 = worldMap.extent
        print("Map center: \(center.x), \(center.y), \(center.z)")
        print("Map extent: \(extent.x), \(extent.y), \(extent.z)")
    }
    
    func worldMappingAvailable() -> Bool {
        guard let ws = session?.currentFrame?.worldMappingStatus else { return false }
        return ws != .notAvailable
    }
    
    /**
     Is there a saved world map?
     */
    func hasBackgroundWorldMap() -> Bool {
        return backgroundWorldMap != nil
    }
}
