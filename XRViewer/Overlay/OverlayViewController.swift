import UIKit

class OverlayViewController: UIViewController {
    
    private var showMode: ShowMode?
    private var showOptions: ShowOptions?
    private var microphoneEnabled = false
    private var recordButton: UIButton?
    private var trackingStateButton: UIButton?
    private var micButton: UIButton?
    private var recordTimingLabel: UILabel?
    private var recordDot: UIView?
    private var helperLabel: UILabel?
    private var buildLabel: UILabel?
    private var startRecordDate: Date?
    private var timer: Timer?
    var animator: Animator?
    
    let HELP_LABEL_HEIGHT: CGFloat = 16
    let HELP_LABEL_WIDTH: CGFloat = 350
    let RECORD_LABEL_OFFSET_X: CGFloat = 4.5
    let RECORD_LABEL_WIDTH: CGFloat = 80
    let RECORD_LABEL_HEIGHT: CGFloat = 12
    let DOT_SIZE: CGFloat = 6
    let DOT_OFFSET_Y: CGFloat = 9.5
    let TRACK_SIZE_W: CGFloat = 256
    let TRACK_SIZE_H: CGFloat = 62
    
    deinit {
        DDLogDebug("OverlayViewController dealloc")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override var prefersStatusBarHidden: Bool {
        return super.prefersStatusBarHidden
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .top
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        view.isHidden = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        viewWillTransition(to: size)
    }

    func setShowMode(_ showMode: ShowMode, withAnimationCompletion completion: Completion) {
        self.showMode = showMode

        update(with: completion)
    }

    func setShowOptions(_ showOptions: ShowOptions, withAnimationCompletion completion: Completion) {
        self.showOptions = showOptions

        update(with: completion)
    }

    func setMicrophoneEnabled(_ microphoneEnabled: Bool, withAnimationCompletion completion: @escaping Completion) {
        self.microphoneEnabled = microphoneEnabled

        micButton?.isSelected = microphoneEnabled

        DispatchQueue.main.async(execute: {
            completion(true)
        })
    }

    func viewWillTransition(to size: CGSize) {
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        var updRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        if showMode.rawValue >= ShowMode.multi.rawValue {
            if showOptions.rawValue & ShowOptions.Browser.rawValue != 0 {
                updRect.origin.y = CGFloat(Constant.urlBarHeight())
            }
        }
        
        weak var blockSelf: OverlayViewController? = self
        animator?.animate(micButton, toFrame: micFrameIn(viewRect: updRect))
        
        if blockSelf?.showMode == ShowMode.single {
            // delay for show camera, mic frame animations
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                blockSelf?.animator?.animate(blockSelf?.recordButton, toFade: true)
                blockSelf?.animator?.animate(blockSelf?.micButton, toFade: true)
            })
        }
        
