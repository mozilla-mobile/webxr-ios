import UIKit

class OverlayViewController: UIViewController {
    
    private var recordState: RecordState?
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

    func setRecordState(_ recordState: RecordState, withAnimationCompletion completion: Completion) {
        self.recordState = recordState

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
        guard let recordState = recordState else { return }
        var updRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        if showMode.rawValue >= ShowMode.multi.rawValue {
            if showOptions.rawValue & ShowOptions.Browser.rawValue != 0 {
                if (recordState == .isReady) || (recordState == .goingToRecording) || (recordState.rawValue >= RecordState.previewing.rawValue) {
                    updRect.origin.y = CGFloat(URL_BAR_HEIGHT)
                }
            }
        }
        
        weak var blockSelf: OverlayViewController? = self
        animator?.animate(micButton, toFrame: micFrameIn(updRect))
        animator?.animate(recordButton, toFrame: recordFrameIn(updRect)) { f in
            if blockSelf?.recordState == .photo {
                blockSelf?.animator?.animate(blockSelf?.recordButton, toFade: true)
                blockSelf?.animator?.animate(blockSelf?.micButton, toFade: true)
            } else if (blockSelf?.recordState == .recording) || (blockSelf?.recordState == .recordingWithMicrophone) {
                if let anOptions = blockSelf?.showOptions {
                    blockSelf?.animator?.animate(blockSelf?.recordButton, toFade: (anOptions.rawValue & ShowOptions.Capture.rawValue) != 0 ? false : true)
                    blockSelf?.animator?.animate(blockSelf?.micButton, toFade: (anOptions.rawValue & ShowOptions.Mic.rawValue) != 0 ? false : true)
                }
            }
        }
        
        if blockSelf?.showMode == ShowMode.single {
            // delay for show camera, mic frame animations
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                blockSelf?.animator?.animate(blockSelf?.recordButton, toFade: true)
                blockSelf?.animator?.animate(blockSelf?.micButton, toFade: true)
            })
        }
        
        helperLabel?.frame = helperLabelFrameIn(updRect)
        helperLabel?.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        
        trackingStateButton?.frame = trackFrameIn(updRect)
        recordDot?.frame = dotFrameIn(updRect)
        recordTimingLabel?.frame = recordLabelFrameIn(updRect)
        buildLabel?.frame = buildFrameIn(updRect)
        
        if recordState == .authDisabled {
            recordButton?.setImage(UIImage(named: "camDisabled"), for: .normal)
            recordButton?.setImage(UIImage(named: "camDisabled"), for: .selected)
            micButton?.setImage(UIImage(named: "micDisabled"), for: .normal)
            micButton?.setImage(UIImage(named: "micDisabled"), for: .selected)
        } else {
            recordButton?.setImage(UIImage(named: "cam"), for: .normal)
            recordButton?.setImage(UIImage.animatedImage(with: [UIImage(named: "cam")!, UIImage(named: "camPress")!], duration: TimeInterval(animator?.animationDuration ?? 0.0)), for: .selected)
            micButton?.setImage(UIImage(named: "micOff"), for: .normal)
            micButton?.setImage(UIImage(named: "mic"), for: .selected)
        }
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
            updateWithRecordState(inDebug: false)
            completion(true)
        case .multiDebug:
            updateWithRecordState(inDebug: true)
            completion(true)
        default:
            break
        }
    }


    func updateWithRecordState(inDebug debug: Bool) {
        guard let recordState = recordState else { return }
        guard let showOptions = showOptions else { return }
        
        if recordState == .recordingWithMicrophone {
            microphoneEnabled = true
        } else if recordState == .recording {
            microphoneEnabled = false
        }

        switch recordState {
            case .isReady:
                animator?.animate(recordButton, toFade: (showOptions.rawValue & ShowOptions.Capture.rawValue) != 0 ? false : true)
                animator?.animate(micButton, toFade: (showOptions.rawValue & ShowOptions.Mic.rawValue) != 0 ? false : true)
                animator?.animate(helperLabel, toFade: (showOptions.rawValue & ShowOptions.Capture.rawValue) != 0 ? false : true)
                animator?.animate(buildLabel, toFade: (debug && (showOptions.rawValue & ShowOptions.BuildNumber.rawValue) != 0) ? false : true)
                animator?.animate(recordDot, toFade: true)
                animator?.animate(recordTimingLabel, toFade: true)
                recordButton?.isSelected = false
                micButton?.isSelected = microphoneEnabled
                helperLabel?.text = HELP_TEXT
                helperLabel?.textColor = UIColor.white
                timer?.invalidate()
                animator?.stopPulseAnimation(recordButton)
            case .photo:
                animator?.animate(helperLabel, toFade: true)
                animator?.animate(buildLabel, toFade: (debug && (showOptions.rawValue & ShowOptions.BuildNumber.rawValue) != 0) ? false : true)
                animator?.animate(recordDot, toFade: true)
                animator?.animate(recordTimingLabel, toFade: true)

                recordButton?.setImage(UIImage(named: "camTap"), for: .selected)
                recordButton?.isSelected = true
                micButton?.isSelected = microphoneEnabled

                helperLabel?.text = HELP_TEXT
                helperLabel?.textColor = UIColor.white
                timer?.invalidate()
            case .goingToRecording:
                break
            case .recordingWithMicrophone, .recording:
                animator?.animate(helperLabel, toFade: true)
                animator?.animate(buildLabel, toFade: (debug && (showOptions.rawValue & ShowOptions.BuildNumber.rawValue) != 0) ? false : true)
                animator?.animate(recordDot, toFade: (showOptions.rawValue & ShowOptions.CaptureTime.rawValue) != 0 ? false : true)
                animator?.animate(recordTimingLabel, toFade: (showOptions.rawValue & ShowOptions.CaptureTime.rawValue) != 0 ? false : true)

                recordButton?.setImage(UIImage.animatedImage(with: [UIImage(named: "cam")!, UIImage(named: "camPress")!], duration: TimeInterval((animator?.animationDuration ?? 0) * 2)), for: .selected)
                animator?.startPulseAnimation(recordButton)
                recordButton?.isSelected = true
                micButton?.isSelected = microphoneEnabled

                helperLabel?.text = HELP_TEXT
                helperLabel?.textColor = UIColor.white

                startRecordDate = Date()
                timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { timer in
                    let currentDate = Date()
                    var timeInterval: TimeInterval? = nil
                    if let aDate = self.startRecordDate {
                        timeInterval = currentDate.timeIntervalSince(aDate)
                    }
                    let timerDate = Date(timeIntervalSince1970: timeInterval ?? 0.0)

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "mm:ss:SS"
                    dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: Int(0.0)) as TimeZone

                    let timeString = dateFormatter.string(from: timerDate)
                    self.recordTimingLabel?.text = timeString
                })
            case .previewing:
                let isIpad: Bool = UIDevice.current.userInterfaceIdiom == .pad
                animator?.animate(recordButton, toFade: isIpad && (showOptions.rawValue & ShowOptions.Capture.rawValue) != 0 ? false : true)
                animator?.animate(micButton, toFade: isIpad && (showOptions.rawValue & ShowOptions.Mic.rawValue) != 0 ? false : true)
                animator?.animate(helperLabel, toFade: isIpad && (showOptions.rawValue & ShowOptions.Capture.rawValue) != 0 ? false : true)
                animator?.animate(buildLabel, toFade: isIpad && (debug && (showOptions.rawValue & ShowOptions.BuildNumber.rawValue) != 0) ? false : true)
                animator?.animate(recordDot, toFade: true)
                animator?.animate(recordTimingLabel, toFade: true)

                recordButton?.isSelected = false

                timer?.invalidate()
                animator?.stopPulseAnimation(recordButton)
            case .disabled:
                animator?.animate(recordButton, toFade: true)
                animator?.animate(micButton, toFade: true)
                animator?.animate(helperLabel, toFade: false)
                animator?.animate(buildLabel, toFade: (debug && (showOptions.rawValue & ShowOptions.BuildNumber.rawValue) != 0) ? false : true)
                animator?.animate(recordDot, toFade: true)
                animator?.animate(recordTimingLabel, toFade: true)
                helperLabel?.text = DISABLED_TEXT
                helperLabel?.textColor = UIColor.gray
                timer?.invalidate()
                animator?.stopPulseAnimation(recordButton)
            case .authDisabled:
                animator?.animate(recordButton, toFade: (showOptions.rawValue & ShowOptions.Capture.rawValue) != 0 ? false : true)
                animator?.animate(micButton, toFade: (showOptions.rawValue & ShowOptions.Mic.rawValue) != 0 ? false : true)
                animator?.animate(helperLabel, toFade: false)
                animator?.animate(buildLabel, toFade: (debug && (showOptions.rawValue & ShowOptions.BuildNumber.rawValue) != 0) ? false : true)
                animator?.animate(recordDot, toFade: true)
                animator?.animate(recordTimingLabel, toFade: true)
                helperLabel?.text = GRANT_TEXT
                helperLabel?.textColor = UIColor.red
                timer?.invalidate()
                animator?.stopPulseAnimation(recordButton)
            case .error:
                animator?.animate(recordButton, toFade: (showOptions.rawValue & ShowOptions.Capture.rawValue) != 0 ? false : true)
                animator?.animate(micButton, toFade: (showOptions.rawValue & ShowOptions.Mic.rawValue) != 0 ? false : true)
                animator?.animate(helperLabel, toFade: false)
                animator?.animate(buildLabel, toFade: (debug && (showOptions.rawValue & ShowOptions.BuildNumber.rawValue) != 0) ? false : true)
                animator?.animate(recordDot, toFade: true)
                animator?.animate(recordTimingLabel, toFade: true)
                recordButton?.isSelected = false
                micButton?.isSelected = microphoneEnabled
                helperLabel?.text = ERROR_TEXT
                helperLabel?.textColor = UIColor.red
            
                // move to Is Ready state
                // fix multiple block executing
                // RF me:
                var updateCounter: Int = 0
                updateCounter += 1
                let blockCounter = updateCounter
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(UInt64(SHOW_ERROR_RECORDING_LABEL_DURATION) * NSEC_PER_SEC), execute: {
                    if (blockCounter == updateCounter) && self.recordState == RecordState.error {
                        self.setRecordState(.isReady, withAnimationCompletion: { finish in
                        })
                    }
                })
            default:
                break
        }
    }
    
    func setTrackingState(_ state: String?, withAnimationCompletion completion: @escaping Completion) {
        guard let recordState = recordState else { return }
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        
        if recordState == .previewing {
            if ((UIDevice.current.userInterfaceIdiom == .pad) && (showOptions.rawValue & ShowOptions.ARWarnings.rawValue) != 0) {
                animator?.animate(trackingStateButton, toFade: false) { finish in
                    completion(finish)
                }
            } else {
                animator?.animate(trackingStateButton, toFade: true) { finish in
                    completion(finish)
                }
            }
            
            return
        }
        
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
        guard let recordState = recordState else { return }
        guard let showOptions = showOptions else { return }
        guard let showMode = showMode else { return }
        
        if recordState == .previewing {
            if ((UIDevice.current.userInterfaceIdiom == .pad) && (showOptions.rawValue & ShowOptions.ARWarnings.rawValue) != 0) {
                animator?.animate(trackingStateButton, toFade: false) { finish in
                    completion(finish)
                }
            } else {
                animator?.animate(trackingStateButton, toFade: true) { finish in
                    completion(finish)
                }
            }
            
            return
        }
        
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
        trackingStateButton?.frame = trackFrameIn(view.bounds)
        trackingStateButton?.contentVerticalAlignment = .fill
        trackingStateButton?.contentHorizontalAlignment = .fill
        view.addSubview(trackingStateButton!)
        
        self.recordDot = UIView(frame: dotFrameIn(view.bounds))
        recordDot?.layer.cornerRadius = CGFloat(Double(DOT_SIZE) / 2.0)
        recordDot?.backgroundColor = UIColor.red
        view.addSubview(recordDot!)
        
        self.recordTimingLabel = UILabel(frame: recordLabelFrameIn(view.bounds))
        recordTimingLabel?.font = UIFont.systemFont(ofSize: 12)
        recordTimingLabel?.textAlignment = .left
        recordTimingLabel?.textColor = UIColor.white
        recordTimingLabel?.backgroundColor = UIColor.clear
        recordTimingLabel?.clipsToBounds = true
        view.addSubview(recordTimingLabel!)
        
        self.helperLabel = UILabel(frame: helperLabelFrameIn(view.bounds))
        helperLabel?.font = UIFont.systemFont(ofSize: 12)
        helperLabel?.textAlignment = .center
        helperLabel?.textColor = UIColor.white
        helperLabel?.backgroundColor = UIColor.clear
        helperLabel?.clipsToBounds = true
        view.addSubview(helperLabel!)
        
        self.buildLabel = UILabel(frame: buildFrameIn(view.bounds))
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
}

