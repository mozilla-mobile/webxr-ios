import ARKit
import Metal
import MetalKit

extension MTKView: RenderDestinationProvider {
}

class ARKMetalController: NSObject, ARKControllerProtocol, MTKViewDelegate {
    
    private var session: ARSession
    var renderer: Renderer!
    private var renderView: MTKView?
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
    private var hitTestFocusPoint = CGPoint.zero
    var previewingSinglePlane: Bool = false
    var focusedPlane: PlaneNode? {
        didSet {
            if focusedPlane == nil {
                oldValue?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Models.scnassets/plane_grid1.png")
            }
        }
    }
    var readyToRenderFrame: Bool = true
    var initializingRender: Bool = true
    
    deinit {
        for view in renderView?.subviews ?? [] {
            view.removeFromSuperview()
        }
        renderView?.delegate = nil
        if let _ = renderView {
            renderView = nil
        }
        appDelegate().logger.debug("ARKMetalController dealloc")
    }
    
    required init(sesion session: ARSession, size: CGSize) {
        self.session = session
        super.init()
        if setupAR(with: session) == false {
            print("Error setting up AR Session with Metal")
        }
    }
    
    func update(_ session: ARSession) {
        self.session = session
        if setupAR(with: session) == false {
            print("Error updating AR Session with Metal")
        }
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
        
        planeHitTestResults = []
    }
    
    func hitTest(_ point: CGPoint, with type: ARHitTestResult.ResultType) -> [ARHitTestResult] {
        if focusedPlane != nil {
            guard let results = session.currentFrame?.hitTest(point, types: type) else { return [] }
            guard let chosenPlane = focusedPlane else { return [] }
            if let anchorIdentifier = planes.someKey(forValue: chosenPlane) {
                let anchor = results.filter { $0.anchor?.identifier == anchorIdentifier }.first
                if let anchor = anchor {
                    return [anchor]
                }
            }
            return []
        } else {
            return session.currentFrame?.hitTest(point, types: type) ?? []
        }
    }

    func updateModes() {
        guard let showMode = showMode else { return }
//        guard let showOptions = showOptions else { return }
        if showMode == ShowMode.urlDebug || showMode == ShowMode.debug {
//            renderView?.showsStatistics = (showOptions.rawValue & ShowOptions.ARStatistics.rawValue) != 0
//            renderView?.debugOptions = (showOptions.rawValue & ShowOptions.ARPoints.rawValue) != 0 ? .showFeaturePoints : []
        } else {
//            renderView?.showsStatistics = false
//            renderView?.debugOptions = []
        }
    }
    
    func didChangeTrackingState(_ camera: ARCamera?) {
    }
    
//    func currentHitTest() -> Any? {
//        return nil
//    }
    
    func setupAR(with session: ARSession) -> Bool {
        renderView = MTKView()
        renderView = MTKView(frame: UIScreen.main.bounds, device: MTLCreateSystemDefaultDevice())
        renderView?.backgroundColor = UIColor.clear
        renderView?.delegate = self
        
        guard let renderView = renderView else {
            appDelegate().logger.error("Error accessing the renderView")
            return false
        }
        guard let device = renderView.device else {
            appDelegate().logger.error("Metal is not supported on this device")
            return false
        }

        renderer = Renderer(session: session, metalDevice: device, renderDestination: renderView)
        renderer.drawRectResized(size: renderView.bounds.size)
        
        return true
    }
    
    
    
    // MARK: - ARKControllerProtocol
    
    func getRenderView() -> UIView! {
        return renderView
    }
    
    func setHitTestFocus(_ point: CGPoint) {
        return
    }
    
    func setShowMode(_ mode: ShowMode) {
        showMode = mode
    }
    
    func setShowOptions(_ options: ShowOptions) {
        showOptions = options
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRectResized(size: size)
    }
    
    func draw(in view: MTKView) {
        guard readyToRenderFrame || initializingRender else {
            return
        }
        renderer.update()
    }
}
