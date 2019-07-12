import UIKit
import XCGLogger

class OverlayViewController: UIViewController {
    
    private var showMode: ShowMode?
    private var showOptions: ShowOptions?
    private var buildLabel: UILabel?
    private var timer: Timer?
    var animator: Animator?
    
    let BUILD_LABEL_WIDTH: CGFloat = 80
    let BUILD_LABEL_HEIGHT: CGFloat = 12
    let BUILD_LABEL_LEADING_SPACE: CGFloat = 15
    let BUILD_LABEL_BOTTOM_SPACE: CGFloat = 34
    
    deinit {
        appDelegate().logger.debug("OverlayViewController dealloc")
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
        
        if showMode.rawValue >= ShowMode.url.rawValue {
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
        case .nothing, .debug:
            animator?.animate(buildLabel, toFade: true)
            timer?.invalidate()
            completion(true)
        case .url, .urlDebug:
            completion(true)
        }
    }

    func setup() {
        
        self.buildLabel = UILabel(frame: buildFrameIn(viewRect: view.bounds))
        buildLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        buildLabel?.textAlignment = .left
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
    
    private func buildFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: BUILD_LABEL_LEADING_SPACE, y: viewRect.size.height - BUILD_LABEL_HEIGHT - BUILD_LABEL_BOTTOM_SPACE, width: BUILD_LABEL_WIDTH, height: BUILD_LABEL_HEIGHT)
    }
}
