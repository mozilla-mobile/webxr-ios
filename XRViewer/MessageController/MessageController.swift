import UIKit
import PopupDialog

typealias DidShowMessage = () -> Void
typealias DidHideMessage = () -> Void
typealias DidHideMessageByUser = () -> Void

class MessageController: NSObject {
    @objc var didShowMessage: DidShowMessage?
    @objc var didHideMessage: DidHideMessage?
    @objc var didHideMessageByUser: DidHideMessageByUser?
    private weak var viewController: UIViewController?
    private weak var arPopup: PopupDialog?

    @objc init(viewController vc: UIViewController?) {
        super.init()
        
        viewController = vc
        setupAppearance()
    }
    
    deinit {
        DDLogDebug("MessageController dealloc")
    }
    
    @objc func clean() {
        if arPopup != nil {
            arPopup?.dismiss(animated: false)
            
            self.arPopup = nil
        }
        
        if viewController?.presentedViewController != nil {
            viewController?.presentedViewController?.dismiss(animated: false)
        }
    }
    
    func arMessageShowing() -> Bool {
        return arPopup != nil
    }

    @objc func showMessageAboutWebError(_ error: Error?, withCompletion reloadCompletion: @escaping (_ reload: Bool) -> Void) {
        let popup = PopupDialog(title: "Cannot open the page", message: "Please check the URL and try again", image: nil, buttonAlignment: NSLayoutConstraint.Axis.horizontal, transitionStyle: .bounceUp, preferredWidth: 200.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        let cancel = DestructiveButton(title: "Ok", height: 40, dismissOnTap: true, action: {
                reloadCompletion(false)

                self.didHideMessageByUser?()
            })

        let ok = DefaultButton(title: "Reload", height: 40, dismissOnTap: true, action: {
                reloadCompletion(true)

                self.didHideMessageByUser?()
            })

        popup.addButtons([cancel, ok])
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    @objc func showMessageAboutARInterruption(_ interrupt: Bool) {
        if interrupt && arPopup == nil {
            let popup = PopupDialog(title: "AR Interruption Occurred", message: "Please wait, it should be fixed automatically", image: nil, buttonAlignment: NSLayoutConstraint.Axis.horizontal, transitionStyle: .bounceUp, preferredWidth: 200.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

            self.arPopup = popup

            viewController?.present(popup, animated: true)

            didShowMessage?()
        } else if !interrupt && arPopup != nil {
            arPopup?.dismiss(animated: true)
            self.arPopup = nil
            didHideMessage?()
        }
    }

    @objc func showMessageAboutFailSession(withMessage message: String?, completion: @escaping () -> Void) {
        let popup = PopupDialog(title: "AR Session Failed", message: message, image: nil, buttonAlignment: NSLayoutConstraint.Axis.horizontal, transitionStyle: .bounceUp, preferredWidth: 200.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        let ok = DefaultButton(title: "Ok", height: 40, dismissOnTap: true, action: {
                popup.dismiss(animated: true)
                self.didHideMessageByUser?()
                completion()
            })

        popup.addButtons([ok])
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    @objc func showMessage(withTitle title: String?, message: String?, hideAfter seconds: Int) {
        let popup = PopupDialog(title: title, message: message, image: nil, buttonAlignment: NSLayoutConstraint.Axis.horizontal, transitionStyle: .zoomIn, preferredWidth: 200.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        viewController?.present(popup, animated: true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(seconds * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            popup.dismiss(animated: true)
        })
    }

    @objc func showMessageAboutMemoryWarning(withCompletion completion: @escaping () -> Void) {
        let popup = PopupDialog(title: "Memory Issue Occurred", message: "There was not enough memory for the application to keep working", image: nil, buttonAlignment: NSLayoutConstraint.Axis.horizontal, transitionStyle: .bounceUp, preferredWidth: 200.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        let ok = DefaultButton(title: "Ok", height: 40, dismissOnTap: true, action: {
                popup.dismiss(animated: true)

                completion()
            
                self.didHideMessageByUser?()
            })

        popup.addButtons([ok])
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    @objc func showMessageAboutConnectionRequired() {
        let popup = PopupDialog(title: "Internet connection is unavailable", message: "Application will restart automatically when a connection becomes available", image: nil, buttonAlignment: NSLayoutConstraint.Axis.horizontal, transitionStyle: .bounceUp, preferredWidth: 200.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        let ok = DefaultButton(title: "Ok", height: 40, dismissOnTap: true, action: {
                popup.dismiss(animated: true)

                self.didHideMessageByUser?()
            })

        popup.addButtons([ok])
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    @objc func showMessageAboutResetTracking(_ responseBlock: @escaping (ResetTrackingOption) -> Void) {
        let popup = PopupDialog(title: "Reset tracking", message: "Please select one of the options below", image: nil, buttonAlignment: NSLayoutConstraint.Axis.vertical, transitionStyle: .bounceUp, preferredWidth: 200.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        let resetTracking = DefaultButton(title: "Completely restart tracking", height: 40, dismissOnTap: true, action: {
                responseBlock(.ResetTracking)
            })
        resetTracking.titleColor = resetTracking.tintColor

        let removeExistingAnchors = DefaultButton(title: "Remove known anchors", height: 40, dismissOnTap: true, action: {
                responseBlock(.RemoveExistingAnchors)
            })
        removeExistingAnchors.titleColor = removeExistingAnchors.tintColor

        let saveWorldMap = DefaultButton(title: "Save World Map", height: 40, dismissOnTap: true, action: {
                responseBlock(.SaveWorldMap)
            })
        saveWorldMap.titleColor = saveWorldMap.tintColor

        let loadWorldMap = DefaultButton(title: "Load previously saved World Map", height: 40, dismissOnTap: true, action: {
                responseBlock(.LoadSavedWorldMap)
            })
        loadWorldMap.titleColor = loadWorldMap.tintColor

        let cancelButton = CancelButton(title: "Cancel", height: 40, dismissOnTap: true, action: {
            })
        cancelButton.titleColor = cancelButton.tintColor

        popup.addButtons([resetTracking, removeExistingAnchors, saveWorldMap, loadWorldMap, cancelButton])

        viewController?.present(popup, animated: true)
    }

    @objc func showMessageAboutAccessingTheCapturedImage(_ granted: @escaping (Bool) -> Void) {
        let popup = PopupDialog(title: "Video Camera Image Access", message: "WebXR Viewer displays video from your camera without giving the web page access to the video.\n\nThis page is requesting access to images from the video camera. Allow?", image: nil, buttonAlignment: NSLayoutConstraint.Axis.horizontal, transitionStyle: .bounceUp, preferredWidth: 340.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        let ok = DestructiveButton(title: "YES", height: 40, dismissOnTap: true, action: {
                granted(true)
            })
        ok.titleColor = UIColor.blue

        let cancel = DefaultButton(title: "NO", height: 40, dismissOnTap: true, action: {
                granted(false)
            })

        popup.addButtons([cancel, ok])
        viewController?.present(popup, animated: true)
    }

    @objc func showPermissionsPopup() {
        let viewController = RequestPermissionsViewController()
        viewController.view.translatesAutoresizingMaskIntoConstraints = true
        viewController.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true

        let dialog = PopupDialog(viewController: viewController, buttonAlignment: NSLayoutConstraint.Axis.vertical, transitionStyle: .bounceUp, preferredWidth: UIScreen.main.bounds.size.width / 2.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true) {
            }

        self.viewController?.present(dialog, animated: true)
    }

    @objc func showMessageAboutAccessingWorldSensingData(_ granted: @escaping (Bool) -> Void, url: URL?) {
        let standardUserDefaults = UserDefaults.standard
        let allowedWorldSensingSites = standardUserDefaults.dictionary(forKey: Constant.allowedWorldSensingSitesKey())
        var site: String? = nil
        if let aPort = url?.port {
            site = url?.host ?? "" + (":\(aPort)")
        }

        // Check global permission.
        if standardUserDefaults.bool(forKey: Constant.alwaysAllowWorldSensingKey()) {
            granted(true)
            return
        }

        // Check per-site permission.
        if allowedWorldSensingSites != nil {
            if allowedWorldSensingSites?[site ?? ""] != nil {
                granted(true)
                return
            }
        }

        let popup = PopupDialog(title: "Access to World Sensing", message: "This webpage wants to use your camera to look for faces and things in the real world. (For details, see our Privacy Notice in Settings.) Allow?", image: nil, buttonAlignment: NSLayoutConstraint.Axis.vertical /* Horizontal */, transitionStyle: .bounceUp, preferredWidth: 340.0, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: true)

        let always = DestructiveButton(title: "Always for this site", height: 40, dismissOnTap: true, action: {

                // don't set global permission...
                // [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:alwaysAllowWorldSensingKey];
                self.showMessage(withTitle: "Site will not Require Permission in the Future", message: "'Reset Allowed World Sensing' in Settings to reset for all sites.", hideAfter: 3)

                // instead, encode the domain/site into the allowed list
                var newDict = [AnyHashable : Any]()
                if allowedWorldSensingSites != nil {
                    if let aCopy = allowedWorldSensingSites {
                        newDict = aCopy
                    }
                }
                newDict[site ?? ""] = "YES"
                UserDefaults.standard.set(newDict, forKey: Constant.allowedWorldSensingSitesKey())

                granted(true)
            })

        let ok = DestructiveButton(title: "This time only", height: 40, dismissOnTap: true, action: {
                granted(true)
            })
        ok.titleColor = UIColor.blue

        let cancel = DefaultButton(title: "NO", height: 40, dismissOnTap: true, action: {
                granted(false)
            })

        popup.addButtons([cancel, ok, always])
        viewController?.present(popup, animated: true)
    }
    
    @objc func hideMessages() {
        viewController?.presentedViewController?.dismiss(animated: true)
    }

    // MARK: private

    func setupAppearance() {
        guard let largeFont = UIFont(name: "MyriadPro-Regular", size: 22) else { return }
        guard let smallFont = UIFont(name: "MyriadPro-Regular", size: 18) else { return }
        PopupDialogDefaultView.appearance().backgroundColor = UIColor.clear
        PopupDialogDefaultView.appearance().titleFont = largeFont
        PopupDialogDefaultView.appearance().titleColor = UIColor.black
        PopupDialogDefaultView.appearance().messageFont = smallFont
        PopupDialogDefaultView.appearance().messageColor = UIColor.gray

        PopupDialogOverlayView.appearance().color = UIColor(white: 0, alpha: 0.5)
        PopupDialogOverlayView.appearance().blurRadius = 10
        PopupDialogOverlayView.appearance().blurEnabled = true
        PopupDialogOverlayView.appearance().liveBlurEnabled = false
        PopupDialogOverlayView.appearance().opacity = 0.5

        DefaultButton.appearance().titleFont = largeFont
        DefaultButton.appearance().titleColor = UIColor.gray
        DefaultButton.appearance().buttonColor = UIColor.clear
        DefaultButton.appearance().separatorColor = UIColor(white: 0.8, alpha: 1)

        CancelButton.appearance().titleColor = UIColor.gray
        CancelButton.appearance().titleFont = largeFont
        
        DestructiveButton.appearance().titleColor = UIColor.red
        DestructiveButton.appearance().titleFont = largeFont
    }
}
