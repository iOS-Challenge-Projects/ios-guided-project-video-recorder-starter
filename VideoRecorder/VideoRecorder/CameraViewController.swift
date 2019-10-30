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

	// AVCaptureSession
	lazy private var captureSession = AVCaptureSession()
	lazy private var fileOutput = AVCaptureMovieFileOutput()
	
	var player: AVPlayer!
	
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!


	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpSession()
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
	//		tapGesture.numberOfTouchesRequired = 2 // Flip our camera
		
		view.addGestureRecognizer(tapGesture)
	}

	@objc func handleTapGesture(_ tapGesture: UITapGestureRecognizer) {
		print("handleTapGesture")
		
		switch tapGesture.state {
		case .ended:
			playRecording()
		default:
			print("Handle other states: \(tapGesture.state.rawValue)")
		}
	}

	private func playRecording() {
		if let player = player {
			player.seek(to: CMTime.zero)  // seek to the beginning of the video
			player.play()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print("Start capture session")
		captureSession.startRunning()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		print("Stop capture session")
		captureSession.stopRunning()
	}

	// CMTime (timeValue, timeScale)
	// Seek to a time, you need construct a CMTime object based on the current time
	// 30 FPS (Frames per second)
	// 1 = CMTIme(1, 30)  = 1/30  = 0.033333 seconds
	// 2 = CMTime(2, 30) =  2/30  = 0.066667 seconds
	// 3 = CMTime(3, 30)
	//	CMTime.zero
	// 600 recommended = 30, 60, 24
	
	
	private func setUpSession() {
		
		captureSession.beginConfiguration()
		
		// Add the camera input
		let camera = bestBackCamera()
		
		guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
			fatalError("Cannot create a device input from camera")
		}
		
		guard captureSession.canAddInput(cameraInput) else {
			fatalError("Cannot add camera to capture session")
		}
		captureSession.addInput(cameraInput)
		
		
		// Set video mode
//		if captureSession.canSetSessionPreset(.hd4K3840x2160) {
//			captureSession.sessionPreset = .hd4K3840x2160
//			print("4K support!!!")
//		}
		
		// Add audio input
		let microphone = bestAudio()
		guard let audioInput = try? AVCaptureDeviceInput(device: microphone) else {
			fatalError("Can't create input from microphone")
		}
		guard captureSession.canAddInput(audioInput) else {
			fatalError("Can't add audio input")
		}
		captureSession.addInput(audioInput)
		
		// Output (movie recording)
		guard captureSession.canAddOutput(fileOutput) else {
			fatalError("Cannot record video to a movie file")
		}
		captureSession.addOutput(fileOutput)
		
		captureSession.commitConfiguration()
		cameraView.session = captureSession
	}

	private func bestBackCamera() -> AVCaptureDevice {
		if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
			return device
		} else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
			return device
		}
		fatalError("ERROR: No cameras on the device or you are running on the Simulator")
	}

	private func bestFrontCamera() -> AVCaptureDevice {
		if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
			return device
		}
		fatalError("ERROR: No cameras on the device or you are running on the Simulator")
	}
	
	private func bestAudio() -> AVCaptureDevice {
		if let device = AVCaptureDevice.default(for: .audio) {
			return device
		}
		fatalError("ERROR: No audio device")
	}

    @IBAction func recordButtonPressed(_ sender: Any) {
		if fileOutput.isRecording {
			// stop recording
			fileOutput.stopRecording()
			// TODO: play the video
		} else {
			// start recording
			fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
		}
	}
	
	// Helper to save to documents directory
	func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]
		
		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
	
	private func playMovie(url: URL) {
		player = AVPlayer(url: url)
		
		// Create the layer
		
		let playerLayer = AVPlayerLayer(player: player)

		// Configure size
		var topCornerRect = self.view.bounds
		topCornerRect.size.width /= 4
		topCornerRect.size.height /= 4
		topCornerRect.origin.y = view.layoutMargins.top
		
		playerLayer.frame = topCornerRect
		self.view.layer.addSublayer(playerLayer)
		
		player.play()
		
		// video gravity
	}
	
}

// Conform to delegate: AVCaptureFileOutputRecordingDelegate

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		
		if let error = error {
			print("File Recording Error: \(error)")
		}
		
		print("didFinishRecordingTo: \(outputFileURL)")
		
		playMovie(url: outputFileURL)
	}
	
	func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
		
		print("didStartRecordingTo: \(fileURL)")
	}
}