        helperLabel?.frame = helperLabelFrameIn(viewRect: updRect)
        helperLabel?.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        
        trackingStateButton?.frame = trackFrameIn(viewRect: updRect)
        recordDot?.frame = dotFrameIn(viewRect: updRect)
        recordTimingLabel?.frame = recordLabelFrameIn(viewRect: updRect)
        buildLabel?.frame = buildFrameIn(viewRect: updRect)
    }
    // common visibility
    
    func update(with completion: Completion) {
        viewWillTransition(to: view.bounds.size)
        guard let showMode = showMode else { return }
        
        switch showMode {
        case .nothing:
            animator?.animate(recordButton, toFade: true)
            animator?.animate(micButton, toFade: true)
            animator?.animate(helperLabel, toFade: true)
            animator?.animate(buildLabel, toFade: true)
            animator?.animate(recordDot, toFade: true)
            timer?.invalidate()
            completion(true)
        case .single:
            animator?.animate(helperLabel, toFade: true)
            animator?.animate(buildLabel, toFade: true)
            animator?.animate(recordDot, toFade: true)
            animator?.animate(recordTimingLabel, toFade: true)
            timer?.invalidate()
            completion(true)
        case .debug:
            animator?.animate(recordButton, toFade: true)
            animator?.animate(micButton, toFade: true)
            animator?.animate(helperLabel, toFade: true)
            animator?.animate(buildLabel, toFade: true)
            animator?.animate(recordDot, toFade: true)
            timer?.invalidate()
            completion(true)
        case .multi:
            completion(true)
        case .multiDebug:
            completion(true)
        default:
            break
        }
    }
    
    func setTrackingState(_ state: String?, withAnimationCompletion completion: @escaping Completion) {
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        
        if showMode.rawValue >= ShowMode.nothing.rawValue {
            if showOptions.rawValue & ShowOptions.ARWarnings.rawValue != 0 {
                if (state == WEB_AR_TRACKING_STATE_NORMAL) {
                    animator?.animate(trackingStateButton, toFade: true) { finish in
                        self.trackingStateButton?.setImage(nil, for: .normal)
                        completion(finish)
                    }
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitNotInitialized"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitLimitedInitializing"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED_FEATURES) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "NotEnoughVisualFeatures"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED_MOTION) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "MovingTooFast"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_NOT_AVAILABLE) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitNotAvailable"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_RELOCALIZING) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitRelocalizing"), for: .normal)
                }
                
                return
            }
        }
        
        trackingStateButton?.setImage(nil, for: .normal)
    }
    
    func setTrackingState(_ state: String?, withAnimationCompletion completion: @escaping Completion, sceneHasPlanes hasPlanes: Bool) {
        guard let showOptions = showOptions else { return }
        guard let showMode = showMode else { return }
        
        if showMode.rawValue >= ShowMode.nothing.rawValue {
            if showOptions.rawValue & ShowOptions.ARWarnings.rawValue != 0 {
                if (state == WEB_AR_TRACKING_STATE_NORMAL) {
                    if hasPlanes {
                        animator?.animate(trackingStateButton, toFade: true) { finish in
                            self.trackingStateButton?.setImage(nil, for: .normal)
                            completion(finish)
                        }
                    } else {
                        animator?.animate(trackingStateButton, toFade: false) { finish in
                            completion(finish)
                        }
                        
                        trackingStateButton?.setImage(UIImage(named: "NoPlanesDetectedYet"), for: .normal)
                    }
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitNotInitialized"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED_INITIALIZING) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitLimitedInitializing"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED_FEATURES) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "NotEnoughVisualFeatures"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_LIMITED_MOTION) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "MovingTooFast"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_NOT_AVAILABLE) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitNotAvailable"), for: .normal)
                } else if (state == WEB_AR_TRACKING_STATE_RELOCALIZING) {
                    animator?.animate(trackingStateButton, toFade: false) { finish in
                        completion(finish)
                    }
                    
                    trackingStateButton?.setImage(UIImage(named: "ARKitRelocalizing"), for: .normal)
                }
                
                return
            }
        }
        
        trackingStateButton?.setImage(nil, for: .normal)
    }

    func setup() {
        self.recordButton = UIButton(type: .custom)
        view.addSubview(recordButton!)
        
        self.micButton = UIButton(type: .custom)
        micButton?.setImage(UIImage(named: "micOff"), for: .normal)
        micButton?.setImage(UIImage(named: "mic"), for: .selected)
        view.addSubview(micButton!)
        
        self.trackingStateButton = UIButton(type: .custom)
        trackingStateButton?.frame = trackFrameIn(viewRect: view.bounds)
        trackingStateButton?.contentVerticalAlignment = .fill
        trackingStateButton?.contentHorizontalAlignment = .fill
        view.addSubview(trackingStateButton!)
        
        self.recordDot = UIView(frame: dotFrameIn(viewRect: view.bounds))
        recordDot?.layer.cornerRadius = CGFloat(Double(DOT_SIZE) / 2.0)
        recordDot?.backgroundColor = UIColor.red
        view.addSubview(recordDot!)
        
        self.recordTimingLabel = UILabel(frame: recordLabelFrameIn(viewRect: view.bounds))
        recordTimingLabel?.font = UIFont.systemFont(ofSize: 12)
        recordTimingLabel?.textAlignment = .left
        recordTimingLabel?.textColor = UIColor.white
        recordTimingLabel?.backgroundColor = UIColor.clear
        recordTimingLabel?.clipsToBounds = true
        view.addSubview(recordTimingLabel!)
        
        self.helperLabel = UILabel(frame: helperLabelFrameIn(viewRect: view.bounds))
        helperLabel?.font = UIFont.systemFont(ofSize: 12)
        helperLabel?.textAlignment = .center
        helperLabel?.textColor = UIColor.white
        helperLabel?.backgroundColor = UIColor.clear
        helperLabel?.clipsToBounds = true
        view.addSubview(helperLabel!)
        
        self.buildLabel = UILabel(frame: buildFrameIn(viewRect: view.bounds))
        buildLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        buildLabel?.textAlignment = .center
        buildLabel?.textColor = UIColor.white
        buildLabel?.backgroundColor = UIColor(white: 0, alpha: 0.0)
        buildLabel?.text = versionBuild()
        view.addSubview(buildLabel!)
        
        viewWillTransition(to: view.bounds.size)

        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }
    
    func appVersion() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    func build() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }
    
    func versionBuild() -> String? {
        let version = appVersion()
        let build = self.build()
        
        var versionBuild = "v\(version ?? "")"
        
        if version != build {
            versionBuild = "\(versionBuild)(\(build ?? ""))"
        }
        
        return versionBuild
    }
    
    // MARK: - UI Placement Helpers
    
    func recordFrameIn(viewRect: CGRect) -> CGRect {
        let x = viewRect.size.width - Constant.recordSize() - Constant.recordOffsetX()
        let y = viewRect.origin.y + (viewRect.size.height - viewRect.origin.y / 2) - Constant.recordSize() / 2
        return CGRect(x: x, y: y, width: Constant.recordSize(), height: Constant.recordSize())
    }
    
    func micFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width - Constant.recordSize() - Constant.recordOffsetX() + (Constant.recordSize() - Constant.micSizeW()) / 2, y: viewRect.origin.y + Constant.recordOffsetY(), width: Constant.micSizeW(), height: Constant.micSizeH())
    }
    
    func debugFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: Constant.recordOffsetX(), y: viewRect.size.height - Constant.recordOffsetY() - Constant.micSizeH(), width: Constant.micSizeW(), height: Constant.micSizeH())
    }
    
    func showFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width - Constant.recordOffsetX() - Constant.micSizeW(), y: viewRect.size.height - Constant.recordOffsetY() - Constant.micSizeH(), width: Constant.micSizeW(), height: Constant.micSizeH())
    }
    
    private func trackFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width / 2 - (TRACK_SIZE_W / 2), y: viewRect.size.height - Constant.recordOffsetY() - Constant.micSizeH() / 2 - TRACK_SIZE_H / 2, width: TRACK_SIZE_W, height: TRACK_SIZE_H)
    }
    
    private func dotFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width / 2 - (DOT_SIZE / 2), y: viewRect.origin.y + DOT_OFFSET_Y, width: DOT_SIZE, height: DOT_SIZE)
    }
    
    private func recordLabelFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width / 2 + (DOT_SIZE / 2) + RECORD_LABEL_OFFSET_X, y: viewRect.origin.y + DOT_OFFSET_Y - (RECORD_LABEL_HEIGHT - DOT_SIZE) / 2, width: RECORD_LABEL_WIDTH, height: RECORD_LABEL_HEIGHT)
    }
    
    private func helperLabelFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width - HELP_LABEL_HEIGHT - 5, y: viewRect.origin.y, width: HELP_LABEL_HEIGHT, height: viewRect.size.height - viewRect.origin.y) // rotate
    }
    
    private func buildFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width / 2 - (RECORD_LABEL_WIDTH / 2), y: viewRect.size.height - RECORD_LABEL_HEIGHT - 4, width: RECORD_LABEL_WIDTH, height: RECORD_LABEL_HEIGHT)
    }
}
