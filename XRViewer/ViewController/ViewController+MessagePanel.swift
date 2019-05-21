enum MessageType {
    case trackingStateEscalation
    case planeEstimation
    case contentPlacement
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "Tracking is unavailable"
        case .normal:
            return ""
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "Limited tracking\nToo much camera movement"
            case .insufficientFeatures:
                return "Limited tracking\nNot enough surface detail"
            case .initializing:
                return "Initializing AR Session"
            case .relocalizing:
                return "Relocalizing\nSlowly scan the space around you"
            }
        }
    }
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        default:
            return nil
        }
    }
}

extension ViewController {
    
    // MARK: - Message Handling
    
    func showMessage(_ text: String, autoHide: Bool = true) {
        weak var blockSelf: ViewController? = self
        DispatchQueue.main.async {
            // cancel any previous hide timer
            blockSelf?.messageHideTimer?.invalidate()
            
            // set text
            blockSelf?.messageLabel.text = text
            
            // make sure status is showing if not ""
            if text == "" {
                blockSelf?.showHideMessage(hide: true)
            } else {
                blockSelf?.showHideMessage(hide: false)
            }
            
            if autoHide {
                // Compute an appropriate amount of time to display the on screen message.
                // According to https://en.wikipedia.org/wiki/Words_per_minute, adults read
                // about 200 words per minute and the average English word is 5 characters
                // long. So 1000 characters per minute / 60 = 15 characters per second.
                // We limit the duration to a range of 1-10 seconds.
                let charCount = text.count
                let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
                blockSelf?.messageHideTimer = Timer.scheduledTimer(
                    withTimeInterval: displayDuration,
                    repeats: false,
                    block: { [weak self] ( _ ) in
                        self?.showHideMessage(hide: true)
                })
            }
        }
    }
    
    func cancelScheduledMessage(forType messageType: MessageType) {
        var timer: Timer?
        switch messageType {
        case .contentPlacement: timer = contentPlacementMessageTimer
        case .planeEstimation: timer = planeEstimationMessageTimer
        case .trackingStateEscalation: timer = trackingStateFeedbackEscalationTimer
        }
        
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
    
    func cancelAllScheduledMessages() {
        cancelScheduledMessage(forType: .contentPlacement)
        cancelScheduledMessage(forType: .planeEstimation)
        cancelScheduledMessage(forType: .trackingStateEscalation)
    }
    
    // MARK: - ARKit
    
    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }
    
    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        weak var blockSelf: ViewController? = self
        
        if trackingStateFeedbackEscalationTimer != nil {
            trackingStateFeedbackEscalationTimer!.invalidate()
            trackingStateFeedbackEscalationTimer = nil
        }
        
        trackingStateFeedbackEscalationTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            blockSelf?.trackingStateFeedbackEscalationTimer?.invalidate()
            blockSelf?.trackingStateFeedbackEscalationTimer = nil
            
            if let recommendation = trackingState.recommendation {
                blockSelf?.showMessage(trackingState.presentationString + "\n" + recommendation, autoHide: false)
            } else {
                blockSelf?.showMessage(trackingState.presentationString, autoHide: false)
            }
        })
    }
    
    // MARK: - Panel Visibility
    
    func showHideMessage(hide: Bool) {
        messageLabel.isHidden = hide
        messagePanel.isHidden = hide
    }
}
