import ARKit
import CoreVideo
import Metal
import MetalKit
import ModelIO
import simd

#warning("DEFAULT APPLE METAL RENDER")

/*
 Protocol abstracting the platform specific view in order to keep the Renderer
 class independent from platform.
 */
typealias CompletionUpdate = () -> Void
// Include header shared between C code here, which executes Metal API commands, and .metal files


// The max number of command buffers in flight
private let kMaxBuffersInFlight: Int = 3
// The max number anchors our uniform buffer will hold
private let kMaxAnchorInstanceCount: Int = 64
// The 256 byte aligned size of our uniform structures
private let kAlignedSharedUniformsSize: size_t = (MemoryLayout<SharedUniforms>.size & ~0xff) + 0x100
private let kAlignedInstanceUniformsSize: size_t = ((MemoryLayout<InstanceUniforms>.size * kMaxAnchorInstanceCount) & ~0xff) + 0x100
// Vertex data for an image plane
private let kImagePlaneVertexData = [-1.0, -1.0, 0.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]

protocol RenderDestinationProvider: class {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: MTLDrawable? { get }
    var colorPixelFormat: MTLPixelFormat? { get set }
    var depthStencilPixelFormat: MTLPixelFormat? { get set }
    var sampleCount: Int { get set }
}

/*
 The main class performing the rendering of a session.
 */
class Renderer: NSObject {
    // The session the renderer will render
    private var session: ARSession?
    // The object controlling the ultimate render destination
    private weak var renderDestination: RenderDestinationProvider?
    private var inFlightSemaphore: DispatchSemaphore?
    // Metal objects
    private weak var device: MTLDevice?
    private weak var commandQueue: MTLCommandQueue?
    private weak var sharedUniformBuffer: MTLBuffer?
    private weak var anchorUniformBuffer: MTLBuffer?
    private weak var imagePlaneVertexBuffer: MTLBuffer?
    private weak var capturedImagePipelineState: MTLRenderPipelineState?
    private weak var capturedImageDepthState: MTLDepthStencilState?
    private weak var anchorPipelineState: MTLRenderPipelineState?
    private weak var anchorDepthState: MTLDepthStencilState?
    private weak var capturedImageTextureY: MTLTexture?
    private weak var capturedImageTextureCbCr: MTLTexture?
    // Captured image texture cache
    private var capturedImageTextureCache: CVOpenGLESTextureCache?
    // Metal vertex descriptor specifying how vertices will by laid out for input into our
    //   anchor geometry render pipeline and how we'll layout our Model IO verticies
    private var geometryVertexDescriptor: MTLVertexDescriptor?
    // MetalKit mesh containing vertex data and index buffer for our anchor geometry
    private var cubeMesh: MTKMesh?
    // Used to determine _uniformBufferStride each frame.
    //   This is the current frame number modulo kMaxBuffersInFlight
    private var uniformBufferIndex: UInt8 = 0
    // Offset within _sharedUniformBuffer to set for the current frame
    private var sharedUniformBufferOffset: UInt32 = 0
    // Offset within _anchorUniformBuffer to set for the current frame
    private var anchorUniformBufferOffset: UInt32 = 0
    // Addresses to write shared uniforms to each frame
    private var sharedUniformBufferAddress: Void?
    // Addresses to write anchor uniforms to each frame
    private var anchorUniformBufferAddress: Void?
    // The number of anchor instances to render
    private var anchorInstanceCount: Int = 0
    // The current viewport size
    private var viewportSize = CGSize.zero
    // Flag for viewport size changes
    private var viewportSizeDidChange = false
    private var orientation: UIInterfaceOrientation?
    
    var completionUpdate: CompletionUpdate?
    
    init(session: ARSession, metalDevice device: MTLDevice?, renderDestinationProvider: RenderDestinationProvider?) {
        super.init()
        self.session = session
        self.device = device
        renderDestination = renderDestinationProvider
        inFlightSemaphore = DispatchSemaphore(value: kMaxBuffersInFlight)
        _loadMetal()
        _loadAssets()
    }
    
