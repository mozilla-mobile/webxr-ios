# WebXR Viewer Changelog

## 1.13
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

## 1.12
* Minor bug fixes to the app.
