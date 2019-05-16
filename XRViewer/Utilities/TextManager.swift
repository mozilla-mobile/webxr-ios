import Foundation
import ARKit

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

class TextManager {
    
    // MARK: - Properties
    
    private var viewController: ViewController!
    
    // Timer for hiding messages
    private var messageHideTimer: Timer?
    
    // Timers for showing scheduled messages
    private var focusSquareMessageTimer: Timer?
    private var planeEstimationMessageTimer: Timer?
    private var contentPlacementMessageTimer: Timer?
    
    // Timer for tracking state escalation
    private var trackingStateFeedbackEscalationTimer: Timer?
    
    var schedulingMessagesBlocked = false
    var alertController: UIAlertController?
    
    // MARK: - Initialization
    
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    // MARK: - Message Handling
    
    func showMessage(_ text: String, autoHide: Bool = true) {
        DispatchQueue.main.async {
            // cancel any previous hide timer
            self.messageHideTimer?.invalidate()
            
            // set text
            self.viewController.messageLabel.text = text
            
            // make sure status is showing if not ""
            if text == "" {
                self.showHideMessage(hide: true, animated: true)
            } else {
                self.showHideMessage(hide: false, animated: true)
            }
            
            if autoHide {
                // Compute an appropriate amount of time to display the on screen message.
                // According to https://en.wikipedia.org/wiki/Words_per_minute, adults read
                // about 200 words per minute and the average English word is 5 characters
                // long. So 1000 characters per minute / 60 = 15 characters per second.
                // We limit the duration to a range of 1-10 seconds.
                let charCount = text.count
                let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
                self.messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration,
                                                             repeats: false,
                                                             block: { [weak self] ( _ ) in
                                                                self?.showHideMessage(hide: true, animated: true)
                })
            }
        }
    }
    
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
        // Do not schedule a new message if a feedback escalation alert is still on screen.
        guard !schedulingMessagesBlocked else {
            return
        }
        
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
        timer = Timer.scheduledTimer(withTimeInterval: seconds,
                                     repeats: false,
                                     block: { [weak self] ( _ ) in
                                        self?.showMessage(text)
                                        timer?.invalidate()
                                        timer = nil
        })
        switch messageType {
        case .contentPlacement: contentPlacementMessageTimer = timer
        case .planeEstimation: planeEstimationMessageTimer = timer
        case .trackingStateEscalation: trackingStateFeedbackEscalationTimer = timer
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
        if trackingStateFeedbackEscalationTimer != nil {
            trackingStateFeedbackEscalationTimer!.invalidate()
            trackingStateFeedbackEscalationTimer = nil
        }
        
        trackingStateFeedbackEscalationTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            self.trackingStateFeedbackEscalationTimer?.invalidate()
            self.trackingStateFeedbackEscalationTimer = nil
            
            if let recommendation = trackingState.recommendation {
                self.showMessage(trackingState.presentationString + "\n" + recommendation, autoHide: false)
            } else {
                self.showMessage(trackingState.presentationString, autoHide: false)
            }
        })
    }
    
    // MARK: - Alert View
    
    func showAlert(title: String, message: String, actions: [UIAlertAction]? = nil) {
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let actions = actions {
            for action in actions {
                alertController!.addAction(action)
            }
        } else {
            alertController!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        DispatchQueue.main.async {
            self.viewController.present(self.alertController!, animated: true, completion: nil)
        }
    }
    
    func dismissPresentedAlert() {
        DispatchQueue.main.async {
            self.alertController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Panel Visibility
    
    func showHideMessage(hide: Bool, animated: Bool) {
        if !animated {
            viewController.messageLabel.isHidden = hide
            return
        }
        
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState],
                       animations: {
                        self.viewController.messageLabel.isHidden = hide
                        self.updateMessagePanelVisibility()
        }, completion: nil)
    }
    
    private func updateMessagePanelVisibility() {
        // Show and hide the panel depending whether there is something to show.
        viewController.messagePanel.isHidden = viewController.messageLabel.isHidden
    }
}
