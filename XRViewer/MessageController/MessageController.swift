import UIKit
import PopupDialog
import CocoaLumberjack

class MessageController: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    @objc var didShowMessage: (() -> Void)?
    @objc var didHideMessage: (() -> Void)?
    @objc var didHideMessageByUser: (() -> Void)?
    private weak var viewController: UIViewController?
    private weak var arPopup: PopupDialog?
    private var tableViewController = UITableViewController()
    private var webXRAuthorizationRequested: WebXRAuthorizationState = .notDetermined
    private var site: String?
    private var permissionsPopup: UIAlertController?
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
            arPopup = nil
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
        weak var blockSelf: MessageController? = self
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

                blockSelf?.didHideMessageByUser?()
            })

        let ok = DefaultButton(title: "Reload", height: 40, dismissOnTap: true, action: {
                reloadCompletion(true)

                blockSelf?.didHideMessageByUser?()
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

            arPopup = popup
            viewController?.present(popup, animated: true)
            didShowMessage?()
        } else if !interrupt && arPopup != nil {
            arPopup?.dismiss(animated: true)
            arPopup = nil
            didHideMessage?()
        }
    }

    @objc func showMessageAboutFailSession(withMessage message: String?, completion: @escaping () -> Void) {
        weak var blockSelf: MessageController? = self
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
                blockSelf?.didHideMessageByUser?()
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
        weak var blockSelf: MessageController? = self
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
            
                blockSelf?.didHideMessageByUser?()
            })

        popup.addButtons([ok])
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    @objc func showMessageAboutConnectionRequired() {
        weak var blockSelf: MessageController? = self
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

                blockSelf?.didHideMessageByUser?()
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
        let permissionsViewController = RequestPermissionsViewController()
        permissionsViewController.view.translatesAutoresizingMaskIntoConstraints = true
        permissionsViewController.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true

        let dialog = PopupDialog(
            viewController: permissionsViewController,
            buttonAlignment: NSLayoutConstraint.Axis.vertical,
            transitionStyle: .bounceUp,
            preferredWidth: UIScreen.main.bounds.size.width / 2.0,
            tapGestureDismissal: false,
            panGestureDismissal: false,
            hideStatusBar: true
        )

        viewController?.present(dialog, animated: true)
    }
    
    @objc func showMessageAboutEnteringXR(_ authorizationRequested: WebXRAuthorizationState, authorizationGranted: @escaping (WebXRAuthorizationState) -> Void, url: URL) {
        weak var blockSelf: MessageController? = self
        let standardUserDefaults = UserDefaults.standard
        let allowedMinimalSites = standardUserDefaults.dictionary(forKey: Constant.allowedMinimalSitesKey())
        let allowedWorldSensingSites = standardUserDefaults.dictionary(forKey: Constant.allowedWorldSensingSitesKey())
        let allowedVideoCameraSites = standardUserDefaults.dictionary(forKey: Constant.allowedVideoCameraSitesKey())
        guard var currentSite: String = url.host else { return }
        webXRAuthorizationRequested = authorizationRequested
        
        if let port = url.port {
            currentSite = currentSite + ":\(port)"
        }
        site = currentSite
        
        switch authorizationRequested {
        case .minimal:
            if allowedMinimalSites?[currentSite] != nil {
                standardUserDefaults.set(true, forKey: Constant.minimalWebXREnabled())
            }
        case .worldSensing:
            if allowedWorldSensingSites?[currentSite] != nil {
                standardUserDefaults.set(true, forKey: Constant.minimalWebXREnabled())
                standardUserDefaults.set(true, forKey: Constant.worldSensingWebXREnabled())
            }
        case .videoCameraAccess:
            if allowedVideoCameraSites?[currentSite] != nil {
                standardUserDefaults.set(true, forKey: Constant.minimalWebXREnabled())
                standardUserDefaults.set(true, forKey: Constant.worldSensingWebXREnabled())
                standardUserDefaults.set(true, forKey: Constant.videoCameraAccessWebXREnabled())
            }
        default:
            break
        }
        
        if !forceShowPermissionsPopup {
            // Check whether Lite Mode is enabled
            if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled())
                && (authorizationRequested == .minimal
                    || authorizationRequested == .lite
                    || authorizationRequested == .worldSensing
                    || authorizationRequested == .videoCameraAccess)
            {
                authorizationGranted(.lite)
                return
            }
            
            switch authorizationRequested {
            case .minimal:
                if allowedMinimalSites?[currentSite] != nil {
                    authorizationGranted(.minimal)
                    return
                }
            case .worldSensing:
                if standardUserDefaults.bool(forKey: Constant.alwaysAllowWorldSensingKey())
                    || allowedWorldSensingSites?[currentSite] != nil
                {
                    authorizationGranted(.worldSensing)
                    return
                }
            case .videoCameraAccess:
                if allowedVideoCameraSites?[currentSite] != nil {
                    authorizationGranted(.videoCameraAccess)
                    return
                }
            default:
                break
            }
        }
        
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
        let negativeAction: UIAlertAction
        if forceShowPermissionsPopup {
            negativeAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        } else {
            negativeAction = UIAlertAction(title: "Deny", style: .cancel) { _ in
                authorizationGranted(.denied)
            }
        }
        alertController.addAction(negativeAction)
        forceShowPermissionsPopup = false
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            if let minimalCell = blockSelf?.tableViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SwitchInputTableViewCell {
                standardUserDefaults.set(minimalCell.switchControl.isOn, forKey: Constant.minimalWebXREnabled())
            }
            if let liteCell = blockSelf?.tableViewController.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SwitchInputTableViewCell {
                standardUserDefaults.set(liteCell.switchControl.isOn, forKey: Constant.liteModeWebXREnabled())
            }
            if let worldSensingCell = blockSelf?.tableViewController.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SwitchInputTableViewCell {
                standardUserDefaults.set(worldSensingCell.switchControl.isOn, forKey: Constant.worldSensingWebXREnabled())
            }
            if let videoCameraAccessCell = blockSelf?.tableViewController.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SwitchInputTableViewCell {
                standardUserDefaults.set(videoCameraAccessCell.switchControl.isOn, forKey: Constant.videoCameraAccessWebXREnabled())
            }
            
            switch blockSelf?.webXRAuthorizationRequested {
            case .minimal?:
                if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) {
                    guard let minimalControl = blockSelf?.tableViewController.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SegmentedControlTableViewCell else { return }
                    
                    var newDict = [AnyHashable : Any]()
                    if let dict = allowedMinimalSites {
                        newDict = dict
                    }
                    if minimalControl.segmentedControl.selectedSegmentIndex == 1 {
                        newDict[currentSite] = "YES"
                    } else {
                        newDict[currentSite] = nil
                    }
                    UserDefaults.standard.set(newDict, forKey: Constant.allowedMinimalSitesKey())
                    authorizationGranted(.minimal)
                } else {
                    authorizationGranted(.denied)
                }
            case .lite?:
                authorizationGranted(standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) ? .lite : .denied)
            case .worldSensing?:
                if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.worldSensingWebXREnabled()) {
                    guard let worldControl = blockSelf?.tableViewController.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SegmentedControlTableViewCell else { return }
                    
                    var newDict = [AnyHashable : Any]()
                    if let dict = allowedWorldSensingSites {
                        newDict = dict
                    }
                    if worldControl.segmentedControl.selectedSegmentIndex == 1 {
                        newDict[currentSite] = "YES"
                    } else {
                        newDict[currentSite] = nil
                    }
                    UserDefaults.standard.set(newDict, forKey: Constant.allowedWorldSensingSitesKey())
                    authorizationGranted(.worldSensing)
                } else if standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) {
                    authorizationGranted(.minimal)
                } else {
                    authorizationGranted(.denied)
                }
            case .videoCameraAccess?:
                if standardUserDefaults.bool(forKey: Constant.videoCameraAccessWebXREnabled()) {
                    guard let videoControl = blockSelf?.tableViewController.tableView.cellForRow(at: IndexPath(row: 4, section: 0)) as? SegmentedControlTableViewCell else { return }
                    
                    var newDict = [AnyHashable : Any]()
                    if let dict = allowedVideoCameraSites {
                        newDict = dict
                    }
                    if videoControl.segmentedControl.selectedSegmentIndex == 1 {
                        newDict[currentSite] = "YES"
                    } else {
                        newDict[currentSite] = nil
                    }
                    UserDefaults.standard.set(newDict, forKey: Constant.allowedVideoCameraSitesKey())
                    authorizationGranted(.videoCameraAccess)
                } else if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.worldSensingWebXREnabled()) {
                    authorizationGranted(.worldSensing)
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
            height = rowHeight * 3
        case .lite:
            height = rowHeight * 3
        case .worldSensing:
            height = rowHeight * 4
        case .videoCameraAccess:
            height = rowHeight * 5
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
        
        permissionsPopup = alertController
        viewController?.present(alertController, animated: true)
    }
    
    @objc func switchValueDidChange(sender: UISwitch) {
        let liteCell = tableViewController.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SwitchInputTableViewCell
        let worldSensingCell = tableViewController.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SwitchInputTableViewCell
        let videoCameraAccessCell = tableViewController.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SwitchInputTableViewCell
        let minimalControl = tableViewController.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SegmentedControlTableViewCell
        let worldControl = tableViewController.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SegmentedControlTableViewCell
        let videoControl = tableViewController.tableView.cellForRow(at: IndexPath(row: 4, section: 0)) as? SegmentedControlTableViewCell
        
        switch sender.tag {
        case 0:
            if sender.isOn {
                liteCell?.switchControl.isEnabled = true
                liteCell?.labelTitle.isEnabled = true
                worldSensingCell?.switchControl.isEnabled = true
                worldSensingCell?.labelTitle.isEnabled = true
                minimalControl?.segmentedControl.isEnabled = true
            } else {
                liteCell?.switchControl.setOn(false, animated: true)
                liteCell?.switchControl.isEnabled = false
                liteCell?.labelTitle.isEnabled = false
                worldSensingCell?.switchControl.setOn(false, animated: true)
                worldSensingCell?.switchControl.isEnabled = false
                worldSensingCell?.labelTitle.isEnabled = false
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.labelTitle.isEnabled = false
                minimalControl?.segmentedControl.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            }
        case 1:
            if sender.isOn {
                worldSensingCell?.switchControl.setOn(true, animated: true)
                worldSensingCell?.switchControl.isEnabled = false
                worldSensingCell?.labelTitle.isEnabled = false
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.labelTitle.isEnabled = false
                minimalControl?.segmentedControl.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            } else {
                minimalControl?.segmentedControl.isEnabled = true
                worldSensingCell?.switchControl.isEnabled = true
                worldSensingCell?.labelTitle.isEnabled = true
                worldControl?.segmentedControl.isEnabled = true
                videoCameraAccessCell?.switchControl.isEnabled = true
                videoCameraAccessCell?.labelTitle.isEnabled = true
            }
        case 2:
            if sender.isOn {
                videoCameraAccessCell?.switchControl.isEnabled = true
                videoCameraAccessCell?.labelTitle.isEnabled = true
                worldControl?.segmentedControl.isEnabled = true
            } else {
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.labelTitle.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            }
        case 3:
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
            return 3
        case .lite:
            return 3
        case .worldSensing:
            return 4
        case .videoCameraAccess:
            return 5
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0, 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
            cell.switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .touchUpInside)
            cell.switchControl.tag = indexPath.row
            
            if indexPath.row == 0 {
                cell.labelTitle.text = "WebXR"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
            } else if indexPath.row == 1 {
                cell.labelTitle.text = "Lite Mode"
                cell.learnMoreButton.isHidden = false
                cell.learnMoreButton.addTarget(self, action: #selector(learnMoreLiteModeTapped), for: .touchUpInside)
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled()) {
                    cell.switchControl.isEnabled = false
                    cell.labelTitle.isEnabled = false
                }
            }
            return cell
        case 2:
            switch webXRAuthorizationRequested {
            case .minimal:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlTableViewCell", for: indexPath) as! SegmentedControlTableViewCell
                cell.segmentedControl.tag = indexPath.row
                
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                {
                    cell.segmentedControl.isEnabled = false
                }
                let allowedMinimalSites = UserDefaults.standard.dictionary(forKey: Constant.allowedMinimalSitesKey())
                if let site = site, allowedMinimalSites?[site] != nil {
                    cell.segmentedControl.selectedSegmentIndex = 1
                }
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                cell.switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .touchUpInside)
                cell.switchControl.tag = indexPath.row
                
                cell.labelTitle.text = "World Sensing"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                {
                    cell.switchControl.isEnabled = false
                    cell.labelTitle.isEnabled = false
                }
                return cell
            }
        case 3:
            switch webXRAuthorizationRequested {
            case .worldSensing:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlTableViewCell", for: indexPath) as! SegmentedControlTableViewCell
                cell.segmentedControl.tag = indexPath.row
                
                if !UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                {
                    cell.segmentedControl.isEnabled = false
                }
                let allowedWorldSensingSites = UserDefaults.standard.dictionary(forKey: Constant.allowedWorldSensingSitesKey())
                if let site = site, allowedWorldSensingSites?[site] != nil {
                    cell.segmentedControl.selectedSegmentIndex = 1
                }
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                cell.switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .touchUpInside)
                cell.switchControl.tag = indexPath.row
                
                cell.labelTitle.text = "Video Camera Access"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.videoCameraAccessWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                    || !UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                {
                    cell.switchControl.isEnabled = false
                    cell.labelTitle.isEnabled = false
                }
                return cell
            }
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlTableViewCell", for: indexPath) as! SegmentedControlTableViewCell
            cell.segmentedControl.tag = indexPath.row
            
            if !UserDefaults.standard.bool(forKey: Constant.videoCameraAccessWebXREnabled()) {
                cell.segmentedControl.isEnabled = false
            }
            let allowedVideoCameraSites = UserDefaults.standard.dictionary(forKey: Constant.allowedVideoCameraSitesKey())
            if let site = site, allowedVideoCameraSites?[site] != nil {
                cell.segmentedControl.selectedSegmentIndex = 1
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
    
    @objc func learnMoreLiteModeTapped() {
        let alert = UIAlertController(title: "What's Lite Mode?", message: "Lite Mode is privacy-focused and sends less information to WebXR sites. \n\nWhen Lite Mode is activated, only one plane from the real world is shared with WebXR sites. \nLite Mode enables face-based experiences, but it will not recognize images nor provide video camera access to WebXR sites.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        permissionsPopup?.present(alert, animated: true)
    }
}
