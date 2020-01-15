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
	lazy private var fileOutput = AVCaptureMovieFileOutput()
	
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
		
		setUpCamera()
		
		// TODO: Add tap gesture to replay video (repeat loop)
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
		toggleRecording()
	}
	
	// Methods
	
	func updateViews() {
		recordButton.isSelected = fileOutput.isRecording
	}

	func toggleRecording() {
		if fileOutput.isRecording {
			// stop
			fileOutput.stopRecording()
		} else {
			// start
			fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
		}
	}
	
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
		
		// Video output (movie)
		guard captureSession.canAddOutput(fileOutput) else {
			fatalError("Can't setup the file output for the movie")
		}
		captureSession.addOutput(fileOutput)
		
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

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		if let error = error {
			print("Error saving video: \(error)")
		}
		print("Video: \(outputFileURL.path)")
		updateViews()
	}
	
	func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
		updateViews()
	}
}
