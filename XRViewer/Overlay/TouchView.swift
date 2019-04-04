import UIKit

class TouchView: UIView {
    
    private var debugAction: HotAction?
    private var cameraRect = CGRect.zero
    private var micRect = CGRect.zero
    private var showRect = CGRect.zero
    private var debugRect = CGRect.zero
    private var debugEvent = false
    private var startTouchDate: Date?
    private var touchTimer: Timer?
    var showMode: ShowMode?
    var showOptions: ShowOptions?
    let MAX_INCREASE_ZONE_SIZE = 10
    private var increaseHotZoneValue: CGFloat = 0.0
    
    @objc init(frame: CGRect, debugAction: @escaping HotAction) {
        super.init(frame: frame)
        
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
    
    func setShowMode(_ mode: ShowMode) {
        showMode = mode
    }
    
    @objc func setShowOptions(_ options: ShowOptions) {
        showOptions = options
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if (superview as? LayerView)?.processTouchInSubview == false {
            return false
        }
        
        if showMode == ShowMode.nothing {
            return false
        }

        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if debugEvent {
            guard let debugAction = debugAction else { return }
            debugAction(true)
            self.debugEvent = false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchTimer != nil {
            
            touchTimer?.invalidate()
            self.touchTimer = nil
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchTimer != nil {
            
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
