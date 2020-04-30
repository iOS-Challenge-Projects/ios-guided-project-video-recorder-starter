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
    
    private var player: AVPlayer! //Its an optional but we force unwrap but we wont use it till it has a value/or does exist
    
    //MARK: - Outlets
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resize camera preview to fill the entire screen
        setupCaptureSession()
        cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        
        //tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
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
        if fileOutput.isRecording{
            fileOutput.stopRecording()
        }else{
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
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
        
        //Audio
        let microphone = bestAudio()
        guard let audioInput = try? AVCaptureDeviceInput(device: microphone),
            captureSession.canAddInput(audioInput) else {
                fatalError("Can't create and add input from microphone")
        }
        captureSession.addInput(audioInput)
        
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
    
    private func bestAudio() -> AVCaptureDevice {
           if let device = AVCaptureDevice.default(for: .audio) {
               return device
           }
           fatalError("No audio")
       }
    
    private func updateViews(){
        //This way we can use the bool of the fileOutput to set the state of the button
        recordButton.isSelected = fileOutput.isRecording
    }
    
    private func playMovie(url: URL){
        player = AVPlayer(url: url)
        
        //To present a video we need a diferent layer than the one presenting the live video
        let playerLayer = AVPlayerLayer(player: player)
        
        //Put the vide tumbnail on the top left corner
        var topRect = view.bounds
        topRect.size.height = topRect.size.height / 4
        topRect.size.width = topRect.size.width / 4
        //Prevent the tuhbnail from going out of the safe area
        topRect.origin.y = view.layoutMargins.top
        
        playerLayer.frame = topRect
        //Added to the view
        view.layer.addSublayer(playerLayer)
        
        //Automatically play the movie
        player.play()
    }
    
    @objc private func handleTapGesture(_ tapGesture: UITapGestureRecognizer){
        switch tapGesture.state {
        case .ended:
            replayMovie()
        default:
            break
        }
    }
    
    private func replayMovie()  {
        guard let player = player else { return }
        player.seek(to: .zero)//This is like reqwind the movie to 0 before playing again
        player.play()
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("didStartRecordingTo")
        updateViews()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Stop")
        if let error = error{
            print("Video Recording error: \(error)")
        }else{
            playMovie(url: outputFileURL)
        }
        updateViews()
    }
}
