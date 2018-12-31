import pop
import UIKit
import CocoaLumberjack

typealias Completion = (Bool) -> Void

let DEFAULT_ANIMATION_DURATION = 0.5
let ANIMATION_PULSE_KEY = "pulse"
let ANIMATION_FRAME_KEY = "frame"
let ANIMATION_COLOR_KEY = "color"

class AnimationDelegate: NSObject, CAAnimationDelegate {
    var completion: Completion?
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        //if completion
        
        completion?(flag)
    }
}

class Animator: NSObject, CAAnimationDelegate {
    
    var animationDuration: Double = 0.0
    private var animationCompletions: [AnimationDelegate] = []
    
    override init() {
        super.init()
        
        self.animationCompletions = []
        animationDuration = DEFAULT_ANIMATION_DURATION
    }
    
    deinit {
        DDLogDebug("Animator dealloc")
    }
    
    @objc func clean() {
        animationCompletions.removeAll()
        UIApplication.shared.keyWindow?.pop_removeAllAnimations()
        UIApplication.shared.keyWindow?.layer.pop_removeAllAnimations()
        UIApplication.shared.keyWindow?.layer.removeAllAnimations()
    }
    
    func startPulseAnimation(_ view: UIView?) {
        let anim = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
        anim?.toValue = CGPoint(x: 1.1, y: 1.1)
        anim?.fromValue = CGPoint(x: 0.9, y: 0.9)
        anim?.repeatForever = true
        anim?.autoreverses = true

        view?.pop_add(anim, forKey: ANIMATION_PULSE_KEY)
    }

    func stopPulseAnimation(_ view: UIView?) {
        view?.pop_removeAnimation(forKey: ANIMATION_PULSE_KEY)
    }

    func animate(_ view: UIView?, toFrame frame: CGRect) {
        animate(view, toFrame: frame) { (bool) in
        }
    }

    func animate(_ view: UIView?, toFrame frame: CGRect, completion: @escaping Completion) {
        guard var viewFrame = view?.frame else { return }
        if frame.equalTo(viewFrame) {
            //if completion

            DispatchQueue.main.async(execute: {
                completion(false)
            })
            return
        }

        let anim = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        anim?.toValue = frame
        anim?.fromValue = viewFrame
        anim?.completionBlock = { anim, finished in
            viewFrame = frame
            //if completion

            completion(finished)
        }

        view?.pop_add(anim, forKey: ANIMATION_FRAME_KEY)
    }

    @objc func animate(_ view: UIView?, toFade fade: Bool) {
        animate(view, toFade: fade) { (bool) in
        }
    }

    func animate(_ view: UIView?, toFade fade: Bool, completion: @escaping Completion) {
        let newOpacity: CGFloat = fade ? 0 : 1

        if CGFloat(view?.layer.opacity ?? 0.0) == newOpacity {
            //if completion

            DispatchQueue.main.async(execute: {
                completion(false)
            })
            return
        }

        view?.layer.opacity = Float(newOpacity)

        var key: String? = nil
        if let aView = view {
            key = "FADE-\(aView)"
        }
        view?.layer.removeAnimation(forKey: key ?? "")

        let transition = CATransition()
        transition.duration = animationDuration
        transition.type = .fade

        let ad = AnimationDelegate()
        weak var blockAd: AnimationDelegate? = ad
        weak var blockSelf: Animator? = self

        ad.completion = { f in
            //if completion

            completion(f)
            blockSelf?.animationCompletions.removeAll(where: { $0 == blockAd })
        }

        transition.delegate = ad
        animationCompletions.append(ad)

        view?.layer.add(transition, forKey: key)
    }

    func animate(_ view: UIView?, to color: UIColor?) {
        if view?.backgroundColor == color {
            return
        }

        let anim = POPSpringAnimation(propertyNamed: kPOPViewBackgroundColor)
        anim?.toValue = color
        anim?.fromValue = view?.backgroundColor
        anim?.completionBlock = { anim, finished in
            view?.backgroundColor = color
        }

        view?.pop_add(anim, forKey: ANIMATION_COLOR_KEY)
    }
}
