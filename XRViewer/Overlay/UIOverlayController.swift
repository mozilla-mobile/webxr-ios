import UIKit

typealias OnSwipeDown = () -> Void
typealias OnSwipeUp = () -> Void

class UIOverlayController: NSObject {
    @objc var animator: Animator? {
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
    private var micAction: HotAction?
    private var showAction: HotAction?
    private var debugAction: HotAction?
    private var showMode: ShowMode?
    private var showOptions: ShowOptions?

    @objc init(rootView: UIView, micAction: @escaping HotAction, showAction: @escaping HotAction, debugAction: @escaping HotAction) {
        super.init()
        self.rootView = rootView

        self.micAction = micAction
        self.showAction = showAction
        self.debugAction = debugAction

        setupTouchView()
        setupOverlayWindow()
    }

    @objc func clean() {
        hotView()?.removeFromSuperview()
        overlayWindow?.isHidden = true
        self.overlayWindow = nil
    }

    @objc func viewWillTransition(to size: CGSize) {
        var updRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        
        if showMode.rawValue >= ShowMode.multi.rawValue {
            if showOptions.rawValue & ShowOptions.Browser.rawValue != 0 {
                updRect.origin.y = CGFloat(URL_BAR_HEIGHT)
            }
        }

        touchView?.setCameraRect(recordFrameIn(updRect), micRect: micFrameIn(updRect), showRect: showFrameIn(updRect), debugRect: debugFrameIn(updRect))
    }

    func hotView() -> UIView? {
        return touchView
    }

    @objc func setMode(_ mode: ShowMode) {
        showMode = mode

        overlayWindow?.alpha = mode == .nothing ? 0 : 1

        touchView?.showMode = mode

        touchView?.setProcessTouches(false)

        overlayVC?.setShowMode(mode, withAnimationCompletion: { finish in
            self.enableTouches(onFinishAnimation: finish)
        })

        viewWillTransition(to: rootView?.bounds.size ?? CGSize.zero)
    }

    @objc func setOptions(_ options: ShowOptions) {
        showOptions = options

        touchView?.showOptions = options
        overlayVC?.setShowOptions(options, withAnimationCompletion: { finish in
        })
    }

    @objc func setMicEnabled(_ micEnabled: Bool) {
        overlayVC?.setMicrophoneEnabled(micEnabled, withAnimationCompletion: { finish in
        })
    }
    /***
     * Informs the overlay view controller about a tracking state change
     * @param state The AR tracking state string
     * @param hasPlanes A boolean indicating whether there are any planes in the scene
     */

    @objc func setTrackingState(_ state: String?, sceneHasPlanes hasPlanes: Bool) {

        overlayVC?.setTrackingState(state, withAnimationCompletion: { finish in
        }, sceneHasPlanes: hasPlanes)
    }

    @objc func setARKitInterruption(_ interruption: Bool) {
        overlayWindow?.alpha = interruption ? 1 : 0
    }

    deinit {
        DDLogDebug("UIOverlayController dealloc")
    }

// MARK: Private

    func setupTouchView() {
        guard let rootView = rootView else { return }
        guard let micAction = micAction else { return }
        guard let showAction = showAction else { return }
        guard let debugAction = debugAction else { return }
        self.touchView = TouchView(frame: rootView.bounds, micAction: micAction, showAction: showAction, debugAction: debugAction)

        viewWillTransition(to: rootView.bounds.size)

        if let aView = touchView {
            rootView.addSubview(aView)
        }

        touchView?.topAnchor.constraint(equalTo: rootView.topAnchor).isActive = true
        touchView?.bottomAnchor.constraint(equalTo: rootView.bottomAnchor).isActive = true
        touchView?.leftAnchor.constraint(equalTo: rootView.leftAnchor).isActive = true
        touchView?.rightAnchor.constraint(equalTo: rootView.rightAnchor).isActive = true

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
}
