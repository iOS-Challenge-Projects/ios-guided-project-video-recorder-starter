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

    // Add capture session
    lazy private var captureSession = AVCaptureSession()
    
    // Add movie output (.mov)
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Resize camera preview to fill the entire screen
        cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        
        setUpCaptureSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        captureSession.stopRunning()
    }
    
    private func setUpCaptureSession() {
        let camera = bestCamera()
        
        captureSession.beginConfiguration()
        
        // Add Inputs
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput) else {
                fatalError("Can't create camera with current input")
        }
        captureSession.addInput(cameraInput)
        
        // switch to 1080p or 4k video
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080 // 1080p
        }
        
        // TODO: Add Microphone
        
        // Add Outputs

        captureSession.commitConfiguration()
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannot save mov to capture session")
        }
        captureSession.addOutput(fileOutput)
        
        cameraView.session = captureSession
    }

    private func bestCamera() -> AVCaptureDevice {
        // ultra wide lens (0.5)
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return device
        }
        
        // wide angle lens (available on every single iPhone 11)
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        
        // if non of these exist, we'll fatalError() on the simulator
        fatalError("No cameras on device (or you're on the simulator and that isn't supported)")
        
        // Potentially the hardware is missing or is broken (if the user serviced the device, dropped the phone in pool)
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        toggleRecording()
    }
    
    private func toggleRecording() {
        if fileOutput.isRecording {
            fileOutput.stopRecording()
            print("Stopped recording")
        } else {
            // FIXME: Store URL
            let url = newRecordingURL()
            print("Started recording: \(url)")
            fileOutput.startRecording(to: url, recordingDelegate: self)
        }
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
    
    private func updateViews() {
        // How do I update the record button?
        recordButton.isSelected = fileOutput.isRecording
        
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video to \(outputFileURL) \(error)")
        }
        
        updateViews()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        updateViews()
    }
}
