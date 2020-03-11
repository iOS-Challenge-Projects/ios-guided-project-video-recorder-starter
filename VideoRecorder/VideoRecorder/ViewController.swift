//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestPermissionAndShowCamera()
    }

    private func requestPermissionAndShowCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
            
        case .notDetermined:
            // First time user has seen the dialog, we don't have permission
            requestPermission()
        case .restricted:
            // parental controls restrict access to camera
            fatalError("Inform the user they cannot use the camera, they need parental permission ... show some kind of UI message")
        case .denied:
            // we asked for permission and they said no
            fatalError("Inform the user to enable camera/audio access in Settings > Privacy")
        case .authorized:
            // we asked for permission and they said yes
            showCamera()
        default:
            fatalError("Unexpected status for AVCaptureDevice authorization")
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            guard granted else {
                fatalError("Inform the user to enable camera/audio access in Settings > Privacy")
            }
            
            DispatchQueue.main.async {
                self.showCamera()
            }
        }
    }
	
	private func showCamera() {
		performSegue(withIdentifier: "ShowCamera", sender: self)
	}
}
