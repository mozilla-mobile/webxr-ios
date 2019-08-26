import AVFoundation
import os
import Accelerate
import Compression

// The ARSessionConfiguration object passed to the run(_:options:) method is not supported by the current device.
let UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_CODE = 100

// A sensor required to run the session is not available.
let SENSOR_UNAVAILABLE_ARKIT_ERROR_CODE = 101

// A sensor failed to provide the required input.
let SENSOR_FAILED_ARKIT_ERROR_CODE = 102

// The user has denied your app permission to use the device camera.
let CAMERA_ACCESS_NOT_AUTHORIZED_ARKIT_ERROR_CODE = 103

// World tracking has encountered a fatal error.
let WORLD_TRACKING_FAILED_ARKIT_ERROR_CODE = 200

/**
 An enum representing the ARKit session state
 
 - ARKSessionUnknown: We don't know about the session state, probably it's been initiated but not ran yet
 - ARKSessionPaused: The session is paused
 - ARKSessionRunning: The session is running
 */
enum ARKitSessionState : Int {
    case arkSessionUnknown
    case arkSessionPaused
    case arkSessionRunning
}

enum ARKType : Int {
    case arkMetal
    case arkSceneKit
}

typealias DidUpdate = (ARKController?) -> Void
typealias DidChangeTrackingState = (ARCamera?) -> Void
typealias SessionWasInterrupted = () -> Void
typealias SessionInterruptionEnded = () -> Void
typealias DidFailSession = (Error?) -> Void
typealias DidUpdateWindowSize = () -> Void
typealias DetectionImageCreatedCompletionType = (Bool, String?) -> Void

class ARKController: NSObject {
    
    var didUpdate: DidUpdate?
    var didChangeTrackingState: DidChangeTrackingState?
    var sessionWasInterrupted: SessionWasInterrupted?
    var sessionInterruptionEnded: SessionInterruptionEnded?
    var didFailSession: DidFailSession?
    var didUpdateWindowSize: DidUpdateWindowSize?
    var interfaceOrientation: UIInterfaceOrientation = .unknown
    
    /**
     Flag indicating if we should inform the JS side about a window size update
     within the current AR Frame update. It's set to YES when the device orientation changes.
     The idea is to only send this kind of update once a Frame.
     */
    var shouldUpdateWindowSize = false
    
    /**
     Enum indicating the AR session state
     @see ARKitSessionState
     */
    var arSessionState: ARKitSessionState?
    
    // A flag representing whether the user allowed the app to send computer vision data to the web page
    var computerVisionDataEnabled = false
    
    // Request a CV frame
    var computerVisionFrameRequested = false
    
    // A flag representing whether geometry is being sent in arrays (true) or dictionaries (false)
    var geometryArrays = false
    
    // A flag representing whether Metal (true) is being used for ARKController or SceneKit (false)
    var usingMetal = false
    
    var session: ARSession?
    var request: [AnyHashable : Any] = [:]
    var configuration: ARConfiguration
    var backgroundWorldMap: ARWorldMap?
    var objects = NSMutableDictionary.init()
    /* key - JS anchor name : value - ARAnchor NSUUID string */    /// Dictionary holding ARReferenceImages by name
    var referenceImageMap = NSMutableDictionary.init()
    /// Dictionary holding completion blocks by image name
    var detectionImageActivationPromises = NSMutableDictionary.init()
    
    /// Array of anchor dictionaries that were added since the last frame.
    /// Contains the initial data of the anchor when it was added.
    var addedAnchorsSinceLastFrame = NSMutableArray.init()
    /// Dictionary holding completion blocks by image name: when an image anchor is removed,
    /// if the name exsist in this dictionary, call activate again using the callback stored here.
    var detectionImageActivationAfterRemovalPromises = NSMutableDictionary.init()
    /// Array of anchor IDs that were removed since the last frame
    var removedAnchorsSinceLastFrame = NSMutableArray.init()
    /// Dictionary holding completion blocks by image name
    var detectionImageCreationPromises = NSMutableDictionary.init()
    /// Array holding dictionaries representing detection image data
    var detectionImageCreationRequests = NSMutableArray.init()
    /**
     We don't send the face geometry on every frame, for performance reasons. This number indicates the
     current number of frames without sending the face geometry
     */
    var numberOfFramesWithoutSendingFaceGeometry: Int = 0
    // For saving WorldMap
    var worldSaveURL: URL?
    var setWorldMapPromise: SetWorldMapCompletionBlock?
    
