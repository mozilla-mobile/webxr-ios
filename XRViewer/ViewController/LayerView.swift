import UIKit

/*
 A UIView that passes through the touch events to its subviews when
 processTouchInSubview is set to YES
*/

class LayerView: UIView {
    /*
     If set to YES, the touch events of this UIView are passed to the subviews
    */
    @objc var processTouchInSubview = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if processTouchInSubview {
            return subviews.first?.hitTest(point, with: event)
        }

        return super.hitTest(point, with: event)
    }
}
