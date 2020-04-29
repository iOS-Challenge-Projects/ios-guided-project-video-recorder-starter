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
    
    //MARK: - Properties
    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    
    //MARK: - Outlets
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resize camera preview to fill the entire screen
        cameraView.videoPlayerView.videoGravity = .resizeAspectFill
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //Stop running the live vide when the view disapear
        captureSession.stopRunning()
    }
    
    //MARK: - Actions
    @IBAction func recordButtonPressed(_ sender: Any) {
        
    }
    
    //MARK: - Methods
    /// Creates a new file URL in the documents directory
    private func newRecordingURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let name = formatter.string(from: Date())
        let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
        return fileURL
    }
    
    private func setupCaptureSession() {
        //Helper func to get the camera
        let camera = bestCamera()
        
        captureSession.beginConfiguration()
        
        // Add inputs
        
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput) else {
                fatalError("Can't create an input from the camera, do something better than crashing")
        }
        captureSession.addInput(cameraInput)

        //Choose quality
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
        
        // Add output
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannot record movie to disk")
        }
        captureSession.addOutput(fileOutput)

        
        captureSession.commitConfiguration()
    
        //Live Preview
        cameraView.session = captureSession
    }
    
    private func bestCamera() -> AVCaptureDevice {
        //Here we request the type of camera in this case a  Ultra Wide Camera
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back){
            return device
        }
        
        //If we cannot grab a Ultra Wide Camera then we get the normal Wide Angle Camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        
        fatalError("No cameras on the device (or you are running it on the iPhone simulator")
    }
}