    /// completion block for getWorldMap request
    var getWorldMapPromise: GetWorldMapCompletionBlock?
    var device: AVCaptureDevice?
    var controller: ARKControllerProtocol
    /// The CV image being sent to JS is downscaled using the metho
    /// downscaleByFactorOf2UntilLargestSideIsLessThan512AvoidingFractionalSides
    /// This call has a side effect on computerVisionImageScaleFactor, that's later used
    /// in order to scale the intrinsics of the camera
    var computerVisionImageScaleFactor: Float = 0.0
    /*
     Computer vision properties
     We hold different data structures, like accelerate, NSData, and NSString buffers,
     to avoid allocating/deallocating a huge amount of memory on each frame
     */
    /// Luma buffer
    var lumaBuffer = vImage_Buffer()
    /// A temporary luma buffer used by the Accelerate framework in the buffer scale opration
    var lumaScaleTemporaryBuffer: UnsafeMutableRawPointer?
    /// The luma buffer size that's being sent to JS
    var lumaBufferSize = CGSize.zero
    /// A data buffer holding the luma information. It's created only onced reused on every frame
    /// by means of the replaceBytesInRange method
    var lumaDataBuffer: NSMutableData?
    /// The luma string buffer being sent to JS
    var lumaBase64StringBuffer = ""
    /*
     The same properties for luma are used for chroma
     */
    var chromaBuffer = vImage_Buffer()
    var chromaScaleTemporaryBuffer: UnsafeMutableRawPointer?
    var chromaBufferSize = CGSize.zero
    var chromaDataBuffer: NSMutableData?
    var chromaBase64StringBuffer = ""
    /// Dictionary that maps a user-generated anchor ID with the one generated by ARKit
    var arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary.init()
    var arkData: [AnyHashable : Any] = [:]
    var lock: os_unfair_lock
    var computerVisionData: [AnyHashable : Any] = [:]
    var showOptions: ShowOptions = .init()
    
    var webXRAuthorizationStatus: WebXRAuthorizationState {
        didSet {
            if webXRAuthorizationStatus != oldValue {
                switch webXRAuthorizationStatus {
                case .notDetermined:
                    appDelegate().logger.debug("WebXR auth changed to not determined")
                    objects = NSMutableDictionary.init()
                case .worldSensing, .videoCameraAccess:
                    appDelegate().logger.debug("WebXR auth changed to video camera access/world sensing")
                    
                    // make sure all the anchors are in the objects[] array, and mark them as added
                    if let anchors = session?.currentFrame?.anchors {
                        for addedAnchor in anchors {
                            if objects[anchorID(for: addedAnchor)] == nil {
                                let addedAnchorDictionary = createDictionary(for: addedAnchor)
                                objects[anchorID(for: addedAnchor)] = addedAnchorDictionary
                                addedAnchorsSinceLastFrame.add(objects[anchorID(for: addedAnchor)] as Any)
                            }
                        }
                    }
                    
                    createRequestedDetectionImages()
                    
                    // Only need to do this if there's an outstanding world map request
                    if getWorldMapPromise != nil {
                        _getWorldMap()
                    }
                case .lite, .minimal, .denied:
                    appDelegate().logger.debug("WebXR auth changed to lite/minimal/denied")
                    
                    if let anchors = session?.currentFrame?.anchors {
                        for addedAnchor in anchors {
                            if objects[anchorID(for: addedAnchor)] == nil {
                                // If the anchor was not being sent but is in the approved list, start sending it
                                if shouldSend(addedAnchor) {
                                    let addedAnchorDictionary = createDictionary(for: addedAnchor)
                                    objects[anchorID(for: addedAnchor)] = addedAnchorDictionary
                                    addedAnchorsSinceLastFrame.add(objects[anchorID(for: addedAnchor)] as Any)
                                }
                            }
                        }
                    }
                    
                    if getWorldMapPromise != nil {
                        getWorldMapPromise?(false, "The user denied access to world sensing data", nil)
                        getWorldMapPromise = nil
                    }
                    
                    // Tony 2/26/19: Below for loop causing a crash when denying world access
                    //            for (NSDictionary* referenceImageDictionary in self.detectionImageCreationRequests) {
                    //                DetectionImageCreatedCompletionType block = self.detectionImageCreationPromises[referenceImageDictionary[@"uid"]];
                    //                block(NO, @"The user denied access to world sensing data");
                    //            }
                }
            }
        }
    }
    
