import UIKit
import XCGLogger

let URL_FIELD_HEIGHT = 29

class BarView: UIView, UITextFieldDelegate {
    
    // MARK: - Properties & Outlets
    
    var backActionBlock: ((Any?) -> Void)?
    var forwardActionBlock: ((Any?) -> Void)?
    var homeActionBlock: ((Any?) -> Void)?
    var reloadActionBlock: ((Any?) -> Void)?
    var cancelActionBlock: ((Any?) -> Void)?
    var showPermissionsActionBlock: ((Any?) -> Void)?
    var goActionBlock: ((String?) -> Void)?
    var debugButtonToggledAction: ((Bool) -> Void)?
    var settingsActionBlock: (() -> Void)?
    var restartTrackingActionBlock: (() -> Void)?
    var switchCameraActionBlock: (() -> Void)?

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
        permissionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        permissionButton.isEnabled = false
        permissionLevelButton = permissionButton
        permissionLevelButton?.heightAnchor.constraint(equalToConstant: CGFloat(URL_FIELD_HEIGHT)).isActive = true
        permissionLevelButton?.widthAnchor.constraint(equalToConstant: CGFloat(URL_FIELD_HEIGHT)).isActive = true
        permissionLevelButton?.imageView?.contentMode = .scaleAspectFit
        urlField.leftView = permissionLevelButton
        urlField.leftViewMode = .unlessEditing

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

        restartTrackingBtn.setImage(UIImage(named: "streetview"), for: .normal)
        restartTrackingBtn.tintColor = UIColor.gray
    }

    // MARK: - Helpers
    
    func urlFieldText() -> String? {
        return urlField.text
    }
    
    // MARK: - Actions
    
    func startLoading(_ url: String?) {
        permissionLevelButton?.startAnimating()
        cancelBtn?.isHidden = false
        reloadBtn?.isHidden = true
        urlField.text = url
    }
    
    func finishLoading(_ url: String?) {
        permissionLevelButton?.stopAnimating()
        cancelBtn?.isHidden = true
        reloadBtn?.isHidden = false
    }
    
    func setBackEnabled(_ enabled: Bool) {
        backBtn.isEnabled = enabled
    }
    
    func setForwardEnabled(_ enabled: Bool) {
        forwardBtn.isEnabled = enabled
    }
    
    func setDebugSelected(_ selected: Bool) {
        debugBtn.isSelected = selected
    }
    
    func setDebugVisible(_ visible: Bool) {
        debugBtn.isHidden = !visible
    }
    
    func setRestartTrackingVisible(_ visible: Bool) {
        restartTrackingBtn.isHidden = !visible
    }
    
    func hideKeyboard() {
        urlField.resignFirstResponder()
    }
    
    func isDebugButtonSelected() -> Bool {
        return debugBtn.isSelected
    }
    
    func hideCameraFlipButton() {
        switchCameraBtn.removeFromSuperview()
    }
    
    // MARK: - Button Actions
    
    @IBAction func backAction(_ sender: Any) {
        appDelegate().logger.debug("backAction")
        urlField.resignFirstResponder()
        backActionBlock?(sender)
    }

    @IBAction func forwardAction(_ sender: Any) {
        appDelegate().logger.debug("forwardAction")
        urlField.resignFirstResponder()
        forwardActionBlock?(sender)
    }

    @IBAction func homeAction(_ sender: Any) {
        appDelegate().logger.debug("homeAction")
        homeActionBlock?(sender)
    }

    @IBAction func reloadAction(_ sender: Any) {
        appDelegate().logger.debug("reloadAction")
        urlField.resignFirstResponder()
        reloadActionBlock?(sender)
    }

    @IBAction func cancelAction(_ sender: Any) {
        appDelegate().logger.debug("cancelAction")
        urlField.resignFirstResponder()
        cancelActionBlock?(sender)
    }
    
    @IBAction func showPermissionsAction(_ sender: Any) {
        appDelegate().logger.debug("showPermissionsAction")
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
