# WebXR Viewer Changelog

* Broke down OverlayHeader.h file into Swift constants, helper functions, and properties
* Removed: RecordController, RecordState enum, recordDot, helperLabel, recordTimingLabel, recordButton, references to Microphone functionality
* Converted following to Swift: Animator, OverlayViewController, UIOverlayController
---
* Converted following to Swift: Utils, Constants, AppDelegate, LayerView, LocationManager, MessageController
---
* Removed unused class HitAnchor
* Converted following to Swift: BarView, AppStateController, TouchView, AnchorNode, FocusNode, PlaneNode, SCNNode+Show, ARSCNView+HitTest, ARKSceneKitController, HitTestResult, ARKControllerProtocol, WebController
* Alert copy updates (Issue #105)
* Changed URL bar cancel button functionality to be like Safari & change to reload button upon cancellation (Issue #73).
* Added CocoaLumberjack/Swift pod for logging in Swift.
---
* Version 1.12 has minor bug fixes to the app.
