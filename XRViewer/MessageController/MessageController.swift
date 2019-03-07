import UIKit
import PopupDialog
import CocoaLumberjack

typealias DidShowMessage = () -> Void
typealias DidHideMessage = () -> Void
typealias DidHideMessageByUser = () -> Void

class MessageController: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    @objc var didShowMessage: DidShowMessage?
    @objc var didHideMessage: DidHideMessage?
    @objc var didHideMessageByUser: DidHideMessageByUser?
    private weak var viewController: UIViewController?
    private weak var arPopup: PopupDialog?
    private var tableViewController = UITableViewController()
    private var webXRAuthorizationRequested: WebXRAuthorizationState = .notDetermined
    var forceShowPermissionsPopup = false

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
    
    @objc func hideMessages() {
        viewController?.presentedViewController?.dismiss(animated: true)
    }

    @objc func showMessageAboutWebError(_ error: Error?, withCompletion reloadCompletion: @escaping (_ reload: Bool) -> Void) {
        let popup = PopupDialog(
            title: "Cannot Open the Page",
            message: "Please check the URL and try again",
            image: nil,
            buttonAlignment: NSLayoutConstraint.Axis.horizontal,
            transitionStyle: .bounceUp,
            preferredWidth: 340.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

        let cancel = CancelButton(title: "Ok", height: 40, dismissOnTap: true, action: {
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
            let popup = PopupDialog(
                title: "AR Interruption Occurred",
                message: "Please wait, it should be fixed automatically",
                image: nil,
                buttonAlignment: NSLayoutConstraint.Axis.horizontal,
                transitionStyle: .bounceUp,
                preferredWidth: 340.0,
                tapGestureDismissal: false,
                panGestureDismissal: false,
                hideStatusBar: true
            )

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
        let popup = PopupDialog(
            title: "AR Session Failed",
            message: message,
            image: nil,
            buttonAlignment: NSLayoutConstraint.Axis.horizontal,
            transitionStyle: .bounceUp,
            preferredWidth: 340.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

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
        let popup = PopupDialog(
            title: title,
            message: message,
            image: nil,
            buttonAlignment: NSLayoutConstraint.Axis.horizontal,
            transitionStyle: .zoomIn,
            preferredWidth: 340.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

        viewController?.present(popup, animated: true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(seconds * Int(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            popup.dismiss(animated: true)
        })
    }

    @objc func showMessageAboutMemoryWarning(withCompletion completion: @escaping () -> Void) {
        let popup = PopupDialog(
            title: "Memory Issue Occurred",
            message: "There was not enough memory for the application to keep working",
            image: nil,
            buttonAlignment: NSLayoutConstraint.Axis.horizontal,
            transitionStyle: .bounceUp,
            preferredWidth: 340.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

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
        let popup = PopupDialog(
            title: "Internet Connection is Unavailable",
            message: "Application will restart automatically when a connection becomes available",
            image: nil,
            buttonAlignment: NSLayoutConstraint.Axis.horizontal,
            transitionStyle: .bounceUp,
            preferredWidth: 340.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

        let ok = DefaultButton(title: "Ok", height: 40, dismissOnTap: true, action: {
                popup.dismiss(animated: true)

                self.didHideMessageByUser?()
            })

        popup.addButtons([ok])
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    @objc func showMessageAboutResetTracking(_ responseBlock: @escaping (ResetTrackingOption) -> Void) {
        let popup = PopupDialog(
            title: "Reset Tracking",
            message: "Please select one of the options below",
            image: nil,
            buttonAlignment: NSLayoutConstraint.Axis.vertical,
            transitionStyle: .bounceUp,
            preferredWidth: 340.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

        let resetTracking = DefaultButton(title: "Completely restart tracking", height: 40, dismissOnTap: true, action: {
                responseBlock(.ResetTracking)
            })

        let removeExistingAnchors = DefaultButton(title: "Remove known anchors", height: 40, dismissOnTap: true, action: {
                responseBlock(.RemoveExistingAnchors)
            })

        let saveWorldMap = DefaultButton(title: "Save World Map", height: 40, dismissOnTap: true, action: {
                responseBlock(.SaveWorldMap)
            })

        let loadWorldMap = DefaultButton(title: "Load previously saved World Map", height: 40, dismissOnTap: true, action: {
                responseBlock(.LoadSavedWorldMap)
            })

        let cancelButton = CancelButton(title: "Cancel", height: 40, dismissOnTap: true, action: {
            })

        popup.addButtons([resetTracking, removeExistingAnchors, saveWorldMap, loadWorldMap, cancelButton])

        viewController?.present(popup, animated: true)
    }

    @objc func showMessageAboutAccessingTheCapturedImage(_ granted: @escaping (Bool) -> Void) {
        let popup = PopupDialog(
            title: "Video Camera Image Access",
            message: "WebXR Viewer displays video from your camera without giving the web page access to the video.\n\nThis page is requesting access to images from the video camera. Allow?",
            image: nil,
            buttonAlignment: NSLayoutConstraint.Axis.horizontal,
            transitionStyle: .bounceUp,
            preferredWidth: 340.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

        let ok = DefaultButton(title: "YES", height: 40, dismissOnTap: true, action: {
                granted(true)
            })

        let cancel = CancelButton(title: "NO", height: 40, dismissOnTap: true, action: {
                granted(false)
            })

        popup.addButtons([cancel, ok])
        viewController?.present(popup, animated: true)
    }

    @objc func showPermissionsPopup() {
        let viewController = RequestPermissionsViewController()
        viewController.view.translatesAutoresizingMaskIntoConstraints = true
        viewController.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true

        let dialog = PopupDialog(
            viewController: viewController,
            buttonAlignment: NSLayoutConstraint.Axis.vertical,
            transitionStyle: .bounceUp,
            preferredWidth: UIScreen.main.bounds.size.width / 2.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

        self.viewController?.present(dialog, animated: true)
    }
    
    @objc func showMessageAboutEnteringXR(_ authorizationRequested: WebXRAuthorizationState, authorizationGranted: @escaping (WebXRAuthorizationState) -> Void, url: URL) {
        let standardUserDefaults = UserDefaults.standard
        let allowedWorldSensingSites = standardUserDefaults.dictionary(forKey: Constant.allowedWorldSensingSitesKey())
        let allowedVideoCameraSites = standardUserDefaults.dictionary(forKey: Constant.allowedVideoCameraSitesKey())
        guard var site: String = url.host else { return }
        webXRAuthorizationRequested = authorizationRequested
        
        if let port = url.port {
            site = site + ":\(port)"
        }
        
        // Check whether .minimal WebXR has been granted
        if authorizationRequested == .minimal
            && standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled())
            && !forceShowPermissionsPopup
        {
            authorizationGranted(.minimal)
            return
        }
        
        // Check global world sensing permission
        if authorizationRequested == .worldSensing
            && standardUserDefaults.bool(forKey: Constant.alwaysAllowWorldSensingKey())
            && !forceShowPermissionsPopup
        {
            authorizationGranted(.worldSensing)
            return
        }
        
        // Check per-site permission
        if authorizationRequested == .worldSensing
            && standardUserDefaults.bool(forKey: Constant.worldSensingWebXREnabled())
            && allowedWorldSensingSites != nil
            && !forceShowPermissionsPopup
        {
            if allowedWorldSensingSites?[site] != nil {
                authorizationGranted(.worldSensing)
                return
            }
        }
        if authorizationRequested == .videoCameraAccess
            && standardUserDefaults.bool(forKey: Constant.videoCameraAccessWebXREnabled())
            && allowedVideoCameraSites != nil
            && !forceShowPermissionsPopup
        {
            if allowedVideoCameraSites?[site] != nil {
                authorizationGranted(.videoCameraAccess)
                return
            }
        }
        forceShowPermissionsPopup = false
        var title: String
        var message: String
        switch webXRAuthorizationRequested {
        case .minimal:
            title = "This site is requesting basic WebXR authorization"
            message = "Basic WebXR authorization displays video from your camera without giving this web page access to the video."
        case .lite:
            title = "This site is requesting Lite Mode authorization"
            message = "Lite Mode allows this site to:\n-Use a single plane from the real world\n-Look for faces"
        case .worldSensing:
            title = "This site is requesting World Sensing authorization"
            message = "World Sensing allows this site to:\n-Use planes detected in the real world\n-Look for faces\n-Look for reference images"
        case .videoCameraAccess:
            title = "This site is requesting Video Camera Access authorization"
            message = "Video Camera Access allows this site to:\n-Access the live images from your video camera\n-Use planes detected in the real world\n-Look for faces \n-Look for reference images"
        default:
            title = "This site is not requesting WebXR authorization"
            message = "No video from your camera, planes, faces, or things in the real world will be shared with this site."
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            switch self.webXRAuthorizationRequested {
            case .minimal:
                authorizationGranted(standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) ? .minimal : .denied)
            case .lite:
                authorizationGranted(standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) ? .lite : .denied)
            case .worldSensing:
                if standardUserDefaults.bool(forKey: Constant.worldSensingWebXREnabled()) {
                    guard let worldControl = self.tableViewController.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SegmentedControlTableViewCell else { return }
                    if worldControl.segmentedControl.selectedSegmentIndex == 1 {
                        var newDict = [AnyHashable : Any]()
                        if let dict = allowedWorldSensingSites {
                            newDict = dict
                        }
                        newDict[site] = "YES"
                        UserDefaults.standard.set(newDict, forKey: Constant.allowedWorldSensingSitesKey())
                    }
                    authorizationGranted(.worldSensing)
                } else if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) {
                    authorizationGranted(.minimal)
                } else {
                    authorizationGranted(.denied)
                }
            case .videoCameraAccess:
                if standardUserDefaults.bool(forKey: Constant.videoCameraAccessWebXREnabled()) {
                    guard let videoControl = self.tableViewController.tableView.cellForRow(at: IndexPath(row: 5, section: 0)) as? SegmentedControlTableViewCell else { return }
                    if videoControl.segmentedControl.selectedSegmentIndex == 1 {
                        var newDict = [AnyHashable : Any]()
                        if let dict = allowedVideoCameraSites {
                            newDict = dict
                        }
                        newDict[site] = "YES"
                        UserDefaults.standard.set(newDict, forKey: Constant.allowedVideoCameraSitesKey())
                    }
                    authorizationGranted(.videoCameraAccess)
                } else if standardUserDefaults.bool(forKey: Constant.worldSensingWebXREnabled()) {
                    authorizationGranted(.worldSensing)
                } else if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) {
                    authorizationGranted(.minimal)
                } else {
                    authorizationGranted(.denied)
                }
            default:
                authorizationGranted(.denied)
            }
        })
        alertController.addAction(confirmAction)
        
        var height = CGFloat()
        let rowHeight: CGFloat = 44
        switch webXRAuthorizationRequested {
        case .minimal:
            height = rowHeight * 1
        case .lite:
            height = rowHeight * 2
        case .worldSensing:
            height = rowHeight * 4
        case .videoCameraAccess:
            height = rowHeight * 6
        default:
            height = rowHeight * 1
        }
        tableViewController = UITableViewController()
        tableViewController.preferredContentSize = CGSize(width: 272, height: height)
        tableViewController.tableView.isScrollEnabled = false
        tableViewController.tableView.delegate = self
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.register(UINib(nibName: "SwitchInputTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "SwitchInputTableViewCell")
        tableViewController.tableView.register(UINib(nibName: "SegmentedControlTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "SegmentedControlTableViewCell")
        alertController.setValue(tableViewController, forKey: "contentViewController")
        
        viewController?.present(alertController, animated: true)
    }
    
    @objc func switchValueDidChange(sender: UISwitch) {
        let liteCell = tableViewController.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SwitchInputTableViewCell
        let worldSensingCell = tableViewController.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SwitchInputTableViewCell
        let videoCameraAccessCell = tableViewController.tableView.cellForRow(at: IndexPath(row: 4, section: 0)) as? SwitchInputTableViewCell
        let worldControl = tableViewController.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SegmentedControlTableViewCell
        let videoControl = tableViewController.tableView.cellForRow(at: IndexPath(row: 5, section: 0)) as? SegmentedControlTableViewCell
        
        switch sender.tag {
        case 0:
            UserDefaults.standard.set(sender.isOn, forKey: Constant.minimalWebXREnabled())
            if sender.isOn {
                liteCell?.switchControl.isEnabled = true
                worldSensingCell?.switchControl.isEnabled = true
            } else {
                UserDefaults.standard.set(false, forKey: Constant.liteModeWebXREnabled())
                UserDefaults.standard.set(false, forKey: Constant.worldSensingWebXREnabled())
                UserDefaults.standard.set(false, forKey: Constant.videoCameraAccessWebXREnabled())
                liteCell?.switchControl.setOn(false, animated: true)
                liteCell?.switchControl.isEnabled = false
                worldSensingCell?.switchControl.setOn(false, animated: true)
                worldSensingCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            }
        case 1:
            UserDefaults.standard.set(sender.isOn, forKey: Constant.liteModeWebXREnabled())
            if sender.isOn {
                UserDefaults.standard.set(false, forKey: Constant.worldSensingWebXREnabled())
                UserDefaults.standard.set(false, forKey: Constant.videoCameraAccessWebXREnabled())
                worldSensingCell?.switchControl.setOn(false, animated: true)
                worldSensingCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            } else {
                worldSensingCell?.switchControl.isEnabled = true
            }
        case 2:
            UserDefaults.standard.set(sender.isOn, forKey: Constant.worldSensingWebXREnabled())
            if sender.isOn {
                videoCameraAccessCell?.switchControl.isEnabled = true
                worldControl?.segmentedControl.isEnabled = true
            } else {
                UserDefaults.standard.set(false, forKey: Constant.videoCameraAccessWebXREnabled())
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            }
        case 4:
            UserDefaults.standard.set(sender.isOn, forKey: Constant.videoCameraAccessWebXREnabled())
            if sender.isOn {
                videoControl?.segmentedControl.isEnabled = true
            } else {
                videoControl?.segmentedControl.isEnabled = false
            }
        default:
            print("Unknown switch control toggled")
        }
    }
    
    // MARK: Alert Controller TableView Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch webXRAuthorizationRequested {
        case .minimal:
            return 1
        case .lite:
            return 2
        case .worldSensing:
            return 4
        case .videoCameraAccess:
            return 6
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 3
            || indexPath.row == 5
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlTableViewCell", for: indexPath) as! SegmentedControlTableViewCell
            cell.segmentedControl.tag = indexPath.row
            if indexPath.row == 3 {
                if !UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled()) {
                    cell.segmentedControl.isEnabled = false
                }
            } else {
                if !UserDefaults.standard.bool(forKey: Constant.videoCameraAccessWebXREnabled()) {
                    cell.segmentedControl.isEnabled = false
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
            cell.switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .touchUpInside)
            cell.switchControl.tag = indexPath.row
            switch indexPath.row {
            case 0:
                cell.labelTitle.text = "WebXR"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
            case 1:
                cell.labelTitle.text = "Lite Mode"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled()) {
                    cell.switchControl.isEnabled = false
                }
            case 2:
                cell.labelTitle.text = "World Sensing"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                {
                    cell.switchControl.isEnabled = false
                }
            case 4:
                cell.labelTitle.text = "Video Camera Access"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.videoCameraAccessWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                    || !UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                {
                    cell.switchControl.isEnabled = false
                }
            default:
                print("Cell not registered for permissions alert indexPath: \(indexPath)")
            }
            return cell
        }
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
        DefaultButton.appearance().titleColor = UIColor.blue
        DefaultButton.appearance().buttonColor = UIColor.clear
        DefaultButton.appearance().separatorColor = UIColor(white: 0.8, alpha: 1)

        CancelButton.appearance().titleColor = UIColor.gray
        CancelButton.appearance().titleFont = largeFont
        
        DestructiveButton.appearance().titleColor = UIColor.red
        DestructiveButton.appearance().titleFont = largeFont
    }
}
