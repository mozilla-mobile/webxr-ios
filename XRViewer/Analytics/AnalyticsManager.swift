//
//  AnalyticsManager.swift
//  XRViewer
//
//  Created by Roberto Garrido on 20/12/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import MozillaTelemetry

@objc enum EventCategory: Int {
    case action
    case api
    
    func name() -> String {
        switch self {
        case .action: return "action"
        case .api: return "api"
        }
    }
}

@objc enum EventMethod: Int {
    case tap
    case webXR
    case foreground
    case background
    
    func name () -> String {
        switch self {
        case .tap: return "tap"
        case .webXR: return "webXR"
        case .foreground: return "foreground"
        case .background: return "background"
        }
    }
}

@objc enum EventObject: Int {
    case recordVideoButton
    case recordPictureButton
    case relaseVideoButton
    case initialize
    case app
    
    func name () -> String {
        switch self {
        case .recordVideoButton: return "record_video_button"
        case .recordPictureButton: return "record_picture_button"
        case .relaseVideoButton: return "release_video_button"
        case .initialize: return "init"
        case .app: return "app"
        }
    }
}

public class AnalyticsManager: NSObject {
    @objc public static let sharedInstance = AnalyticsManager()
    
    override private init() {}
    
    @objc func initialize(sendUsageData: Bool) {
#if USE_ANALYTICS
        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "WebXR"
        telemetryConfig.updateChannel = "Release"
        
        telemetryConfig.isCollectionEnabled = sendUsageData
        telemetryConfig.isUploadEnabled = sendUsageData
        
        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
        Telemetry.default.add(pingBuilderType: MobileEventPingBuilder.self)
#endif
    }
    
    @objc func sendEvent(category: EventCategory, method: EventMethod, object: EventObject) {
#if USE_ANALYTICS
        let event = TelemetryEvent(category: category.name(), method: method.name(), object: object.name())
        Telemetry.default.recordEvent(event)
#endif
    }
}
