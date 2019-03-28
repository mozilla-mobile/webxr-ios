//
//  Header containing types and enum constants shared between Metal shaders and C/ObjC source
//

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
enum BufferIndices : Int {
    case kBufferIndexMeshPositions    = 0
    case kBufferIndexMeshGenerics     = 1
    case kBufferIndexInstanceUniforms = 2
    case kBufferIndexSharedUniforms   = 3
}

// Attribute index values shared between shader and C code to ensure Metal shader vertex
//   attribute indices match the Metal API vertex descriptor attribute indices
enum VertexAttributes : Int {
    case kVertexAttributePosition = 0
    case kVertexAttributeTexcoord = 1
    case kVertexAttributeNormal   = 2
}

// Texture index values shared between shader and C code to ensure Metal shader texture indices
//   match indices of Metal API texture set calls
enum TextureIndices : Int {
    case kTextureIndexColor = 0
    case kTextureIndexY     = 1
    case kTextureIndexCbCr  = 2
}

// Structure shared between shader and C code to ensure the layout of shared uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code
struct SharedUniforms {
    // Camera Uniforms
    var projectionMatrix: matrix_float4x4
    var viewMatrix: matrix_float4x4
    
    // Lighting Properties
    var ambientLightColor: vector_float3
    var directionalLightDirection: vector_float3
    var directionalLightColor: vector_float3
    var materialShininess: Float
}

// Structure shared between shader and C code to ensure the layout of instance uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code
struct InstanceUniforms {
    var modelMatrix: matrix_float4x4
}
