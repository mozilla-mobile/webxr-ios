//
//  RequestPermissionsViewController.swift
//  XRViewer
//
//  Created by Roberto Garrido on 27/3/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit
import FontAwesomeKit
import CoreLocation
import AVFoundation
import Photos

/// A view controller that requests the requiered permissions to properly use the app
class RequestPermissionsViewController: UIViewController {

    @IBOutlet weak var buttonGPS: UIButton!
    @IBOutlet weak var buttonCamera: UIButton!
    
    let size: CGFloat = 24.0
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style(button: buttonGPS, withImage: FAKFontAwesome.locationArrowIcon(withSize: size).image(with: CGSize(width: size, height: size)))
        style(button: buttonCamera, withImage: FAKFontAwesome.cameraIcon(withSize: size).image(with: CGSize(width: size, height: size)))
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            buttonGPS.isEnabled = false
        }
        
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            buttonCamera.isEnabled = false
        }
    }
    
    fileprivate func style(button: UIButton, withImage image: UIImage) {
        button.layer.cornerRadius = button.frame.height/2.0
        button.layer.borderColor = self.view.tintColor.cgColor
        button.layer.borderWidth = 2.0
        button.setImage(image, for: .normal)
    }

    @IBAction func buttonGPSAccessTapped() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    @IBAction func buttonCameraAccessTapped() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.buttonCamera.isEnabled = false
                    self.handlePopupDismiss()
                }
            }
            
        }
    }
    
    func handlePopupDismiss() {
        if !buttonCamera.isEnabled && !buttonGPS.isEnabled {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension RequestPermissionsViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.buttonGPS.isEnabled = false
            self.handlePopupDismiss()
        }
    }
}