    func drawRectResized(_ size: CGSize, orientation: UIInterfaceOrientation) {
        viewportSize = size
        viewportSizeDidChange = true
        self.orientation = orientation
    }
    
    func update() {
        
        // Wait to ensure only kMaxBuffersInFlight are getting proccessed by any stage in the Metal
        //   pipeline (App, Metal, Drivers, GPU, etc)
        
        // Commented when converted since unused and throwing errors/warnings
//        guard let inFlight = inFlightSemaphore else { return }
//        dispatch_semaphore_wait(inFlight, DispatchTime.distantFuture.uptimeNanoseconds)
        
        // Create a new command buffer for each renderpass to the current drawable
        let commandBuffer: MTLCommandBuffer? = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "MyCommand"
        
        // Add completion hander which signal _inFlightSemaphore when Metal and the GPU has fully
        //   finished proccssing the commands we're encoding this frame.  This indicates when the
        //   dynamic buffers, that we're writing to this frame, will no longer be needed by Metal
        //   and the GPU.
        let block_sema: DispatchSemaphore? = inFlightSemaphore
        commandBuffer?.addCompletedHandler({ buffer in
            
            block_sema?.signal()
            
            if self.completionUpdate != nil {
                self.completionUpdate?()
            }
        })
        
        
        _updateBufferStates()
        _updateGameState()
        
        // Obtain a renderPassDescriptor generated from the view's drawable textures
        let renderPassDescriptor: MTLRenderPassDescriptor? = renderDestination?.currentRenderPassDescriptor
        
        // If we've gotten a renderPassDescriptor we can render to the drawable, otherwise we'll skip
        //   any rendering this frame because we have no drawable to draw to
        if renderPassDescriptor != nil {
            
            // Create a render command encoder so we can render into something
            var renderEncoder: MTLRenderCommandEncoder? = nil
            if let renderPassDescriptor = renderPassDescriptor {
                renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            }
            renderEncoder?.label = "MyRenderEncoder"
            
            _drawCapturedImage(with: renderEncoder)
            _drawAnchorGeometry(with: renderEncoder)
            
            // We're done encoding commands
            renderEncoder?.endEncoding()
        }
        
        // Schedule a present once the framebuffer is complete using the current drawable
        if let currentDrawable = renderDestination?.currentDrawable {
            commandBuffer?.present(currentDrawable)
        }
        
        // Finalize rendering here & push the command buffer to the GPU
        commandBuffer?.commit()
    }
    
