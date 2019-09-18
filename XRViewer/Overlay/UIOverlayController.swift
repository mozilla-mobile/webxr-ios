import UIKit
import XCGLogger

typealias OnSwipeDown = () -> Void
typealias OnSwipeUp = () -> Void

class UIOverlayController: NSObject {
    var animator: Animator? {
        didSet(animator) {
            overlayVC?.animator = animator
        }
    }
    var onSwipeDown: OnSwipeDown?
    var onSwipeUp: OnSwipeUp?
    private weak var rootView: UIView?
    private var touchView: TouchView?
    private var overlayWindow: UIWindow?
    private var overlayVC: OverlayViewController?
    private var debugAction: HotAction?
    private var showMode: ShowMode?
    private var showOptions: ShowOptions?

    init(rootView: UIView, debugAction: @escaping HotAction) {
        super.init()
        self.rootView = rootView
        self.debugAction = debugAction
        setupTouchView()
        setupOverlayWindow()
    }

    func clean() {
        hotView()?.removeFromSuperview()
        overlayWindow?.isHidden = true
        self.overlayWindow = nil
    }

    func viewWillTransition(to size: CGSize) {
        var updRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        
        if showMode.rawValue >= ShowMode.url.rawValue {
            if showOptions.rawValue & ShowOptions.browser.rawValue != 0 {
                updRect.origin.y = CGFloat(Constant.urlBarHeight())
            }
        }

        touchView?.setCameraRect(recordFrameIn(viewRect: updRect), micRect: micFrameIn(viewRect: updRect), showRect: showFrameIn(viewRect: updRect), debugRect: debugFrameIn(viewRect: updRect))
    }

    func hotView() -> UIView? {
        return touchView
    }

    func setMode(_ mode: ShowMode) {
        showMode = mode
        overlayWindow?.alpha = mode == .nothing ? 0 : 1
        touchView?.showMode = mode
        touchView?.setProcessTouches(false)
        overlayVC?.setShowMode(mode, withAnimationCompletion: { finish in
            self.enableTouches(onFinishAnimation: finish)
        })
        viewWillTransition(to: rootView?.bounds.size ?? CGSize.zero)
    }

    func setOptions(_ options: ShowOptions) {
        showOptions = options
        touchView?.showOptions = options
        overlayVC?.setShowOptions(options, withAnimationCompletion: { finish in
        })
    }

    func setARKitInterruption(_ interruption: Bool) {
        overlayWindow?.alpha = interruption ? 1 : 0
    }

    deinit {
        appDelegate().logger.debug("UIOverlayController dealloc")
    }

// MARK: Private

    func setupTouchView() {
        guard let rootView = rootView else { return }
        guard let debugAction = debugAction else { return }
        self.touchView = TouchView(frame: rootView.bounds, debugAction: debugAction)

        viewWillTransition(to: rootView.bounds.size)

        if let aView = touchView {
            rootView.addSubview(aView)
        }
        touchView?.backgroundColor = UIColor.clear
    }

    func setupOverlayWindow() {
        let mainWindow: UIWindow? = (UIApplication.shared.delegate?.window)!
        self.overlayWindow = UIWindow(frame: mainWindow?.bounds ?? CGRect.zero)

        self.overlayVC = OverlayViewController()
        overlayVC?.view.frame = overlayWindow?.bounds ?? CGRect.zero
        overlayWindow?.rootViewController = overlayVC
        overlayWindow?.backgroundColor = UIColor.clear
        overlayWindow?.isHidden = false
        overlayWindow?.alpha = 0
        overlayWindow?.isUserInteractionEnabled = false
        overlayVC?.view.isUserInteractionEnabled = false

        DispatchQueue.main.async(execute: {
            mainWindow?.makeKey()
        })
    }

    func enableTouches(onFinishAnimation finish: Bool) {
        if finish {
            touchView?.setProcessTouches(true)
        } else {
            guard let animationDuration = animator?.animationDuration else { return }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(UInt64(animationDuration) * NSEC_PER_SEC), execute: {
                self.touchView?.setProcessTouches(true)
            })
        }
    }
    
    // MARK: - UI Placement Helpers
    
    func recordFrameIn(viewRect: CGRect) -> CGRect {
        return CGRect(x: viewRect.size.width - Constant.recordSize() - Constant.recordOffsetX(), y: viewRect.origin.y + (viewRect.size.height - viewRect.origin.y) / 2 - Constant.recordSize() / 2, width: Constant.recordSize(), height: Constant.recordSize())
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
}
