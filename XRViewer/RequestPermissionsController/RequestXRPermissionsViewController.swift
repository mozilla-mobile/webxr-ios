//
//  RequestXRPermissionsViewController.swift
//  XRViewer
//
//  Created by Anthony Morales on 4/16/19.
//  Copyright © 2019 Mozilla. All rights reserved.
//

import UIKit

class RequestXRPermissionsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 44
    }
}
