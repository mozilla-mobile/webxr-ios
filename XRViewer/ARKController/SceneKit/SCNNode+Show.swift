import SceneKit

extension SCNNode {
    func show(_ show: Bool) {
        if show {
            unhide()
        } else {
            hide()
        }
    }

    func hide() {
        if opacity == 1.0 {
            runAction(SCNAction.fadeOut(duration: 0.5))
        }
    }

    func unhide() {
        if opacity == 0.0 {
            runAction(SCNAction.fadeIn(duration: 0.5))
        }
    }
}
