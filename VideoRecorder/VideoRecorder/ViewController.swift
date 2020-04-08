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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestPermissionAndShowCamera()
    }

    private func requestPermissionAndShowCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
            
            case .notDetermined: // 1st run and the user hasn't been asked to give permission
                requestPermission()
            case .restricted: // Parental controls limit access to video
                fatalError("Your don't have permission to use the camera, talk to your parent about enabling")
            case .denied: // 2nd+ run, the user didn't trust us, or they said no by accident (show how to enable)
                fatalError("Show them a link to settings to get access to video")
            case .authorized: // 2nd+ run, they've given permission to use the camera
                showCamera()
            @unknown default:
                fatalError("Didn't handle a new state for AVCaptureDevice authorization")
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else {
                fatalError("Tell user they need to give video permission")
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
