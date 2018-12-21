import UIKit

class OverlayViewController: UIViewController {
    
    private var showMode: ShowMode?
    private var showOptions: ShowOptions?
    private var buildLabel: UILabel?
    private var timer: Timer?
    var animator: Animator?
    
    let RECORD_LABEL_WIDTH: CGFloat = 80
    let RECORD_LABEL_HEIGHT: CGFloat = 12
    
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

    func viewWillTransition(to size: CGSize) {
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        var updRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        if showMode.rawValue >= ShowMode.multi.rawValue {
            if showOptions.rawValue & ShowOptions.Browser.rawValue != 0 {
                updRect.origin.y = CGFloat(Constant.urlBarHeight())
            }
        }
        
        buildLabel?.frame = buildFrameIn(viewRect: updRect)
    }
    // common visibility
    
    func update(with completion: Completion) {
        viewWillTransition(to: view.bounds.size)
        guard let showMode = showMode else { return }
        
        switch showMode {
        case .nothing:
            animator?.animate(buildLabel, toFade: true)
            timer?.invalidate()
            completion(true)
        case .single:
            animator?.animate(buildLabel, toFade: true)
            timer?.invalidate()
            completion(true)
        case .debug:
            animator?.animate(buildLabel, toFade: true)
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

    func setup() {
        
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
    
    func debugFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: Constant.recordOffsetX(), y: viewRect.size.height - Constant.recordOffsetY() - Constant.micSizeH(), width: Constant.micSizeW(), height: Constant.micSizeH())
    }
    
    func showFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width - Constant.recordOffsetX() - Constant.micSizeW(), y: viewRect.size.height - Constant.recordOffsetY() - Constant.micSizeH(), width: Constant.micSizeW(), height: Constant.micSizeH())
    }
    
    private func buildFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width / 2 - (RECORD_LABEL_WIDTH / 2), y: viewRect.size.height - RECORD_LABEL_HEIGHT - 4, width: RECORD_LABEL_WIDTH, height: RECORD_LABEL_HEIGHT)
    }
}
