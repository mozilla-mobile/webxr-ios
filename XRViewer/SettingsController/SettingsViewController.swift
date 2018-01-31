//
//  SettingsViewController.swift
//  XRViewer
//
//  Created by Roberto Garrido on 29/1/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    let privacyNoticeURL = "https://github.com/mozilla-mobile/webxr-ios/blob/master/PrivacyNotice.md"
    let termsOfServiceURL = "https://github.com/mozilla-mobile/webxr-ios/blob/master/TermsOfService.md"
    let viewControllerTitle = "XRViewer"
    let termsAndConditionsHeaderTitle = "TERMS AND CONDITIONS"
    let generalHeaderTitle = "GENERAL"
    let manageAppPermissionsHeaderTitle = "MANAGE APP PERMISSIONS"
    let manageAppPermissionsFooterTitle = "This will make the current AR Session to be restarted when you come back"
    let footerHeight = CGFloat(55.0)
    let headerHeight = CGFloat(55.0)
    let privacyNoticeLabelText = "Privacy Notice"
    let termsOfServiceLabelText = "Terms of Service"
    
    var tableView: UITableView!
    var onDoneButtonTapped: (() -> Void)?

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
            return 2
        } else if section == 1 {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let termsAndConditionsCell = tableView.dequeueReusableCell(withIdentifier: "TermsAndConditionsTableViewCell", for: indexPath) as! TermsAndConditionsTableViewCell
                termsAndConditionsCell.labelTermsAndConditions.text = privacyNoticeLabelText
                cell = termsAndConditionsCell
            case 1:
                let termsAndConditionsCell = tableView.dequeueReusableCell(withIdentifier: "TermsAndConditionsTableViewCell", for: indexPath) as! TermsAndConditionsTableViewCell
                termsAndConditionsCell.labelTermsAndConditions.text = termsOfServiceLabelText
                cell = termsAndConditionsCell
            default:
                fatalError("Cell not registered for indexPath: \(indexPath)")
            }
        case 1:
            switch indexPath.row {
            case 0:
                let textInputCell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! TextInputTableViewCell
                textInputCell.textField.text = UserDefaults.standard.string(forKey: homeURLKey)
                textInputCell.textField.delegate = self
                cell = textInputCell
            case 1:
                let switchInputCell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                switchInputCell.switchControl.isOn = UserDefaults.standard.bool(forKey: useAnalyticsKey)
                switchInputCell.switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
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
        UserDefaults.standard.set(switchControl.isOn, forKey: useAnalyticsKey)
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            UserDefaults.standard.set(text, forKey: homeURLKey)
            textField.resignFirstResponder()
        }
        return true
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                UIApplication.shared.open(URL(string: privacyNoticeURL)!,
                                          options: [:],
                                          completionHandler: nil)
            } else {
                UIApplication.shared.open(URL(string: termsOfServiceURL)!,
                                          options: [:],
                                          completionHandler: nil)
            }
        } else if indexPath.section == 2 {
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
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
