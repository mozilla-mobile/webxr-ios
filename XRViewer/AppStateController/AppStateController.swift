import UIKit

/**
 An enum representing the state of the app UI at a given time
 
 - nothing: Shows the warning labels
 - debug: Shows the helper and build label, and the AR debug info
 - url: Shows the URL Bar
 - urlDebug: Shows the URL Bar and the AR debug info
 */
@objc enum ShowMode: Int {
    case nothing    = 0
    case debug      = 1
    case url        = 2
    case urlDebug   = 3
}

enum ExclusiveStateType: Int {
    case exclusiveStateMessage
    case exclusiveStateMemory
    case exclusiveStateBackground
    case exclusiveStateReachability
}

class AppStateController: NSObject {
    @objc var state: AppState
    var onModeUpdate: ((ShowMode) -> Void)?
    var onOptionsUpdate: ((ShowOptions) -> Void)?
    @objc var onXRUpdate: ((Bool) -> Void)?
    @objc var onRequestUpdate: (([AnyHashable : Any]?) -> Void)?
    @objc var onDebug: ((Bool) -> Void)?
    @objc var onMemoryWarning: ((String?) -> Void)?
    @objc var onEnterForeground: ((String?) -> Void)?
    @objc var onReachable: ((String?) -> Void)?
    private var exclusives: [ExclusiveState] = []

    @objc init(state: AppState) {
        self.state = state
        super.init()

        exclusives = [ExclusiveState]()
    }

    func setShowMode(_ mode: ShowMode) {
        if mode != state.showMode {
            guard let onDebug = onDebug else { return }
            DispatchQueue.main.async {
                onDebug(mode == ShowMode.urlDebug)
            }
        }

        self.state = state.updatedShowMode(mode)
        guard let onModeUpdate = onModeUpdate else { return }
        let showMode = state.showMode
        DispatchQueue.main.async {
            onModeUpdate(showMode)
        }
    }

    func setShowOptions(_ options: ShowOptions) {
        state = state.updatedShowOptions(options)
        guard let onOptionsUpdate = onOptionsUpdate else { return }
        let showOptions = state.showOptions
        DispatchQueue.main.async {
            onOptionsUpdate(showOptions)
        }
    }

    @objc func setWebXR(_ webXR: Bool) {
        state = state.updatedWebXR(webXR)
        guard let onXRUpdate = onXRUpdate else { return }
        let webXR = state.webXR
        DispatchQueue.main.async {
            onXRUpdate(webXR)
        }
    }

    @objc func setARRequest(_ dict: [AnyHashable : Any], completed: @escaping () -> ()) {
        state = state.updated(withARRequest: dict)
        guard let onRequestUpdate = onRequestUpdate else { return }
        DispatchQueue.main.async {
            onRequestUpdate(dict)
            completed()
        }
    }

    @objc func invertDebugMode() {
        state.showMode == ShowMode.url ? setShowMode(ShowMode.urlDebug) : setShowMode(ShowMode.url)
    }

    @objc func shouldShowURLBar() -> Bool {

        var showURLBar = false

        if !state.webXR {
            showURLBar = true
        } else {
            if state.showMode == .debug {
                showURLBar = false
            } else if state.showMode == .url {
                showURLBar = true
            } else if state.showMode == .urlDebug {
                showURLBar = true
            }
        }

        return showURLBar
    }

    @objc func shouldSendARKData() -> Bool {
        return state.webXR && !state.aRRequest.isEmpty
    }

    @objc func shouldSendCVData() -> Bool {
        return state.computerVisionFrameRequested && state.sendComputerVisionData && state.userGrantedSendingComputerVisionData
    }

    @objc func shouldSendNativeTime() -> Bool {
        return state.numberOfTimesSendNativeTimeWasCalled < 2
    }

    @objc func wasMemoryWarning() -> Bool {
        var was = false

        (exclusives as NSArray).enumerateObjects({ obj, idx, stop in
            if let obj = obj as? ExclusiveState {
                if obj.type == .exclusiveStateMemory {
                    was = true
                    stop.pointee = true
                }
            }
        })

        return was
    }
    // rf ?

    @objc func saveOnMessageShowMode() {
        save(on: .exclusiveStateMessage, url: nil, mode: state.showMode)
    }

    @objc func applyOnMessageShowMode() {
        apply(on: .exclusiveStateMessage)
    }

    @objc func saveDidReceiveMemoryWarning(onURL url: String?) {
        if let aMode = ShowMode(rawValue: 0) {
            save(on: .exclusiveStateMemory, url: url, mode: aMode)
        }
    }

    @objc func applyOnDidReceiveMemoryAction() {
        apply(on: .exclusiveStateMemory)
    }

    @objc func saveMoveToBackground(onURL url: String?) {
        setShowMode(ShowMode.nothing)
        if let aMode = ShowMode(rawValue: 0) {
            save(on: .exclusiveStateBackground, url: url, mode: aMode)
        }
    }

    @objc func applyOnEnterForegroundAction() {
        apply(on: .exclusiveStateBackground)
    }

    @objc func saveNotReachable(onURL url: String?) {
        if let aMode = ShowMode(rawValue: 0) {
            save(on: .exclusiveStateReachability, url: url, mode: aMode)
        }
    }

    @objc func applyOnReachableAction() {
        apply(on: .exclusiveStateReachability)
    }

// MARK: Private

    func save(on type: ExclusiveStateType, url: String?, mode: ShowMode) {
        let state = ExclusiveState()
        if url != nil {
            state.url = url ?? ""
        } else {
            state.mode = mode
        }
        state.type = type

        weak var blockSelf: AppStateController? = self

        switch type {
            case .exclusiveStateMessage:
                state.action = {
                    blockSelf?.setShowMode(mode)
                }
            case .exclusiveStateMemory:
                state.action = {
                    guard let onMemoryWarning = blockSelf?.onMemoryWarning else {
                        print("Unable to set onMemoryWarning")
                        return
                    }
                    DispatchQueue.main.async {
                        onMemoryWarning(url)
                    }
                }
            case .exclusiveStateBackground:
                state.action = {
                    guard let onEnterForeground = blockSelf?.onEnterForeground else {
                        print("Unable to set onEnterForeground")
                        return
                    }
                    DispatchQueue.main.async {
                        onEnterForeground(url)
                    }
                }
            case .exclusiveStateReachability:
                state.action = {
                    guard let onReachable = blockSelf?.onReachable else {
                        print("Unable to set onReachable")
                        return
                    }
                    DispatchQueue.main.async {
                        onReachable(url)
                    }
                }
        }

        exclusives.append(state)
    }

    func apply(on type: ExclusiveStateType) {
        var message: ExclusiveState? = nil

        (exclusives as NSArray).enumerateObjects({ obj, idx, stop in
            if let obj = obj as? ExclusiveState {
                if obj.type == type {
                    message = obj
                    stop.pointee = true
                }
            }
        })

        if let message: ExclusiveState = message {
            if let action = message.action {
                action()
            }
            exclusives.removeAll { $0 == message }
        }
    }
}

class ExclusiveState: NSObject {
    var action: (() -> Void)?
    var url = ""
    var type: ExclusiveStateType?
    var mode: ShowMode?
}
