import FontAwesomeKit
import UIKit
import CocoaLumberjack

let URL_FIELD_HEIGHT = 29

class BarView: UIView, UITextFieldDelegate {
    
    // MARK: - Properties & Outlets
    
    @objc var backActionBlock: ((Any?) -> Void)?
    @objc var forwardActionBlock: ((Any?) -> Void)?
    @objc var homeActionBlock: ((Any?) -> Void)?
    @objc var reloadActionBlock: ((Any?) -> Void)?
    @objc var cancelActionBlock: ((Any?) -> Void)?
    @objc var showPermissionsActionBlock: ((Any?) -> Void)?
    @objc var goActionBlock: ((String?) -> Void)?
    @objc var debugButtonToggledAction: ((Bool) -> Void)?
    @objc var settingsActionBlock: (() -> Void)?
    @objc var restartTrackingActionBlock: (() -> Void)?
    @objc var switchCameraActionBlock: (() -> Void)?

    @IBOutlet weak var urlField: URLTextField!
    @IBOutlet private weak var backBtn: UIButton!
    @IBOutlet private weak var forwardBtn: UIButton!
    @IBOutlet private weak var homeBtn: UIButton!
    @IBOutlet private weak var debugBtn: UIButton!
    @IBOutlet private weak var settingsBtn: UIButton!
    private weak var reloadBtn: UIButton?
    private weak var cancelBtn: UIButton?
    weak var permissionLevelButton: ActivityIndicatorButton?
    @IBOutlet private weak var restartTrackingBtn: UIButton!
    @IBOutlet private weak var switchCameraBtn: UIButton!

    // MARK: - View Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }

