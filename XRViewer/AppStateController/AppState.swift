import Foundation

let SHOW_MODE_BY_DEFAULT = ShowMode.nothing
let SHOW_OPTIONS_BY_DEFAULT = ShowOptions.init(rawValue: 0)
let POPUP_ENABLED_BY_DEFAULT = true
let USER_GRANTED_SENDING_COMPUTER_VISION_DATA_BY_DEFAULT = false

/**
 The app internal state
 */
@objc class AppState: NSObject, NSCopying {
    @objc var aRRequest: [AnyHashable : Any] = [:]
    var trackingState = ""
    @objc var showMode: ShowMode = .nothing
    @objc var showOptions: ShowOptions = .init(rawValue: 0)
    var webXR = false
    var computerVisionFrameRequested = false
    var shouldRemoveAnchorsOnNextARSession = false
    var sendComputerVisionData = false
    var shouldShowSessionStartedPopup = false
    var shouldShowLiteModePopup = false
    var numberOfTimesSendNativeTimeWasCalled: Int = 0
    @objc var userGrantedSendingComputerVisionData = false
    @objc var askedComputerVisionData = false
    @objc var userGrantedSendingWorldStateData: SendWorldSensingDataAuthorizationState = .notDetermined
    @objc var askedWorldStateData = false

    class func defaultState() -> AppState {
        let state = AppState()

        state.showMode = SHOW_MODE_BY_DEFAULT
        state.showOptions = SHOW_OPTIONS_BY_DEFAULT
        state.shouldShowSessionStartedPopup = POPUP_ENABLED_BY_DEFAULT
        state.shouldShowLiteModePopup = true
        state.numberOfTimesSendNativeTimeWasCalled = 0
        state.userGrantedSendingComputerVisionData = USER_GRANTED_SENDING_COMPUTER_VISION_DATA_BY_DEFAULT
        state.userGrantedSendingWorldStateData = .denied
        state.askedComputerVisionData = false
        state.askedWorldStateData = false

        // trackingstate default is nil ?

        return state
    }

    func updatedShowMode(_ showMode: ShowMode) -> Self {
        self.showMode = showMode
        return self
    }

    func updatedShowOptions(_ showOptions: ShowOptions) -> Self {
        self.showOptions = showOptions
        return self
    }

    func updatedWebXR(_ webXR: Bool) -> Self {
        self.webXR = webXR
        return self
    }

    func updated(withARRequest dict: [AnyHashable : Any]?) -> Self {
        guard let dict = dict else { return self }
        aRRequest = dict
        return self
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = AppState()
        copy.showOptions = showOptions
        copy.showMode = showMode
        copy.webXR = webXR
        copy.aRRequest = aRRequest
        copy.computerVisionFrameRequested = computerVisionFrameRequested
        copy.shouldRemoveAnchorsOnNextARSession = shouldRemoveAnchorsOnNextARSession
        copy.sendComputerVisionData = sendComputerVisionData
        copy.shouldShowSessionStartedPopup = shouldShowSessionStartedPopup
        copy.shouldShowLiteModePopup = shouldShowLiteModePopup
        copy.numberOfTimesSendNativeTimeWasCalled = numberOfTimesSendNativeTimeWasCalled
        copy.userGrantedSendingComputerVisionData = userGrantedSendingComputerVisionData
        copy.askedComputerVisionData = askedComputerVisionData
        copy.userGrantedSendingWorldStateData = userGrantedSendingWorldStateData
        copy.askedWorldStateData = askedWorldStateData

        return copy
    }
}
