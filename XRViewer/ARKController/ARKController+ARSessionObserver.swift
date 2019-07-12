extension ARKController: ARSessionObserver {
    
    @objc(session:cameraDidChangeTrackingState:)
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        didChangeTrackingState(camera)
    }
    
    @objc(sessionWasInterrupted:)
    func sessionWasInterrupted(_ session: ARSession) {
        appDelegate().logger.error("sessionWasInterrupted")
        sessionWasInterrupted()
    }
    
    @objc(sessionInterruptionEnded:)
    func sessionInterruptionEnded(_ session: ARSession) {
        appDelegate().logger.error("sessionInterruptionEnded")
        sessionInterruptionEnded()
    }
    
    @objc(session:didFailWithError:)
    func session(_ session: ARSession, didFailWithError error: Error) {
        appDelegate().logger.error("Session didFailWithError - \(error.localizedDescription)")
        didFailSession(error)
    }
    
    @objc(sessionShouldAttemptRelocalization:)
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
