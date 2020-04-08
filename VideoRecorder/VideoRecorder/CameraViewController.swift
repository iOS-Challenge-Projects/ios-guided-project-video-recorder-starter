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
    
    private var player: AVPlayer! // It's an optional, but we're treating as a non-optional
    // We're promising that we'll initialize before we use it
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Resize camera preview to fill the entire screen
        cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        
        setUpCaptureSession()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        captureSession.stopRunning()
    }
    
    @objc private func handleTapGesture(_ tapGesture: UITapGestureRecognizer) {
        print("tap")
        
        switch tapGesture.state {
            case .ended:
                replayMovie()
            default:
                break // ignore all other states
        }
    }
    
    private func replayMovie() {
        guard let player = player else { return }
        
        // 30 FPS, 60 FPS, 24 Frames Per Second
        // CMTime (0, 30) = 1st frame
        // CMTime(1, 30) = 2nd frame ...
        player.seek(to: .zero)
        player.play()
    }
    
    
    private func setUpCaptureSession() {
        
        captureSession.beginConfiguration()
        
        // Add inputs
        let camera = bestCamera()
        
        // Video
        guard let captureInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(captureInput) else {
                fatalError("Can't create the input form the camera")
        }
        captureSession.addInput(captureInput)
        
        if captureSession.canSetSessionPreset(.hd1920x1080) { // FUTURE: Play with 4k
            captureSession.sessionPreset = .hd1920x1080
        }
        
        // Audio
        let microphone = bestAudio()
        guard let audioInput = try? AVCaptureDeviceInput(device: microphone),
            captureSession.canAddInput(audioInput) else {
                fatalError("Can't create microphone input")
        }
        captureSession.addInput(audioInput)
        
        // Add outputs
        
        // Recording to disk
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannot record to disk")
        }
        captureSession.addOutput(fileOutput)
        
        captureSession.commitConfiguration()
        
        // Live preview
        cameraView.session = captureSession
    }

    private func bestCamera() -> AVCaptureDevice {
        // All iPhones have a wide angle camera (front + back)
        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return ultraWideCamera
        }
        
        if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wideCamera
        }
        
        // Future: Add a button to toggle front/back camera
        
        fatalError("No cameras on the device (or you're running this on a Simulator which isn't supported)")
    }
    
    private func bestAudio() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(for: .audio) {
            return device
        }
        fatalError("No audio")
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        if fileOutput.isRecording {
            fileOutput.stopRecording()  // Future: Play with pausing using another button
        } else {
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
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
        recordButton.isSelected = fileOutput.isRecording
    }
    
    private func playMovie(url: URL) {
        player = AVPlayer(url: url)
        
        let playerLayer = AVPlayerLayer(player: player)
        
        // top left corner (Fullscreen, you'd need a close button)
        var topRect = view.bounds
        topRect.size.height = topRect.size.height / 4
        topRect.size.width = topRect.size.width / 4 // create a constant for the "magic number"
        topRect.origin.y = view.layoutMargins.top
        playerLayer.frame = topRect
        view.layer.addSublayer(playerLayer)
        
        player.play()
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("didFinishRecording")
        if let error = error {
            print("Video Recording Error: \(error)")
        } else {
            playMovie(url: outputFileURL)
        }
        updateViews()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Update UI
        print("didStartRecording: \(fileURL)")
        
        updateViews()
    }
}
