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

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
		
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
	
    @IBAction func recordButtonPressed(_ sender: Any) {

	}
	
	// Methods

	func setUpCamera() {
		let camera = bestCamera()
		
		captureSession.beginConfiguration()
		
		// make changes to the devices connected

		// Video input
		guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
			fatalError("Cannot create camera input")
		}
		guard captureSession.canAddInput(cameraInput) else {
			fatalError("Cannot add camera input to session")
		}
		captureSession.addInput(cameraInput)
		
		if captureSession.canSetSessionPreset(.hd1920x1080) {
			captureSession.canSetSessionPreset(.hd1920x1080)
		}
		
		// TODO: Audio input
		
		// TODO: Video output (movie)
		
		captureSession.commitConfiguration()
		cameraView.session = captureSession
	}

	/// WideAngle Lens is on every iPhone that's been shipped through 2019
	private func bestCamera() -> AVCaptureDevice {
		if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
			return device
		}
		// Fallback camera
		if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
			return device
		}
		
		fatalError("No cameras on the device. Or you are running on the Simulator (not supported)")
	}
	
	/// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
}

