import SceneKit
import ARKit

class FocusNode: SCNNode {

    private var lastPositionOnPlane: SCNVector3?
    private var lastPosition: SCNVector3?
    private var recentFocusSquarePositions: [SCNVector3] = []
    private var anchorOfVisitedPlanes: Set<ARPlaneAnchor> = []
    private var isAnimating = false
    private var isOpen = false
    private var onNode: SCNNode?
    private var offNode: SCNNode?
    private let FOCUS_SQUARE_SIZE = 0.17

    override init() {
        super.init()

        opacity = 0

        self.recentFocusSquarePositions = [SCNVector3]()
        self.anchorOfVisitedPlanes = Set<ARPlaneAnchor>()

        let nodeOn = SCNNode()
        let planeOn = SCNPlane(width: CGFloat(FOCUS_SQUARE_SIZE), height: CGFloat(FOCUS_SQUARE_SIZE))

        let materialOn = SCNMaterial()
        let imgOn = UIImage(named: "Models.scnassets/yes_white.png")
        materialOn.diffuse.contents = imgOn
        //[[materialOn diffuse] setIntensity:0.5];
        planeOn.materials = [materialOn]

        nodeOn.geometry = planeOn
        nodeOn.transform = SCNMatrix4MakeRotation(-.pi / 2, 1, 0, 0)
        addChildNode(nodeOn)
        self.onNode = nodeOn


        let nodeOff = SCNNode()
        let planeOff = SCNPlane(width: CGFloat(FOCUS_SQUARE_SIZE), height: CGFloat(FOCUS_SQUARE_SIZE))

        let materialOff = SCNMaterial()
        let imgOff = UIImage(named: "Models.scnassets/no_white.png")
        materialOff.diffuse.contents = imgOff
        //[[materialOff diffuse] setIntensity:0.5];
        planeOff.materials = [materialOff]

        nodeOff.geometry = planeOff
        nodeOff.transform = SCNMatrix4MakeRotation(-.pi / 2.0, 1, 0, 0)
        addChildNode(nodeOff)
        self.offNode = nodeOff
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func update(forPosition position: SCNVector3, planeAnchor anchor: ARPlaneAnchor?, camera: ARCamera?) {
        self.lastPosition = position
        
        if anchor != nil {
            guard let anchor = anchor else { return }
            self.lastPositionOnPlane = position
            anchorOfVisitedPlanes.insert(anchor)
            
            onNode?.opacity = 1
            offNode?.opacity = 0
        } else {
            onNode?.opacity = 0
            offNode?.opacity = 1
        }
        
        runAction(SCNAction.customAction(duration: 0.5, action: { node, elapsedTime in
            self.updateTransform(forPosition: position, camera: camera)
        }))
    }
    
    func averageFromRecentPositions() -> SCNVector3 {
        var x: Float = 0
        var y: Float = 0
        var z: Float = 0

        for position in recentFocusSquarePositions {
            x += position.x
            y += position.y
            z += position.z
        }

        return SCNVector3Make(x / Float(recentFocusSquarePositions.count), y / Float(recentFocusSquarePositions.count), z / Float(recentFocusSquarePositions.count))
    }

    func updateTransform(forPosition position: SCNVector3, camera: ARCamera?) {
        // add to list of recent positions
        recentFocusSquarePositions.append(position)

        // remove anything older than the last 8
        let toRemove: Int = recentFocusSquarePositions.count - 8

        if toRemove > 0 {
            if let subRange = Range(NSRange(location: 0, length: toRemove)) { recentFocusSquarePositions.removeSubrange(subRange) }
        }

        // move to average of recent positions to avoid jitter
        self.position = averageFromRecentPositions()


        let scale: CGFloat = scaleBased(onDistance: camera)
        setUniformScale(scale)

        // Correct y rotation of camera square
        guard let camera = camera else { return }
        let tilt = CGFloat(abs(camera.eulerAngles.x))
        let threshold1: CGFloat = .pi / 2 * 0.65
        let threshold2: CGFloat = .pi / 2 * 0.75
        let yaw = atan2(camera.transform.columns.0.x, camera.transform.columns.1.x)
        var angle: CGFloat = 0

        if tilt > 0 && tilt < threshold1 {
            angle = CGFloat(camera.eulerAngles.y)
        } else if tilt >= threshold1 && tilt < threshold2 {
            let relativeInRange = CGFloat(abs((tilt - threshold1) / (threshold2 - threshold1)))
            let normalizedY = normalizeAngle(CGFloat(camera.eulerAngles.y), forMinimalRotationTo: CGFloat(yaw))
            angle = normalizedY * (1 - relativeInRange) + CGFloat(yaw) * relativeInRange
        } else {
            angle = CGFloat(yaw)
        }

        rotation = SCNVector4Make(0, 1, 0, Float(angle))
    }

    func normalizeAngle(_ angle: CGFloat, forMinimalRotationTo rotation: CGFloat) -> CGFloat {
        // Normalize angle in steps of 90 degrees such that the rotation to the other angle is minimal
        var normalized: CGFloat = angle

        while abs(Float(normalized - rotation)) > .pi / 4 {
            if angle > rotation {
                normalized -= .pi / 2
            } else {
                normalized += .pi / 2
            }
        }

        return normalized
    }

    func scaleBased(onDistance camera: ARCamera?) -> CGFloat {
        guard let camera = camera else { return 1 }
        let diff: SCNVector3 = SCNVector3Make(worldPosition.x - camera.transform.columns.3.x , worldPosition.y - camera.transform.columns.3.y, worldPosition.z - camera.transform.columns.3.z)

        let distanceFromCamera = CGFloat(sqrtf(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z))

        // This function reduces size changes of the focus square based on the distance by scaling it up if it far away,
        // and down if it is very close.
        // The values are adjusted such that scale will be 1 in 0.7 m distance (estimated distance when looking at a table),
        // and 1.2 in 1.5 m distance (estimated distance when looking at the floor).
        let newScale: CGFloat = distanceFromCamera < 0.7 ? (distanceFromCamera / 0.7) : (0.25 * distanceFromCamera + 0.825)

        return newScale
    }
}

extension SCNNode {
    func setUniformScale(_ scale: CGFloat) {
        self.scale = SCNVector3Make(Float(scale), Float(scale), Float(scale))
    }
}
