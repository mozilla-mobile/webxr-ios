//
//  SettingsViewController.swift
//  XRViewer
//
//  Created by Roberto Garrido on 29/1/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    var tableView: UITableView!

    var onDoneButtonTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "XRViewer"
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func loadView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UINib(nibName: "TextInputTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "TextInputTableViewCell")
        tableView.register(UINib(nibName: "SwitchInputTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "SwitchInputTableViewCell")
        tableView.register(UINib(nibName: "TextTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "TextTableViewCell")
        
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let textInputCell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! TextInputTableViewCell
                cell = textInputCell
            case 1:
                let switchInputCell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                cell = switchInputCell
            default:
                fatalError("Cell not registered for indexPath: \(indexPath)")
            }
        case 1:
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
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "GENERAL" : "MANAGE APP PERMISSIONS"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? nil : "This will make the current AR Session to be restarted when you come back"
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0 : 55.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55.0
    }
}