    init(type: ARKType, rootView: UIView) {
        
        let worldTrackingConfiguration = ARWorldTrackingConfiguration()
        worldTrackingConfiguration.planeDetection = [.horizontal, .vertical]
        worldTrackingConfiguration.worldAlignment = .gravityAndHeading
        configuration = worldTrackingConfiguration
        session = ARSession()
        arSessionState = .arkSessionUnknown
        if type == .arkMetal
        {
            controller = ARKMetalController(sesion: session!, size: rootView.bounds.size)
        } else {
            controller = ARKSceneKitController(sesion: session!, size: rootView.bounds.size)
        }
        
        lock = os_unfair_lock()
        objects = NSMutableDictionary.init()
        computerVisionData = [:]
        arkData = [:]
        addedAnchorsSinceLastFrame = NSMutableArray.init()
        removedAnchorsSinceLastFrame = NSMutableArray.init()
        arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary.init()
        shouldUpdateWindowSize = true
        geometryArrays = false
        backgroundWorldMap = nil
        
        let renderView = controller.getRenderView()
        rootView.addSubview(renderView)
        renderView.translatesAutoresizingMaskIntoConstraints = false
        renderView.topAnchor.constraint(equalTo: rootView.topAnchor)
        renderView.leftAnchor.constraint(equalTo: rootView.leftAnchor)
        renderView.rightAnchor.constraint(equalTo: rootView.rightAnchor)
        renderView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
        
        controller.setHitTestFocus(renderView.center)
        
        interfaceOrientation = Utils.getInterfaceOrientationFromDeviceOrientation()
        usingMetal = type == .arkMetal
        lumaDataBuffer = nil
        lumaBase64StringBuffer = ""
        chromaDataBuffer = nil
        chromaBase64StringBuffer = ""
        computerVisionImageScaleFactor = 4.0
        lumaBufferSize = CGSize(width: 0.0, height: 0.0)
        
        webXRAuthorizationStatus = .notDetermined
        detectionImageActivationPromises = NSMutableDictionary.init()
        referenceImageMap = NSMutableDictionary.init()
        detectionImageCreationRequests = NSMutableArray.init()
        detectionImageCreationPromises = NSMutableDictionary.init()
        detectionImageActivationAfterRemovalPromises = NSMutableDictionary.init()
        
        getWorldMapPromise = nil
        setWorldMapPromise = nil
        
        let fileMgr = FileManager.default
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsDir = URL(fileURLWithPath: dirPaths[0])
        let newDir = docsDir.appendingPathComponent("maps", isDirectory: true)
        do {
            try fileMgr.createDirectory(at: newDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            worldSaveURL = nil
            appDelegate().logger.debug("Couldn't create map save directory")
        }
        worldSaveURL = newDir.appendingPathComponent("webxrviewer")
        
        super.init()
        session?.delegate = self
    }
    
    deinit {
        appDelegate().logger.debug("ARKController dealloc")
    }
    
    func viewWillTransition(to size: CGSize) {
        controller.setHitTestFocus(CGPoint(x: size.width / 2, y: size.height / 2))
        interfaceOrientation = Utils.getInterfaceOrientationFromDeviceOrientation()
    }
}
