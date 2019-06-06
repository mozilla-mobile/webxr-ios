import ARKit
import SceneKit
import CocoaLumberjack

class ARKSceneKitController: NSObject, ARKControllerProtocol, ARSCNViewDelegate {
    
    private var session: ARSession
    private var renderView: ARSCNView?
    private var renderViewSize: CGSize = CGSize.zero
    private weak var camera: SCNCamera?
    private var anchorsNodes: [AnchorNode] = []

    private var showMode: ShowMode? {
        didSet {
            updateModes()
        }
    }
    private var showOptions: ShowOptions? {
        didSet {
            updateModes()
        }
    }
    var planes: [UUID : PlaneNode] = [:]
    private var planeHitTestResults: [ARHitTestResult] = []
    private var currentHitTest: HitTestResult?
    private var focus: FocusNode?
    private var hitTestFocusPoint = CGPoint.zero
    var previewingSinglePlane = false
    var focusedPlane: PlaneNode? {
        didSet {
            if focusedPlane == nil {
                oldValue?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Models.scnassets/plane_grid1.png")
            }
        }
    }

    deinit {
        DDLogDebug("ARKSceneKitController dealloc")
    }

    required init(sesion session: ARSession, size: CGSize) {
        self.session = session
        super.init()
        
        setupAR(with: session, size: size)
        planes = [UUID : PlaneNode]()
        anchorsNodes = [AnchorNode]()

        setupFocus()
    }

    func update(_ session: ARSession) {
        self.session = session
        renderView?.session = session
    }

    func clean() {
        for (_, plane) in planes {
            plane.removeFromParentNode()
        }
        planes.removeAll()

        for anchor in anchorsNodes {
            anchor.removeFromParentNode()
        }
        anchorsNodes.removeAll()

        focus?.show(false)

        planeHitTestResults = []
    }

    func hitTest(_ point: CGPoint, with type: ARHitTestResult.ResultType) -> [Any]? {
        if focusedPlane != nil {
            guard let results = renderView?.hitTest(point, types: type) else { return [] }
            guard let chosenPlane = focusedPlane else { return [] }
            if let anchorIdentifier = planes.someKey(forValue: chosenPlane) {
                let anchor = results.filter { $0.anchor?.identifier == anchorIdentifier }.first
                if let anchor = anchor {
                    return [anchor]
                }
            }
            return []
        } else {
            return renderView?.hitTest(point, types: type)
        }
    }

    func updateModes() {
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        if showMode == ShowMode.urlDebug || showMode == ShowMode.debug {
            renderView?.showsStatistics = (showOptions.rawValue & ShowOptions.ARStatistics.rawValue) != 0
            renderView?.debugOptions = (showOptions.rawValue & ShowOptions.ARPoints.rawValue) != 0 ? .showFeaturePoints : []
        } else {
            renderView?.showsStatistics = false
            renderView?.debugOptions = []
        }
    }
    
    func didChangeTrackingState(_ camera: ARCamera?) {
        guard let camera = camera else { return }
        guard let showOptions = showOptions else { return }
        switch camera.trackingState {
        case .normal:
            focus?.show(false)
        default:
            focus?.show((showOptions.rawValue & ShowOptions.ARFocus.rawValue) != 0)
        }
    }

// MARK: - Private

    func setupAR(with session: ARSession, size: CGSize) {
        self.session = session

        // Tony (5/29/19): From looking into the "thread blocked waiting for next drawable" issue,
        // I think if we were able to use OpenGL for the ARSCNView that the issue would be resolved.
        // However, it looks like this is a bogus option and ARSCNView defaults to Metal as the
        // preferredRenderingAPI regardless of what you feed into 'options'.
        renderView = ARSCNView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height), options: [SCNView.Option.preferredRenderingAPI.rawValue: NSNumber(value: SCNRenderingAPI.openGLES2.rawValue)])
        renderView?.session = session
        renderView?.scene = SCNScene()
        renderView?.showsStatistics = false
        renderView?.allowsCameraControl = true
        renderView?.automaticallyUpdatesLighting = false
        renderView?.preferredFramesPerSecond = Int(PREFER_FPS)
        renderView?.delegate = self

        camera = renderView?.pointOfView?.camera
        camera?.wantsHDR = true

        renderView?.scene.lightingEnvironment.contents = UIColor.white
        renderView?.scene.lightingEnvironment.intensity = 50
        
        renderViewSize = renderView?.frame.size ?? CGSize.zero
    }

