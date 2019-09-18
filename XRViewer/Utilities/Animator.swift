import UIKit
import XCGLogger

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
        appDelegate().logger.debug("Animator dealloc")
    }
    
    func clean() {
        animationCompletions.removeAll()
        UIApplication.shared.keyWindow?.layer.removeAllAnimations()
    }

    func animate(_ view: UIView?, toFade fade: Bool) {
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
}