    // MARK: - Private
    func _loadMetal() {
        // Create and load our basic Metal state objects
        
        // Set the default formats needed to render
        renderDestination?.depthStencilPixelFormat = .depth32Float_stencil8
        renderDestination?.colorPixelFormat = .bgra8Unorm
        renderDestination?.sampleCount = 1
        
        // Calculate our uniform buffer sizes. We allocate kMaxBuffersInFlight instances for uniform
        //   storage in a single buffer. This allows us to update uniforms in a ring (i.e. triple
        //   buffer the uniforms) so that the GPU reads from one slot in the ring wil the CPU writes
        //   to another. Anchor uniforms should be specified with a max instance count for instancing.
        //   Also uniform storage must be aligned (to 256 bytes) to meet the requirements to be an
        //   argument in the constant address space of our shading functions.
        let sharedUniformBufferSize = Int(kAlignedSharedUniformsSize * kMaxBuffersInFlight)
        let anchorUniformBufferSize = Int(kAlignedInstanceUniformsSize * kMaxBuffersInFlight)
        
        // Create and allocate our uniform buffer objects. Indicate shared storage so that both the
        //   CPU can access the buffer
        sharedUniformBuffer = device?.makeBuffer(length: sharedUniformBufferSize, options: .storageModeShared)
        
        sharedUniformBuffer?.label = "SharedUniformBuffer"
        
        anchorUniformBuffer = device?.makeBuffer(length: anchorUniformBufferSize, options: .storageModeShared)
        
        anchorUniformBuffer?.label = "AnchorUniformBuffer"
        
        // Create a vertex buffer with our image plane vertex data.
        // Commented when converted since unused and throwing errors
//        imagePlaneVertexBuffer = device?.makeBuffer(bytes: &kImagePlaneVertexData, length: MemoryLayout<kImagePlaneVertexData>.size, options: [])
        
        imagePlaneVertexBuffer?.label = "ImagePlaneVertexBuffer"
        
        // Load all the shader files with a metal file extension in the project
        let defaultLibrary: MTLLibrary? = device?.makeDefaultLibrary()
        
        let capturedImageVertexFunction: MTLFunction? = defaultLibrary?.makeFunction(name: "capturedImageVertexTransform")
        let capturedImageFragmentFunction: MTLFunction? = defaultLibrary?.makeFunction(name: "capturedImageFragmentShader")
        
        // Create a vertex descriptor for our image plane vertex buffer
        let imagePlaneVertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        imagePlaneVertexDescriptor.attributes[VertexAttributes.kVertexAttributePosition.rawValue].format = MTLVertexFormat.float2
        imagePlaneVertexDescriptor.attributes[VertexAttributes.kVertexAttributePosition.rawValue].offset = 0
        imagePlaneVertexDescriptor.attributes[VertexAttributes.kVertexAttributePosition.rawValue].bufferIndex = BufferIndices.kBufferIndexMeshPositions.rawValue
        
        // Texture coordinates.
        imagePlaneVertexDescriptor.attributes[VertexAttributes.kVertexAttributeTexcoord.rawValue].format = MTLVertexFormat.float2
        imagePlaneVertexDescriptor.attributes[VertexAttributes.kVertexAttributeTexcoord.rawValue].offset = 8
        imagePlaneVertexDescriptor.attributes[VertexAttributes.kVertexAttributeTexcoord.rawValue].bufferIndex = BufferIndices.kBufferIndexMeshPositions.rawValue
        
        // Position Buffer Layout
        imagePlaneVertexDescriptor.layouts[BufferIndices.kBufferIndexMeshPositions.rawValue].stride = 16
        imagePlaneVertexDescriptor.layouts[BufferIndices.kBufferIndexMeshPositions.rawValue].stepRate = 1
        imagePlaneVertexDescriptor.layouts[BufferIndices.kBufferIndexMeshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        // Create a pipeline state for rendering the captured image
        let capturedImagePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        capturedImagePipelineStateDescriptor.label = "MyCapturedImagePipeline"
        capturedImagePipelineStateDescriptor.sampleCount = renderDestination?.sampleCount ?? 0
        capturedImagePipelineStateDescriptor.vertexFunction = capturedImageVertexFunction
        capturedImagePipelineStateDescriptor.fragmentFunction = capturedImageFragmentFunction
        capturedImagePipelineStateDescriptor.vertexDescriptor = imagePlaneVertexDescriptor
        if let colorPixelFormat = renderDestination?.colorPixelFormat {
            capturedImagePipelineStateDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        }
        if let depthStencilPixelFormat = renderDestination?.depthStencilPixelFormat {
            capturedImagePipelineStateDescriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        }
        if let depthStencilPixelFormat = renderDestination?.depthStencilPixelFormat {
            capturedImagePipelineStateDescriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        }
        
        let error: Error? = nil
        capturedImagePipelineState = try! device?.makeRenderPipelineState(descriptor: capturedImagePipelineStateDescriptor)
        if capturedImagePipelineState == nil {
            if let error = error {
                print("Failed to created captured image pipeline state, error \(error)")
            }
        }
        
        let capturedImageDepthStateDescriptor = MTLDepthStencilDescriptor()
        capturedImageDepthStateDescriptor.depthCompareFunction = .always
        capturedImageDepthStateDescriptor.isDepthWriteEnabled = false
        capturedImageDepthState = device?.makeDepthStencilState(descriptor: capturedImageDepthStateDescriptor)
        
        // Create captured image texture cache
        CVOpenGLESTextureCacheCreate(nil, nil, device as! CVEAGLContext, nil, &capturedImageTextureCache)
        
        let anchorGeometryVertexFunction: MTLFunction? = defaultLibrary?.makeFunction(name: "anchorGeometryVertexTransform")
        let anchorGeometryFragmentFunction: MTLFunction? = defaultLibrary?.makeFunction(name: "anchorGeometryFragmentLighting")
        
        // Create a vertex descriptor for our Metal pipeline. Specifies the layout of vertices the
        //   pipeline should expect. The layout below keeps attributes used to calculate vertex shader
        //   output position separate (world position, skinning, tweening weights) separate from other
        //   attributes (texture coordinates, normals).  This generally maximizes pipeline efficiency
        geometryVertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributePosition.rawValue].format = MTLVertexFormat.float3
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributePosition.rawValue].offset = 0
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributePosition.rawValue].bufferIndex = BufferIndices.kBufferIndexMeshPositions.rawValue
        
        // Texture coordinates.
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributeTexcoord.rawValue].format = MTLVertexFormat.float2
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributeTexcoord.rawValue].offset = 0
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributeTexcoord.rawValue].bufferIndex = BufferIndices.kBufferIndexMeshGenerics.rawValue
        
        // Normals.
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributeNormal.rawValue].format = MTLVertexFormat.half3
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributeNormal.rawValue].offset = 8
        geometryVertexDescriptor?.attributes[VertexAttributes.kVertexAttributeNormal.rawValue].bufferIndex = BufferIndices.kBufferIndexMeshGenerics.rawValue
        
        // Position Buffer Layout
        geometryVertexDescriptor?.layouts[BufferIndices.kBufferIndexMeshPositions.rawValue].stride = 12
        geometryVertexDescriptor?.layouts[BufferIndices.kBufferIndexMeshPositions.rawValue].stepRate = 1
        geometryVertexDescriptor?.layouts[BufferIndices.kBufferIndexMeshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        // Generic Attribute Buffer Layout
        geometryVertexDescriptor?.layouts[BufferIndices.kBufferIndexMeshGenerics.rawValue].stride = 16
        geometryVertexDescriptor?.layouts[BufferIndices.kBufferIndexMeshGenerics.rawValue].stepRate = 1
        geometryVertexDescriptor?.layouts[BufferIndices.kBufferIndexMeshGenerics.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        // Create a reusable pipeline state for rendering anchor geometry
        let anchorPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        anchorPipelineStateDescriptor.label = "MyAnchorPipeline"
        anchorPipelineStateDescriptor.sampleCount = renderDestination?.sampleCount ?? 0
        anchorPipelineStateDescriptor.vertexFunction = anchorGeometryVertexFunction
        anchorPipelineStateDescriptor.fragmentFunction = anchorGeometryFragmentFunction
        anchorPipelineStateDescriptor.vertexDescriptor = geometryVertexDescriptor
        if let colorPixelFormat = renderDestination?.colorPixelFormat {
            anchorPipelineStateDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        }
        if let depthStencilPixelFormat = renderDestination?.depthStencilPixelFormat {
            anchorPipelineStateDescriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        }
        if let depthStencilPixelFormat = renderDestination?.depthStencilPixelFormat {
            anchorPipelineStateDescriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        }
        
        anchorPipelineState = try! device?.makeRenderPipelineState(descriptor: anchorPipelineStateDescriptor)
        if anchorPipelineState == nil {
            if let error = error {
                print("Failed to created geometry pipeline state, error \(error)")
            }
        }
        
        let anchorDepthStateDescriptor = MTLDepthStencilDescriptor()
        anchorDepthStateDescriptor.depthCompareFunction = .less
        anchorDepthStateDescriptor.isDepthWriteEnabled = true
        anchorDepthState = device?.makeDepthStencilState(descriptor: anchorDepthStateDescriptor)
        
        // Create the command queue
        commandQueue = device?.makeCommandQueue()
    }
    
    func _loadAssets() {
        // Create and load our assets into Metal objects including meshes and textures
        
        // Create a MetalKit mesh buffer allocator so that ModelIO will load mesh data directly into
        //   Metal buffers accessible by the GPU
        var metalAllocator: MTKMeshBufferAllocator? = nil
        if let device = device {
            metalAllocator = MTKMeshBufferAllocator(device: device)
        }
        
        // Creata a Model IO vertexDescriptor so that we format/layout our model IO mesh vertices to
        //   fit our Metal render pipeline's vertex descriptor layout
        guard let geometryVertexDescriptor = geometryVertexDescriptor else { return }
        let vertexDescriptor: MDLVertexDescriptor? = MTKModelIOVertexDescriptorFromMetal(geometryVertexDescriptor)
        
        // Indicate how each Metal vertex descriptor attribute maps to each ModelIO attribute
        // Commented when converted since unused and throwing errors
//        vertexDescriptor?.attributes[VertexAttributes.kVertexAttributePosition.rawValue].name = MDLVertexAttributePosition
//        vertexDescriptor?.attributes[VertexAttributes.kVertexAttributeTexcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
//        vertexDescriptor?.attributes[VertexAttributes.kVertexAttributeNormal.rawValue].name = MDLVertexAttributeNormal
        
        // Use ModelIO to create a box mesh as our object
        var mesh: MDLMesh? = nil
        let float3 = vector_float3(0.075, 0.075, 0.075)
        let uint3 = vector_uint3(1, 1, 1)
        mesh = MDLMesh.newBox(withDimensions: float3, segments: uint3, geometryType: .triangles, inwardNormals: false, allocator: metalAllocator)
        
        
        // Perform the format/relayout of mesh vertices by setting the new vertex descriptor in our
        //   Model IO mesh
        if let vertexDescriptor = vertexDescriptor {
            mesh?.vertexDescriptor = vertexDescriptor
        }
        
        let error: Error? = nil
        
        // Create a MetalKit mesh (and submeshes) backed by Metal buffers
        if let mesh = mesh, let device = device {
            cubeMesh = try? MTKMesh(mesh: mesh, device: device)
        }
        
        if cubeMesh == nil || error != nil {
            print("Error creating MetalKit mesh \(error?.localizedDescription ?? "")")
        }
    }
    
    func _updateBufferStates() {
        // Update the location(s) to which we'll write to in our dynamically changing Metal buffers for
        //   the current frame (i.e. update our slot in the ring buffer used for the current frame)
        
        uniformBufferIndex = UInt8(Int((uniformBufferIndex + 1)) % kMaxBuffersInFlight)
        
        sharedUniformBufferOffset = UInt32(UInt8(kAlignedSharedUniformsSize) * uniformBufferIndex)
        anchorUniformBufferOffset = UInt32(UInt8(kAlignedInstanceUniformsSize) * uniformBufferIndex)

        // Commented when converted since unused and throwing errors
//        sharedUniformBufferAddress = sharedUniformBuffer?.contents + sharedUniformBufferOffset
//        anchorUniformBufferAddress = UInt(UInt8(anchorUniformBuffer?.contents() ?? 0)) + UInt(anchorUniformBufferOffset)
    }
    
    func _updateGameState() {
        // Update any game state
        
        let currentFrame: ARFrame? = session?.currentFrame
        
        if currentFrame == nil {
            return
        }
        
        if let currentFrame = currentFrame {
            _updateSharedUniforms(with: currentFrame)
        }
        if let currentFrame = currentFrame {
            _updateAnchors(with: currentFrame)
        }
        if let currentFrame = currentFrame {
            _updateCapturedImageTextures(with: currentFrame)
        }
        
        if viewportSizeDidChange {
            viewportSizeDidChange = false
            
            if let currentFrame = currentFrame {
                _updateImagePlane(with: currentFrame)
            }
        }
    }
    
    func _updateSharedUniforms(with frame: ARFrame) {
        // Update the shared uniforms of the frame
        var uniforms = sharedUniformBufferAddress as? SharedUniforms
        guard let orientation = orientation else { return }
        
        uniforms?.viewMatrix = frame.camera.transform.inverse
        uniforms?.projectionMatrix = frame.camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.001, zFar: 1000)
        
        // Set up lighting for the scene using the ambient intensity if provided
        var ambientIntensity: Float = 1.0
        
        if frame.lightEstimate != nil {
            ambientIntensity = Float((frame.lightEstimate?.ambientIntensity ?? 0.0) / 1000)
        }
        
        let ambientLightColor = vector_float3(0.5, 0.5, 0.5)
        uniforms?.ambientLightColor = ambientLightColor * ambientIntensity
        
        var directionalLightDirection = vector_float3(0.0, 0.0, -1.0)
        directionalLightDirection = normalize(directionalLightDirection)
        uniforms?.directionalLightDirection = directionalLightDirection
        
        let directionalLightColor = vector_float3(0.6, 0.6, 0.6)
        uniforms?.directionalLightColor = directionalLightColor * ambientIntensity
        
        uniforms?.materialShininess = 30
    }
    
    func _updateAnchors(with frame: ARFrame) {
        
        var anchorObjects = [AnyHashable]()
        
        (frame.anchors as NSArray).enumerateObjects({ obj, idx, stop in
            if (obj is ARPlaneAnchor) == false {
                if let obj = obj as? AnyHashable {
                    anchorObjects.append(obj)
                }
            }
        })
        
        // Update the anchor uniform buffer with transforms of the current frame's anchors
        let anchorInstanceCount = min(anchorObjects.count, kMaxAnchorInstanceCount)
        
        var anchorOffset: Int = 0
        if anchorInstanceCount == kMaxAnchorInstanceCount {
            anchorOffset = max(anchorObjects.count - kMaxAnchorInstanceCount, 0)
        }
        
        for index in 0..<anchorInstanceCount {
            var anchorUniforms: InstanceUniforms? = nil
            if let address = anchorUniformBufferAddress as? InstanceUniforms {
                // Commented when converted since unused and throwing errors
//                anchorUniforms = address + index
            }
            let anchor = anchorObjects[index + anchorOffset] as? ARAnchor
            
            // Flip Z axis to convert geometry from right handed to left handed
            var coordinateSpaceTransform = matrix_identity_float4x4
            coordinateSpaceTransform.columns.2.z = -1.0
            guard let transform = anchor?.transform else { return }
            anchorUniforms?.modelMatrix = matrix_multiply(transform, coordinateSpaceTransform)
        }
        
        self.anchorInstanceCount = anchorInstanceCount
    }
    
    func _updateCapturedImageTextures(with frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        
        if CVPixelBufferGetPlaneCount(pixelBuffer) < 2 {
            return
        }
        
        capturedImageTextureY = _createTexture(from: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = _createTexture(from: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
    }
    
    func _createTexture(from pixelBuffer: CVPixelBuffer?, pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
        var mtlTexture: MTLTexture? = nil
        guard let pixelBuffer = pixelBuffer,
            let capturedImageTextureCache = capturedImageTextureCache else { return nil }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVOpenGLESTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, 0, GLint(pixelFormat.rawValue), GLsizei(width), GLsizei(height), 0, 0, planeIndex, &texture)
        
        //CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(NULL, _capturedImageTextureCache, pixelBuffer, NULL, pixelFormat, width, height, planeIndex, &texture);
        guard let texture1 = texture else { return nil }
        if status == kCVReturnSuccess {
            mtlTexture = CVMetalTextureGetTexture(texture1)
        }
        
        return mtlTexture
    }
    
    func _updateImagePlane(with frame: ARFrame) {
        // Update the texture coordinates of our image plane to aspect fill the viewport
        // Commented when converted since unused and throwing errors
//        guard let orientation = orientation else { return }
//        let displayToCameraTransform: CGAffineTransform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()

//        if let vertexData = Float(imagePlaneVertexBuffer?.contents()) {
//            for index in 0..<4 {
//                let textureCoordIndex: Int = 4 * index + 2
//                let textureCoord = CGPoint(x: CGFloat(kImagePlaneVertexData[textureCoordIndex]), y: CGFloat(kImagePlaneVertexData[textureCoordIndex + 1]))
//                let transformedCoord: CGPoint = textureCoord.applying(displayToCameraTransform)
//                vertexData?[textureCoordIndex] = Float(transformedCoord.x)
//                vertexData?[textureCoordIndex + 1] = Float(transformedCoord.y)
//            }
//        }
    }
    
    func _drawCapturedImage(with renderEncoder: MTLRenderCommandEncoder?) {
        if capturedImageTextureY == nil || capturedImageTextureCbCr == nil {
            return
        }
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder?.pushDebugGroup("DrawCapturedImage")
        
        // Set render command encoder state
        renderEncoder?.setCullMode(.none)
        if let capturedImagePipelineState = capturedImagePipelineState {
            renderEncoder?.setRenderPipelineState(capturedImagePipelineState)
        }
        renderEncoder?.setDepthStencilState(capturedImageDepthState)
        
        // Set mesh's vertex buffers
        renderEncoder?.setVertexBuffer(imagePlaneVertexBuffer, offset: 0, index: BufferIndices.kBufferIndexMeshPositions.rawValue)
        
        // Set any textures read/sampled from our render pipeline
        renderEncoder?.setFragmentTexture(capturedImageTextureY, index: TextureIndices.kTextureIndexY.rawValue)
        renderEncoder?.setFragmentTexture(capturedImageTextureCbCr, index: TextureIndices.kTextureIndexCbCr.rawValue)
        
        // Draw each submesh of our mesh
        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder?.popDebugGroup()
    }
    
    func _drawAnchorGeometry(with renderEncoder: MTLRenderCommandEncoder?) {
        if anchorInstanceCount == 0 {
            return
        }
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder?.pushDebugGroup("DrawAnchors")
        
        // Set render command encoder state
        renderEncoder?.setCullMode(.back)
        if let anchorPipelineState = anchorPipelineState {
            renderEncoder?.setRenderPipelineState(anchorPipelineState)
        }
        renderEncoder?.setDepthStencilState(anchorDepthState)
        
        //[renderEncoder setTriangleFillMode:MTLTriangleFillModeLines];
        
        // Set any buffers fed into our render pipeline
        renderEncoder?.setVertexBuffer(anchorUniformBuffer, offset: Int(anchorUniformBufferOffset), index: BufferIndices.kBufferIndexInstanceUniforms.rawValue)
        renderEncoder?.setVertexBuffer(sharedUniformBuffer, offset: Int(sharedUniformBufferOffset), index: BufferIndices.kBufferIndexSharedUniforms.rawValue)
        renderEncoder?.setFragmentBuffer(sharedUniformBuffer, offset: Int(sharedUniformBufferOffset), index: BufferIndices.kBufferIndexSharedUniforms.rawValue)
        
        
        // Set mesh's vertex buffers
        for bufferIndex in 0..<(cubeMesh?.vertexBuffers.count ?? 0) {
            let vertexBuffer = cubeMesh?.vertexBuffers[bufferIndex]
            renderEncoder?.setVertexBuffer(vertexBuffer?.buffer, offset: vertexBuffer?.offset ?? 0, index: bufferIndex)
        }
        
        // Draw each submesh of our mesh
        for submesh: MTKSubmesh in cubeMesh?.submeshes ?? [] {
            renderEncoder?.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: anchorInstanceCount)
        }
        
        renderEncoder?.popDebugGroup()
    }
}