// MARK: Focus

    func setupFocus() {
        if focus != nil {
            focus?.removeFromParentNode()
        }

        focus = FocusNode()
        if let aFocus = focus {
            renderView?.scene.rootNode.addChildNode(aFocus)
        }
    }

    func hitTest() {
//        guard let showOptions = showOptions else { return }
//        // hit testing only for Focus node!
//        if (showOptions.rawValue & ShowOptions.ARFocus.rawValue) != 0 {
//            if let aFocus = renderView?.hitTest(point: hitTestFocusPoint, withResult: { result in
//                self.currentHitTest = result
//
//                self.updateFocus()
//            }) {
//                if let focus = aFocus as? [ARHitTestResult] {
//                    self.planeHitTestResults = focus
//                }
//            }
//        } else {
//            focus?.show(false)
//        }
        
        guard previewingSinglePlane else { return }
        guard let firstHitTestResult = renderView?.hitTest(hitTestFocusPoint, types: .existingPlaneUsingGeometry).first else { return }
        if let plane = firstHitTestResult.anchor as? ARPlaneAnchor {
            let node = renderView?.node(for: plane)
            let child = node?.childNodes.first as? PlaneNode
            child?.opacity = 1
            focusedPlane = child
        }
    }

    func updateFocus() {
        guard let showOptions = showOptions else { return }
        if currentHitTest != nil {
            focus?.show((showOptions.rawValue & ShowOptions.ARFocus.rawValue) != 0)
        } else {
            focus?.show(false)
        }
        guard let currentHitTest = currentHitTest else { return }
        guard let position = currentHitTest.position else { return }
        focus?.update(forPosition: position, planeAnchor: currentHitTest.anchor, camera: session.currentFrame?.camera)
    }

    func updateCameraFocus() {
        var focusDistance: CGFloat = 0

        if focus?.opacity ?? 0 > 0 {
            let focusPosition: SCNVector3? = focus?.position
            let cameraPosition: SCNVector3? = renderView?.pointOfView?.position

            let vector: SCNVector3 = SCNVector3Make((focusPosition?.x ?? 0.0) - (cameraPosition?.x ?? 0.0), (focusPosition?.y ?? 0.0) - (cameraPosition?.y ?? 0.0), (focusPosition?.z ?? 0.0) - (cameraPosition?.z ?? 0.0))

            focusDistance = CGFloat(sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z))
        }

        if focusDistance > 0 {
            //DDLogDebug(@"Camera focus - %.1f", focusDistance);
            camera?.focusDistance = focusDistance
        }
    }

    func updatePlanes() {
        guard let showMode = showMode else { return }
        guard let showOptions = showOptions else { return }
        for (_, plane) in planes {
            plane.geometry?.firstMaterial?.diffuse.contents = focusedPlane == plane ? UIImage(named: "Models.scnassets/plane_grid2.png") : UIImage(named: "Models.scnassets/plane_grid1.png")
            plane.show(((showMode == ShowMode.urlDebug) && (showOptions.rawValue & ShowOptions.ARPlanes.rawValue) != 0) || ((showMode == ShowMode.debug) && (showOptions.rawValue & ShowOptions.ARPlanes.rawValue) != 0) || previewingSinglePlane)
        }
    }

    func updateAnchors() {
        guard let showOptions = showOptions else { return }
        for anchor in anchorsNodes {
            anchor.show((showOptions.rawValue & ShowOptions.ARObject.rawValue) != 0)
        }
    }

// MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let lightEstimate: CGFloat? = session.currentFrame?.lightEstimate?.ambientIntensity
        renderView?.scene.lightingEnvironment.intensity = (lightEstimate ?? 0.0) / 40

        hitTest()
//        updateCameraFocus()
        updatePlanes()
        updateAnchors()
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            var plane: PlaneNode? = nil
            if let anAnchor = anchor as? ARPlaneAnchor {
                plane = PlaneNode(anchor: anAnchor)
            }
            planes[anchor.identifier] = plane
            if let aPlane = plane {
                node.addChildNode(aPlane)
            }
        } else {
            let anchorNode = AnchorNode(anchor: anchor)
            node.addChildNode(anchorNode)
            anchorsNodes.append(anchorNode)
            
            // move anchor to be over the plane
            var transform: SCNMatrix4 = node.worldTransform
            transform = SCNMatrix4Translate(transform, 0, Float((anchorNode.size()) / 2), 0)
            node.transform = transform
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            let plane = planes[anchor.identifier]
            plane?.update(anchor as? ARPlaneAnchor)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if node is AnchorNode {
            anchorsNodes.removeAll(where: { element in element == node })
        } else {
            planes.removeValue(forKey: anchor.identifier)
        }
    }
    
    // MARK: - ARKControllerProtocol
    
    func getRenderView() -> UIView! {
        return renderView
    }
    
    func getRenderViewSize() -> CGSize {
        return renderViewSize
    }
    
    func setRenderViewSize(_ size: CGSize) {
        renderViewSize = size
    }
    
    func setHitTestFocus(_ point: CGPoint) {
        hitTestFocusPoint = point
    }
    
    func setShowMode(_ mode: ShowMode) {
        showMode = mode
    }
    
    func setShowOptions(_ options: ShowOptions) {
        showOptions = options
    }
}
