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
    
    func worldMappingAvailable() -> Bool {
        guard let ws = session?.currentFrame?.worldMappingStatus else { return false }
        return ws != .notAvailable
    }
}
