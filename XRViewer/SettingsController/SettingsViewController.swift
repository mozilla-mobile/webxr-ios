//
//  SettingsViewController.swift
//  XRViewer
//
//  Created by Roberto Garrido on 29/1/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit

/// A view controller to handle the settings of the app
class SettingsViewController: UIViewController {
    let privacyNoticeURL = "https://github.com/mozilla-mobile/webxr-ios/blob/master/PrivacyNotice.md"
    let viewControllerTitle = "XRViewer"
    let termsAndConditionsHeaderTitle = "TERMS AND CONDITIONS"
    let generalHeaderTitle = "GENERAL"
    let manageAppPermissionsHeaderTitle = "MANAGE APP PERMISSIONS"
    let manageAppPermissionsFooterTitle = "Opening iOS Settings may cause the current AR Session to be restarted when you come back"
    let footerHeight = CGFloat(55.0)
    let headerHeight = CGFloat(55.0)
    let privacyNoticeLabelText = "Privacy Notice"
    
    var tableView: UITableView!
    @objc var onDoneButtonTapped: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = viewControllerTitle
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func loadView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UINib(nibName: "TextInputTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "TextInputTableViewCell")
        tableView.register(UINib(nibName: "SwitchInputTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "SwitchInputTableViewCell")
        tableView.register(UINib(nibName: "TextTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "TextTableViewCell")
        tableView.register(UINib(nibName: "TermsAndConditionsTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "TermsAndConditionsTableViewCell")
        
        view = tableView
        
        let barButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonTapped))
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    @objc func doneButtonTapped() {
        onDoneButtonTapped?()
    }
}

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 7
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        switch indexPath.section {
        case 0:
            let termsAndConditionsCell = tableView.dequeueReusableCell(withIdentifier: "TermsAndConditionsTableViewCell", for: indexPath) as! TermsAndConditionsTableViewCell
            termsAndConditionsCell.labelTermsAndConditions.text = privacyNoticeLabelText
            cell = termsAndConditionsCell
            break
        case 1:
            switch indexPath.row {
            case 0:
                let textInputCell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! TextInputTableViewCell
                textInputCell.labelTitle?.text = "Home URL"
                textInputCell.textField.text = UserDefaults.standard.string(forKey: Constant.homeURLKey())
                textInputCell.textField.delegate = self
                textInputCell.textField.keyboardType = .URL
                textInputCell.textField.tag = 1
                cell = textInputCell
            case 1:
                let switchInputCell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                switchInputCell.labelTitle?.text = "Send Tech and Interaction Data"
                switchInputCell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.useAnalyticsKey())
                switchInputCell.switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
                switchInputCell.switchControl.tag = 1
                cell = switchInputCell
            case 2:
                let textInputCell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! TextInputTableViewCell
                textInputCell.labelTitle?.text = "ARKit shutdown delay:"
                textInputCell.textField.text = UserDefaults.standard.string(forKey: Constant.secondsInBackgroundKey())
                textInputCell.textField.keyboardType = .numberPad
                textInputCell.textField.delegate = self
                textInputCell.textField.tag = 2
                cell = textInputCell
            case 3:
                let textInputCell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! TextInputTableViewCell
                textInputCell.labelTitle?.text = "Anchor retention threshold (meters):"
                textInputCell.textField.text = UserDefaults.standard.string(forKey: Constant.distantAnchorsDistanceKey())
                textInputCell.textField.keyboardType = .numberPad
                textInputCell.textField.delegate = self
                textInputCell.textField.tag = 3
                cell = textInputCell
            case 4:
                let switchInputCell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                switchInputCell.labelTitle?.text = "Always Allow World Sensing"
                switchInputCell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.alwaysAllowWorldSensingKey())
                switchInputCell.switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
                switchInputCell.switchControl.tag = 4
                cell = switchInputCell
            case 5:
                let switchInputCell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                switchInputCell.labelTitle?.text = "Forget WebXR Permissions for All Sites"
                switchInputCell.switchControl.isOn = false
                switchInputCell.switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
                switchInputCell.switchControl.tag = 5
                cell = switchInputCell
            case 6:
                let switchInputCell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                switchInputCell.labelTitle?.text = "Expose WebXR API (restart required)"
                switchInputCell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.exposeWebXRAPIKey());
                switchInputCell.switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
                switchInputCell.switchControl.tag = 6
                cell = switchInputCell
            default:
                fatalError("Cell not registered for indexPath: \(indexPath)")
            }
        case 2:
            switch indexPath.row {
            case 0:
                let textCell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell", for: indexPath) as! TextTableViewCell
                cell = textCell
                break
            default:
                fatalError("Cell not registered for indexPath: \(indexPath)")
            }
        default:
            fatalError("Cell not registered for indexPath: \(indexPath)")
        }
        
        return cell
    }
    
    @objc func switchValueChanged(switchControl: UISwitch) {
        if switchControl.tag == 1 {
            UserDefaults.standard.set(switchControl.isOn, forKey: Constant.useAnalyticsKey())
        } else if switchControl.tag == 4 {
            UserDefaults.standard.set(switchControl.isOn, forKey: Constant.alwaysAllowWorldSensingKey())
        } else if switchControl.tag == 5 {
            // Forget any sites remembered
            UserDefaults.standard.removeObject(forKey: Constant.allowedWorldSensingSitesKey())
            UserDefaults.standard.removeObject(forKey: Constant.allowedVideoCameraSitesKey())
            // Assume that if they are resetting, World Sensing should NOT be always-on.
            UserDefaults.standard.set(false, forKey: Constant.alwaysAllowWorldSensingKey())
            let alwaysAllowSwitch = tableView.cellForRow(at: IndexPath(row: 4, section: 1)) as? SwitchInputTableViewCell
            alwaysAllowSwitch?.switchControl.setOn(false, animated: true)
        } else if switchControl.tag == 6 {
            UserDefaults.standard.set(switchControl.isOn, forKey: Constant.exposeWebXRAPIKey())
        }
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, textField.tag == 1 {
            UserDefaults.standard.set(text, forKey: Constant.homeURLKey())
        } else if let text = textField.text, textField.tag == 2 {
            UserDefaults.standard.set(text, forKey: Constant.secondsInBackgroundKey())
        } else if let text = textField.text, textField.tag == 3 {
            UserDefaults.standard.set(text, forKey: Constant.distantAnchorsDistanceKey())
        }
        textField.resignFirstResponder()
        return true
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            UIApplication.shared.open(URL(string: privacyNoticeURL)!,
                                      options: [:],
                                      completionHandler: nil)
        } else if indexPath.section == 2 {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return termsAndConditionsHeaderTitle
        } else if section == 1 {
            return generalHeaderTitle
        } else {
            return manageAppPermissionsHeaderTitle
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 || section == 1 {
            return nil
        } else {
            return manageAppPermissionsFooterTitle
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 || section == 1 {
            return 0.0
        } else {
            return footerHeight
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }
}
