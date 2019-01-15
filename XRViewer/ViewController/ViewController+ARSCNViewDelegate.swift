import ARKit
import CocoaLumberjack

extension ViewController: ARSCNViewDelegate {
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        switch camera.trackingState {
        case .notAvailable:
            fallthrough
        case .limited:
            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DDLogError("sessionWasInterrupted")
        textManager.blurBackground()
        overlayController?.setARKitInterruption(true)
        messageController?.showMessageAboutARInterruption(true)
        webController?.wasARInterruption(true)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DDLogError("sessionInterruptionEnded")
        textManager.unblurBackground()
        textManager.showMessage("Resetting...")
        overlayController?.setARKitInterruption(false)
        messageController?.showMessageAboutARInterruption(false)
        webController?.wasARInterruption(false)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
