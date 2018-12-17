import UIKit

class TouchView: UIView {
    
    private var cameraAction: HotAction?
    private var micAction: HotAction?
    private var showAction: HotAction?
    private var debugAction: HotAction?
    private var cameraRect = CGRect.zero
    private var micRect = CGRect.zero
    private var showRect = CGRect.zero
    private var debugRect = CGRect.zero
    private var cameraEvent = false
    private var micEvent = false
    private var showEvent = false
    private var debugEvent = false
    private var startTouchDate: Date?
    private var touchTimer: Timer?
    var showMode: ShowMode?
    var showOptions: ShowOptions?
    private var recordState: RecordState?
    let MAX_INCREASE_ZONE_SIZE = 10
    private var increaseHotZoneValue: CGFloat = 0.0
    
    @objc init(frame: CGRect, cameraAction: @escaping HotAction, micAction: @escaping HotAction, showAction: @escaping HotAction, debugAction: @escaping HotAction) {
        super.init(frame: frame)
        
        self.cameraAction = cameraAction
        self.micAction = micAction
        self.showAction = showAction
        self.debugAction = debugAction
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func setProcessTouches(_ process: Bool) {
        (superview as? LayerView)?.processTouchInSubview = process
    }
    
    @objc func setCameraRect(_ cameraRect: CGRect, micRect: CGRect, showRect: CGRect, debugRect: CGRect) {
        self.cameraRect = cameraRect
        self.micRect = micRect
        self.showRect = showRect
        self.debugRect = debugRect
        
        updateIncreaseHotZoneValue()
    }
    
    @objc func setShowMode(_ mode: ShowMode) {
        showMode = mode
    }
    
    @objc func setShowOptions(_ options: ShowOptions) {
        showOptions = options
    }
    
    @objc func setRecordState(_ state: RecordState) {
        recordState = state
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if (superview as? LayerView)?.processTouchInSubview == false {
            return false
        }
        
        if showMode == ShowMode.nothing {
            return false
        }
        guard let showMode = showMode else { return false }
        guard let showOptions = showOptions else { return false }
        if (showMode.rawValue >= ShowMode.multi.rawValue) && (showOptions.rawValue & ShowOptions.Capture.rawValue) != 0 && increasedRect(cameraRect).contains(point) {
            self.cameraEvent = true
            return true
        } else {
            if (showMode.rawValue >= ShowMode.multi.rawValue) && (showOptions.rawValue & ShowOptions.Mic.rawValue) != 0 && increasedRect(micRect).contains(point) {
                self.micEvent = true
                self.cameraEvent = false
                return true
            }
            /*
             This functionality is not needed anymore, since we are showing/hiding the debug buttons when swipping down/up
             
             if (CGRectContainsPoint([self increasedRect:[self showRect]], point))
             {
             if (([self recordState] == RecordStateRecording) || ([self recordState] == RecordStateRecordingWithMicrophone))
             {
             return NO;
             }
             
             [self setShowEvent:YES];
             [self setCameraEvent:NO];
             return YES;
             }
             if (([self showMode] >= ShowMulti) && ([self showOptions] & Debug) && CGRectContainsPoint([self debugRect], point))
             {
             [self setDebugEvent:YES];
             [self setCameraEvent:NO];
             return YES;
             }
             */
        }
        
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if cameraEvent {
            self.startTouchDate = Date()
            
            weak var blockSelf: TouchView? = self
            
            self.touchTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(RECORD_LONG_TAP_DURATION), repeats: false, block: { timer in
                guard let cameraAction = blockSelf?.cameraAction else { return }
                cameraAction(true)
                blockSelf?.cameraEvent = false
                timer.invalidate()
                blockSelf?.touchTimer = nil
            })
        } else if micEvent {
            guard let micAction = micAction else { return }
            micAction(true)
            self.micEvent = false
        } else if showEvent {
            guard let showAction = showAction else { return }
            showAction(true)
            self.showEvent = false
        } else if debugEvent {
            guard let debugAction = debugAction else { return }
            debugAction(true)
            self.debugEvent = false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchTimer != nil {
            guard let cameraAction = cameraAction else { return }
            cameraAction(false)
            self.cameraEvent = false
            
            touchTimer?.invalidate()
            self.touchTimer = nil
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchTimer != nil {
            guard let cameraAction = cameraAction else { return }
            cameraAction(false)
            self.cameraEvent = false
            
            touchTimer?.invalidate()
            self.touchTimer = nil
        }
    }
    
    func updateIncreaseHotZoneValue() {
        let bottomYMin = showRect.minY
        let topYMax = cameraRect.maxY
        
        let increase = fminf(Float(MAX_INCREASE_ZONE_SIZE), abs(Float(bottomYMin - topYMax)) / 2)
        
        self.increaseHotZoneValue = CGFloat(increase)
    }
    
    func increasedRect(_ rect: CGRect) -> CGRect {
        return CGRect(x: rect.origin.x - increaseHotZoneValue, y: rect.origin.y - increaseHotZoneValue, width: rect.size.width + increaseHotZoneValue * 2, height: rect.size.height + increaseHotZoneValue * 2)
    }
}
