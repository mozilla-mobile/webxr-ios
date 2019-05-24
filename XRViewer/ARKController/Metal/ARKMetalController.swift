import ARKit
import Metal
import MetalKit

extension MTKView: RenderDestinationProvider {
}

class ARKMetalController: NSObject, ARKControllerProtocol, MTKViewDelegate {
    
    var previewingSinglePlane: Bool = false
    var focusedPlane: PlaneNode?
    var planes: [UUID : PlaneNode] = [:]
    private var renderer: Renderer!
    private var renderView: MTKView?
    private var hitTestFocusPoint = CGPoint.zero
    
    deinit {
        DDLogDebug("ARKMetalController dealloc")
    }
    
    required init(sesion session: ARSession, size: CGSize) {
        super.init()
        if setupAR(with: session) == false {
            print("Error setting up AR Session with Metal")
        }
    }
    
    func getRenderView() -> UIView! {
        return renderView
    }
    
    func setHitTestFocus(_ point: CGPoint) {
        return
    }
    
    func hitTest(_ point: CGPoint, with type: ARHitTestResult.ResultType) -> [Any]? {
        return nil
    }
    
    func cameraProjectionTransform() -> matrix_float4x4 {
        return matrix_identity_float4x4
    }
    
    func didChangeTrackingState(_ camera: ARCamera?) {
    }
    
    func currentHitTest() -> Any? {
        return nil
    }
    
    func setShowMode(_ mode: ShowMode) {
    }
    
    func setShowOptions(_ options: ShowOptions) {
    }
    
    func clean() {
    }
    
    func update(_ session: ARSession) {
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
