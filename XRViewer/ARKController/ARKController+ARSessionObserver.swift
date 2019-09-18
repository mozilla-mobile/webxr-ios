import ARKit

extension ARKController: ARSessionObserver {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        didChangeTrackingState?(camera)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        appDelegate().logger.error("sessionWasInterrupted")
        sessionWasInterrupted?()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        appDelegate().logger.error("sessionInterruptionEnded")
        sessionInterruptionEnded?()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        appDelegate().logger.error("Session didFailWithError - \(error.localizedDescription)")
        didFailSession?(error)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