    func setup() {
        backBtn.setImage(UIImage(named: "back"), for: .disabled)
        forwardBtn.setImage(UIImage(named: "forward"), for: .disabled)
        backBtn.isEnabled = false
        forwardBtn.isEnabled = false

        urlField.delegate = self

        let permissionButton = ActivityIndicatorButton(type: .custom)
        permissionButton.setImage(nil, for: .normal)
        permissionButton.addTarget(self, action: #selector(BarView.showPermissionsAction(_:)), for: .touchUpInside)
        permissionButton.frame = CGRect(x: 0, y: 0, width: CGFloat(URL_FIELD_HEIGHT), height: CGFloat(URL_FIELD_HEIGHT))
        permissionButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        permissionButton.isEnabled = false
        urlField.leftView = permissionButton
        urlField.leftViewMode = .unlessEditing
        permissionLevelButton = permissionButton

        urlField.clearButtonMode = .whileEditing
        urlField.returnKeyType = .go

        urlField.textContentType = .URL
        urlField.placeholder = "Search or enter website name"
        urlField.layer.cornerRadius = CGFloat(URL_FIELD_HEIGHT / 4)
        urlField.textAlignment = .center

        let reloadButton = UIButton(type: .custom)
        reloadButton.setImage(UIImage(named: "reload"), for: .normal)
        reloadButton.addTarget(self, action: #selector(BarView.reloadAction(_:)), for: .touchUpInside)
        reloadButton.frame = CGRect(x: 0, y: 0, width: CGFloat(URL_FIELD_HEIGHT), height: CGFloat(URL_FIELD_HEIGHT))
        reloadButton.isHidden = false

        let cancelButton = UIButton(type: .custom)
        cancelButton.setImage(UIImage(named: "cancel"), for: .normal)
        cancelButton.addTarget(self, action: #selector(BarView.cancelAction(_:)), for: .touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: CGFloat(URL_FIELD_HEIGHT), height: CGFloat(URL_FIELD_HEIGHT))
        cancelButton.isHidden = true

        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat(URL_FIELD_HEIGHT), height: CGFloat(URL_FIELD_HEIGHT)))
        rightView.addSubview(reloadButton)
        rightView.addSubview(cancelButton)
        self.cancelBtn = cancelButton
        self.reloadBtn = reloadButton

        urlField.rightView = rightView
        urlField.rightViewMode = .unlessEditing

        debugBtn.setImage(UIImage(named: "debugOff"), for: .normal)
        debugBtn.setImage(UIImage(named: "debugOn"), for: .selected)

        var error: Error?
        let streetViewIcon = try? FAKFontAwesome.init(identifier: "fa-street-view", size: 24)
        if error != nil {
            print("\(error?.localizedDescription ?? "")")
        } else {
            let streetViewImage: UIImage? = streetViewIcon?.image(with: CGSize(width: 24, height: 24))
            restartTrackingBtn.setImage(streetViewImage, for: .normal)
            restartTrackingBtn.tintColor = UIColor.gray
        }
    }

    // MARK: - Helpers
    
    @objc func urlFieldText() -> String? {
        return urlField.text
    }
    
    // MARK: - Actions
    
    @objc func startLoading(_ url: String?) {
        permissionLevelButton?.startAnimating()
        cancelBtn?.isHidden = false
        reloadBtn?.isHidden = true
        urlField.text = url
    }
    
    @objc func finishLoading(_ url: String?) {
        permissionLevelButton?.stopAnimating()
        cancelBtn?.isHidden = true
        reloadBtn?.isHidden = false
    }
    
    @objc func setBackEnabled(_ enabled: Bool) {
        backBtn.isEnabled = enabled
    }
    
    @objc func setForwardEnabled(_ enabled: Bool) {
        forwardBtn.isEnabled = enabled
    }
    
    func setDebugSelected(_ selected: Bool) {
        debugBtn.isSelected = selected
    }
    
    @objc func setDebugVisible(_ visible: Bool) {
        debugBtn.isHidden = !visible
    }
    
    @objc func setRestartTrackingVisible(_ visible: Bool) {
        restartTrackingBtn.isHidden = !visible
    }
    
    @objc func hideKeyboard() {
        urlField.resignFirstResponder()
    }
    
    @objc func isDebugButtonSelected() -> Bool {
        return debugBtn.isSelected
    }
    
    @objc func hideCameraFlipButton() {
        switchCameraBtn.removeFromSuperview()
    }
    
    // MARK: - Button Actions
    
    @IBAction func backAction(_ sender: Any) {
        DDLogDebug("backAction")
        urlField.resignFirstResponder()
        backActionBlock?(sender)
    }

    @IBAction func forwardAction(_ sender: Any) {
        DDLogDebug("forwardAction")
        urlField.resignFirstResponder()
        forwardActionBlock?(sender)
    }

    @IBAction func homeAction(_ sender: Any) {
        DDLogDebug("homeAction")
        homeActionBlock?(sender)
    }

    @IBAction func reloadAction(_ sender: Any) {
        DDLogDebug("reloadAction")
        urlField.resignFirstResponder()
        reloadActionBlock?(sender)
    }

    @IBAction func cancelAction(_ sender: Any) {
        DDLogDebug("cancelAction")
        urlField.resignFirstResponder()
        cancelActionBlock?(sender)
    }
    
    @IBAction func showPermissionsAction(_ sender: Any) {
        DDLogDebug("showPermissionsAction")
        urlField.resignFirstResponder()
        showPermissionsActionBlock?(sender)
    }

    @IBAction func debugAction(_ sender: Any) {
        debugBtn.isSelected = !debugBtn.isSelected
        debugButtonToggledAction?(debugBtn.isSelected)
    }

    @IBAction func settingsAction() {
        settingsActionBlock?()
    }

    @IBAction func restartTrackingAction(_ sender: Any) {
        restartTrackingActionBlock?()
    }

    @IBAction func switchCameraAction(_ sender: Any) {
        switchCameraActionBlock?()
    }

    // MARK: - UITextField Delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        goActionBlock?(textField.text)
        return true
    }

    // MARK: - UIView

    // This function increases the hitboxes of the forwardBtn/backBtn
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let minXPos = backBtn.frame.maxX
        let maxXPos = forwardBtn.frame.minX

        let increaseValue: CGFloat = (maxXPos - minXPos) / 2

        let icreasedBackRect = CGRect(x: backBtn.frame.origin.x - increaseValue, y: backBtn.frame.origin.y - increaseValue, width: backBtn.frame.size.width + increaseValue * 2, height: backBtn.frame.size.height + increaseValue * 2)

        let icreasedForwardRect = CGRect(x: forwardBtn.frame.origin.x - increaseValue, y: forwardBtn.frame.origin.y - increaseValue, width: forwardBtn.frame.size.width + increaseValue * 2, height: forwardBtn.frame.size.height + increaseValue * 2)

        if icreasedBackRect.contains(point) {
            return backBtn
        }

        if icreasedForwardRect.contains(point) {
            return forwardBtn
        }

        return super.hitTest(point, with: event)
    }
}

class URLTextField: UITextField {
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: 0, width: CGFloat(URL_FIELD_HEIGHT), height: CGFloat(URL_FIELD_HEIGHT))
    }
}
