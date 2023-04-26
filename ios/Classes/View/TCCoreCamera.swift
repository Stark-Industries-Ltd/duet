//
//  CameraManager.swift
//  CustomCamera
//
//  Created by Taras Chernyshenko on 2/28/18.
//  Copyright © 2018 Taras Chernyshenko. All rights reserved.
//

import UIKit
import AVFoundation

class TCCoreCamera: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate,
                    AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    typealias VideoCompletion = (URL) -> Void
    typealias PhotoCompletion = (UIImage) -> Void

    public enum CameraPosition {
        case front
        case back
    }
    
    private let recordingQueue = DispatchQueue(label: "recording.queue")
    private let audioSettings: [String : Any]
    private let videoSettings: [String : Any]
    private let view: UIView
    private let audioWriterInput: AVAssetWriterInput
    private let videoWriterInput: AVAssetWriterInput
    private let photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    private let videoOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    private let audioOutput: AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
    private let session: AVCaptureSession = AVCaptureSession()
    
    private var deviceInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var assetWriter: AVAssetWriter?
    private(set) var isRecording: Bool = false
    private var isRecordingSessionStarted: Bool = false
    private(set) var cameraPosition: CameraPosition = .back
    private(set) var zoomFactor: CGFloat = 0.5 {
        didSet {
            if self.zoomFactor < 1.0 || self.zoomFactor > self.maxZoomFactor { return }
            if let device = self.deviceInput?.device {
                do {
                    try device.lockForConfiguration()
                    device.ramp(toVideoZoomFactor: self.zoomFactor, withRate: 3.0)
                    device.unlockForConfiguration()
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    open var videoCompletion: VideoCompletion?
    open var photoCompletion: PhotoCompletion?

    open var maxZoomFactor: CGFloat = 10.0
    private var recoderNummber = 0
    private let fileManager = FileManager()
    private var fileURL: URL {
        return URL(fileURLWithPath: "\(NSTemporaryDirectory() as String)/video\(self.recoderNummber).mp4")
    }

    init(view: UIView) {
        self.view = view
        self.audioSettings = [
            AVFormatIDKey : kAudioFormatAppleIMA4,
            AVNumberOfChannelsKey : 1,
            AVSampleRateKey : 32000.0
        ]
        self.videoSettings = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : view.frame.width,
            AVVideoHeightKey : view.frame.height,
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill
        ]
        self.audioWriterInput = AVAssetWriterInput(mediaType: .audio,
                                                   outputSettings: self.audioSettings)
        self.videoWriterInput = AVAssetWriterInput(mediaType: .video,
                                                   outputSettings: self.videoSettings)
        super.init()
        self.updateFileStorage()
        self.initialize()
        self.configureWriters()
        self.configurePreview()
        self.configureSession()
    }
    
    open func startRecording() {
        self.isRecording = true
        self.configureWriters()
        self.updateFileStorage()
        guard let assetWriter = self.assetWriter else {
            assertionFailure("AssetWriter was not initialized")
            return
        }
        if !assetWriter.startWriting() {
            assertionFailure("AssetWriter error: \(assetWriter.error.debugDescription)")
        }
        self.isRecording = true
        self.videoOutput.setSampleBufferDelegate(self, queue: self.recordingQueue)
        self.audioOutput.setSampleBufferDelegate(self, queue: self.recordingQueue)
    }

    open func stopRecording() {
        self.isRecording = false
        self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
        self.audioOutput.setSampleBufferDelegate(nil, queue: nil)
        self.assetWriter?.finishWriting {
            self.videoCompletion?(self.fileURL)
            self.recoderNummber += 1
            self.isRecording = false
            self.isRecordingSessionStarted = false
        }
    }
    
    private func updateFileStorage() {
        if fileManager.isDeletableFile(atPath: fileURL.path) {
            do {
                // delete old video
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func initialize() {
        self.session.sessionPreset = .photo
        self.videoWriterInput.expectsMediaDataInRealTime = true
        self.audioWriterInput.expectsMediaDataInRealTime = true
        self.cameraPosition = .front
        self.addVideoInput(position: .front)
    }
    
    func addVideoInput(position: AVCaptureDevice.Position) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                    for: .video, position: position) else { return }
        if let currentInput = self.deviceInput {
            self.session.removeInput(currentInput)
            self.deviceInput = nil
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.deviceInput = input
            }
        } catch {
            print(error)
        }
    }
    
    private func configureWriters() {
        do {
            self.assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mov)
        } catch {
            print(error.localizedDescription)
        }
        guard let assetWriter = self.assetWriter else {
            assertionFailure("AssetWriter was not initialized")
            return
        }
        if assetWriter.canAdd(self.videoWriterInput) {
            assetWriter.add(self.videoWriterInput)
        }
        if assetWriter.canAdd(self.audioWriterInput) {
            assetWriter.add(self.audioWriterInput)
        }
    }
    
    private func configurePreview() {
        let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        //        importent line of code what will did a trick
        previewLayer.videoGravity = .resizeAspectFill
        let rootLayer = self.view.layer
        rootLayer.masksToBounds = true
        previewLayer.frame = CGRect(x: 0, y: 0,
                                    width: view.frame.width,
                                    height: view.frame.height
        )
        rootLayer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    private func configureSession() {
        DispatchQueue.main.async {
            self.session.beginConfiguration()
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            if let videoConnection = self.videoOutput.connection(with: .video) {
                if videoConnection.isVideoStabilizationSupported {
                    videoConnection.preferredVideoStabilizationMode = .auto
                }
                videoConnection.videoOrientation = .portrait
            }
            self.session.commitConfiguration()
            let audioDevice = AVCaptureDevice.default(for: .audio)
            guard let audioDevice = audioDevice else {
                return
            }
            let audioIn = try? AVCaptureDeviceInput(device: audioDevice)
            if self.session.canAddInput(audioIn!) {
                self.session.addInput(audioIn!)
            }
            if self.session.canAddOutput(self.audioOutput) {
                self.session.addOutput(self.audioOutput)
            }
        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput
                       sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !self.isRecordingSessionStarted {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.assetWriter?.startSession(atSourceTime: presentationTime)
            self.isRecordingSessionStarted = true
        }
        self.appendSampleBuffer(sampleBuffer)
    }

    private func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        let description = CMFormatDescriptionGetMediaType(CMSampleBufferGetFormatDescription(sampleBuffer)!)
        switch description {
        case kCMMediaType_Audio:
            if self.audioWriterInput.isReadyForMoreMediaData {
//                print("appendSampleBuffer audio");
                self.audioWriterInput.append(sampleBuffer)
            }
        default:
            if self.videoWriterInput.isReadyForMoreMediaData {
//                print("appendSampleBuffer video");
                if !self.videoWriterInput.append(sampleBuffer) {
                    print("Error writing video buffer");
                }
            }
        }
    }
}
