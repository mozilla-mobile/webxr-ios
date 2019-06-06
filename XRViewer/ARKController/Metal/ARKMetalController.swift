import ARKit
import Metal
import MetalKit

extension MTKView: RenderDestinationProvider {
}

class ARKMetalController: NSObject, ARKControllerProtocol, MTKViewDelegate {
    
    private var renderer: Renderer!
    private var renderView: MTKView?
    var planes: [UUID : PlaneNode] = [:]
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
    
    private var planeHitTestResults: [ARHitTestResult] = []
    private var hitTestFocusPoint = CGPoint.zero
    private var currentHitTest: HitTestResult?
    
    var previewingSinglePlane: Bool = false
    var focusedPlane: PlaneNode? {
        didSet {
            if focusedPlane == nil {
                oldValue?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Models.scnassets/plane_grid1.png")
            }
        }
    }
    
    deinit {
        DDLogDebug("ARKMetalController dealloc")
    }
    
    required init(sesion session: ARSession, size: CGSize) {
        super.init()
        if setupAR(with: session) == false {
            print("Error setting up AR Session with Metal")
        }
    }
    
    func update(_ session: ARSession) {
        
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
    
    func hitTest(_ point: CGPoint, with type: ARHitTestResult.ResultType) -> [Any]? {
        return nil
//        if focusedPlane != nil {
//            guard let results = renderView?.hitTest(point, types: type) else { return [] }
//            guard let chosenPlane = focusedPlane else { return [] }
//            if let anchorIdentifier = planes.someKey(forValue: chosenPlane) {
//                let anchor = results.filter { $0.anchor?.identifier == anchorIdentifier }.first
//                if let anchor = anchor {
//                    return [anchor]
//                }
//            }
//            return []
//        } else {
//            return renderView?.hitTest(point, types: type)
//        }
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
    
    func getRenderView() -> UIView! {
        return renderView
    }
    
    func getRenderViewSize() -> CGSize {
        return CGSize.zero
    }
    
    func setRenderViewSize(_ size: CGSize) {
        return
    }
    
    func setHitTestFocus(_ point: CGPoint) {
        return
    }
    
    func didChangeTrackingState(_ camera: ARCamera?) {
    }
    
//    func currentHitTest() -> Any? {
//        return nil
//    }
    
    func setShowMode(_ mode: ShowMode) {
    }
    
    func setShowOptions(_ options: ShowOptions) {
    }
    
    func setupAR(with session: ARSession) -> Bool {
        renderView = MTKView()
        renderView = MTKView(frame: UIScreen.main.bounds, device: MTLCreateSystemDefaultDevice())
        renderView?.backgroundColor = UIColor.clear
        renderView?.delegate = self
        
        guard let renderView = renderView else {
            DDLogError("Error accessing the renderView")
            return false
        }
        guard let device = renderView.device else {
            DDLogError("Metal is not supported on this device")
            return false
        }

        renderer = Renderer(session: session, metalDevice: device, renderDestination: renderView)
        renderer.drawRectResized(size: renderView.bounds.size)
        
        return true
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRectResized(size: size)
    }
    
    func draw(in view: MTKView) {
        renderer.update()
    }
}
