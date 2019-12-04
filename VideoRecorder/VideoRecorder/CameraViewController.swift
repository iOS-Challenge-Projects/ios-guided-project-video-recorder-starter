//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

	lazy private var captureSession = AVCaptureSession()
	
	
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!


	override func viewDidLoad() {
		super.viewDidLoad()
	
		setUpCamera()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		captureSession.startRunning()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		captureSession.stopRunning()
	}

	private func setUpCamera() {
		let camera = bestCamera()
		
		captureSession.beginConfiguration()
		guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
			fatalError("Can't create an input form the camera, do something better than crashing")
		}
		
		// Add inputs
		guard captureSession.canAddInput(cameraInput) else {
			fatalError("This session can't handle this type of input: \(cameraInput)")
		}
		captureSession.addInput(cameraInput)
				
		if captureSession.canSetSessionPreset(.hd1920x1080) {
			captureSession.sessionPreset = .hd1920x1080
		}
		
		captureSession.commitConfiguration()
		
		cameraView.session = captureSession
	}
	
	private func bestCamera() -> AVCaptureDevice {
		if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
			return device
		}
		if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
			return device
		}
		
		fatalError("No cameras on the device (or you are running it on the iPhone simulator")
	}


    @IBAction func recordButtonPressed(_ sender: Any) {

	}
}

