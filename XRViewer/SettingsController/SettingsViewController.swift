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
    let viewControllerTitle = "XRViewer"
    let termsAndConditionsHeaderTitle = "TERMS AND CONDITIONS"
    let generalHeaderTitle = "GENERAL"
    let manageAppPermissionsHeaderTitle = "MANAGE APP PERMISSIONS"
    let manageAppPermissionsFooterTitle = "Opening iOS Settings will cause the current AR Session to be restarted when you come back"
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
            return 4
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
                textInputCell.textField.text = UserDefaults.standard.string(forKey: homeURLKey)
                textInputCell.textField.delegate = self
                textInputCell.textField.keyboardType = .URL
                textInputCell.textField.tag = 1
                cell = textInputCell
            case 1:
                let switchInputCell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                switchInputCell.switchControl.isOn = UserDefaults.standard.bool(forKey: useAnalyticsKey)
                switchInputCell.switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
                cell = switchInputCell
            case 2:
                let textInputCell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! TextInputTableViewCell
                textInputCell.labelTitle?.text = "ARKit shutdown delay:"
                textInputCell.textField.text = UserDefaults.standard.string(forKey: secondsInBackgroundKey)
                textInputCell.textField.keyboardType = .numberPad
                textInputCell.textField.delegate = self
                textInputCell.textField.tag = 2
                cell = textInputCell
            case 3:
                let textInputCell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! TextInputTableViewCell
                textInputCell.labelTitle?.text = "Anchor retention threshold (meters):"
                textInputCell.textField.text = UserDefaults.standard.string(forKey: distantAnchorsDistanceKey)
                textInputCell.textField.keyboardType = .numberPad
                textInputCell.textField.delegate = self
                textInputCell.textField.tag = 3
                cell = textInputCell
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
        if let text = textField.text, textField.tag == 1 {
            UserDefaults.standard.set(text, forKey: homeURLKey)
        } else if let text = textField.text, textField.tag == 2 {
            UserDefaults.standard.set(text, forKey: secondsInBackgroundKey)
        } else if let text = textField.text, textField.tag == 3 {
            UserDefaults.standard.set(text, forKey: distantAnchorsDistanceKey)
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
