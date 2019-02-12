//
//  AnalyticsManager.swift
//  XRViewer
//
//  Created by Roberto Garrido on 20/12/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
#if USE_ANALYTICS
import MozillaTelemetry
#endif

/**
Category of the event being tracked
- action
- api
*/
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

/**
Method of the event being tracked
- tap: when the user taps on anything within the app
- webXR: when there is an action initiated by the webXR API
- foreground: when the app goes to foreground
- background: when the app goes to background
*/
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

/**
Event being tracked
- initialize: when the app initializes
- app: when there is an event related with the app
*/
@objc enum EventObject: Int {
    case initialize
    case app
    
    func name () -> String {
        switch self {
        case .initialize: return "init"
        case .app: return "app"
        }
    }
}

/// A class managing the tracking of the events within the app
public class AnalyticsManager: NSObject {
    @objc public static let sharedInstance = AnalyticsManager()
    
    override private init() {}

    /// Initializes the telemetry framework
    ///
    /// - Parameter sendUsageData: whether we want to send user data
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

    /// Sends an event to telemetry
    ///
    /// - Parameters:
    ///   - category: The category of the event. See EventCategory.
    ///   - method: The method of the event. See EventMethod.
    ///   - object: The object of the event. See EventObject.
    @objc func sendEvent(category: EventCategory, method: EventMethod, object: EventObject) {
#if USE_ANALYTICS
        let event = TelemetryEvent(category: category.name(), method: method.name(), object: object.name())
        Telemetry.default.recordEvent(event)
#endif
    }
}
