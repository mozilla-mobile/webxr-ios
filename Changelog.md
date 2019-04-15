# WebXR Viewer Changelog
* Added privacy-focused Lite Mode
* Added button to URL bar to review, revoke, or grant permissions in-flight for each site
* Revamped the permissioning process (new UI, new UX, more granular permissions)
* Reconfigured Lite Mode so user can choose which plane to pass in
* Point to Swift 4 compatible version of Mozilla Telemetry pod
* Changed popup widths for iPad compatibility
* Added 'WEBSERVER' custom flag for Debug compilations
* Converted, separated functions to ARKController+Anchors, ARKController+AppState, ARKController+Images, ARKController+ARSessionDelegate, ARKController+WorldMap, ARKController+Camera, ARKController+Frame
* Convert following enums to Swift: ResetTrackingOption, ShowMode
* Moved ARSession methods to ViewController+ARSCNViewDelegate
* Fixed dropped frames and CV low FPS issue with ARFaceAnchors
* Fixed Settings.bundle check in AppDelegate
* Removed: Legacy ARKit interruption code, legacy MessageController functions, unused hasPlanes & currentPlanesArray functions
* Converted following to Swift: AppState, Prefix, ARKMetalController, ShaderTypes, WekARKHeader
---
* Moved buildLabel to bottom left to prevent overlap with home indicator
* Added TextManager class
* Started coordinating ARKit updates via ViewController+ARSCNViewDelegate
* Implemented: messagePanel, messageLabel for tracking updates
* Broke down OverlayHeader.h file into Swift constants, helper functions, and properties
* Removed: RecordController, RecordState enum, recordDot, helperLabel, recordTimingLabel, recordButton, references to Microphone functionality, legacy ARKit tracking state code & images
* Dropped in Swift version of Reachability
* Converted following to Swift: ViewController, Animator, OverlayViewController, UIOverlayController
* Converted following to Swift: Utils, Constants, AppDelegate, LayerView, LocationManager, MessageController
* Removed unused class HitAnchor
* Converted following to Swift: BarView, AppStateController, TouchView, AnchorNode, FocusNode, PlaneNode, SCNNode+Show, ARSCNView+HitTest, ARKSceneKitController, HitTestResult, ARKControllerProtocol, WebController
* Alert copy updates (Issue #105)
* Changed URL bar cancel button functionality to be like Safari & change to reload button upon cancellation (Issue #73)
* Added CocoaLumberjack/Swift pod for logging in Swift
---
* Minor bug fixes to the app.
