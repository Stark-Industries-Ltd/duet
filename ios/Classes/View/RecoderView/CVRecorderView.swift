//
//  CVRecorderView.swift
//  CVRecorder
//
//  Created by DucManh on 27/04/2023.
//

import UIKit
import AVFoundation
import Photos

public enum RecorderState: Int {
    case Stopped = 0
    case Recording
    case Paused
    case NotReady
}

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ capture: CVRecorderView, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)
    func videoCaptureDidChangedCamera(currentCameraPosition: AVCaptureDevice.Position)
    func videoCaptureStateDidChanged(_ currentState: RecorderState)
}

class CVRecorderView: UIView, AVAudioRecorderDelegate {
    fileprivate lazy var cameraSession = AVCaptureSession()
    fileprivate lazy var videoDataOutput = AVCaptureVideoDataOutput()
    fileprivate lazy var audioDataOutput = AVCaptureAudioDataOutput()
    private var previewLayer : AVCaptureVideoPreviewLayer!

    fileprivate var videoWriter: AVAssetWriter!
    fileprivate var videoWriterInput: AVAssetWriterInput!
    fileprivate var audioWriterInput: AVAssetWriterInput!
    fileprivate var sessionAtSourceTime: CMTime?
    
    var lastTimestamp = CMTime()
    public weak var delegate: VideoCaptureDelegate?
    public var fps = 15
    
    var currentCameraInput: AVCaptureDeviceInput!
    var cameraDevice: AVCaptureDevice?
    
    var recorderState: RecorderState = .NotReady {
        didSet{
            delegate?.videoCaptureStateDidChanged(recorderState)
        }
    }
    
    var encoder: VideoEncoder!
    var _timeOffset: CMTime!
    var _channels:  Int!
    var _sampleRate: Float64!
    var _currentFile: Int = 0
    var _discont: Bool = true
    
    var _lastVideo: CMTime!
    var _lastAudio: CMTime!
    
    func setupCamera(_ parentView: UIView,  devicePosition: AVCaptureDevice.Position) {
        cameraSession.sessionPreset = .photo

        cameraDevice = cameraWithPosition(position: devicePosition)

        //Setup your microphone
        let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)

        do {
            cameraSession.beginConfiguration()

            // Add camera to your session
            let deviceInput = try AVCaptureDeviceInput(device: cameraDevice!)
            if cameraSession.canAddInput(deviceInput) {
                cameraSession.addInput(deviceInput)
                currentCameraInput = deviceInput
            }

            // Add microphone to your session
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            if cameraSession.canAddInput(audioInput) {
                cameraSession.addInput(audioInput)
            }

            //Now we should define your output data
            let queue = DispatchQueue(label: "com.cvcamrecorder.record-video.data-output")

            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            if cameraSession.canAddOutput(videoDataOutput) {
                videoDataOutput.setSampleBufferDelegate(self, queue: queue)
                cameraSession.addOutput(videoDataOutput)
            }
            videoDataOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait

            //Define your audio output
            if cameraSession.canAddOutput(audioDataOutput) {
                audioDataOutput.setSampleBufferDelegate(self, queue: queue)
                cameraSession.addOutput(audioDataOutput)
            }

            cameraSession.commitConfiguration()

            //Present the preview of video
            previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
            previewLayer.frame = frame
            previewLayer.bounds = bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            layer.addSublayer(previewLayer)

            parentView.layer.addSublayer(layer)

            //Don't forget start running your session
            //this doesn't mean start record!
            recorderState = .Stopped
            cameraSession.startRunning()
        } catch let error {
            recorderState = .NotReady
            debugPrint(error.localizedDescription)
        }
    }

    private var _filename = ""

    func setupWriter() {
        do {
            _filename = UUID().uuidString
            let userDomainMask = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let videoPath = userDomainMask.first!.appendingPathComponent("\(_filename).mp4")
            videoWriter = try AVAssetWriter(url: videoPath, fileType: AVFileType.mp4)
            
            //Add video input
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: frame.width,
                AVVideoHeightKey: frame.height,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 2300000,
                ],
            ])
            videoWriterInput.mediaTimeScale = CMTimeScale(bitPattern: 600)
            videoWriterInput.expectsMediaDataInRealTime = true
            videoWriterInput.expectsMediaDataInRealTime = true
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
            }

            //Add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000,
            ])
            audioWriterInput.expectsMediaDataInRealTime = true
            if videoWriter.canAdd(audioWriterInput) {
                videoWriter.add(audioWriterInput)
            }
            videoWriter.startWriting()
        }
        catch let error {
            debugPrint(error.localizedDescription)
        }
    }
}

extension CVRecorderView {

    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
}

extension CVRecorderView{
    func toggleRecording() {
        switch recorderState {
        case .Stopped:
            print("start recording")
            encoder = nil
            _timeOffset = CMTime(value: 0, timescale: 0)
            _discont = false
            recorderState = .Recording
            setupWriter()
        case .Recording:
            fallthrough
        case .Paused:
            print("stop recording")
            self.stop()
            recorderState = .Stopped
        case .NotReady:
            print("error should not have received toggle pause command when NotReady")
        }
    }

    func togglePauseRecording() {
        switch recorderState{
        case .Stopped:
            print("error should not have received toggle pause command when stopped")
        case .Recording:
            print("pause recording")
            recorderState = .Paused
            _discont = true
        case .Paused:
            print("resume recording")
            recorderState = .Recording
        case .NotReady:
            print("error should not have received toggle pause command when NotReady")
        }
    }
}

extension CVRecorderView {
    fileprivate func canWrite() -> Bool {
        return recorderState == .Recording
        && videoWriter != nil
        && videoWriter.status == .writing
    }
}

extension CVRecorderView {
    func stop() {
        if recorderState == .Recording || recorderState == .Paused{
            videoWriter.finishWriting { [weak self] in
                self?.sessionAtSourceTime = nil
                guard let url = self?.videoWriter.outputURL else { return }
                self?.saveVideoToAlbum(videoUrl: url)
            }
        }else{
            print("<<<<<<<<<<< stop() should not be called wen recorder state is \(recorderState)")
        }
        
    }
    
    private func saveVideoToAlbum(videoUrl: URL) {
        var info = ""
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        }) { (success, error) in
            if success {
                info = "hello"
            } else {
                info = "保存失败，err = \(error.debugDescription)"
            }
            
            print(info)
            
            
        }
    }
}


extension CMTime {
    //    var isValid : Bool { return (flags & .Valid) != nil }
    var isValid : Bool { return flags.contains(.valid) }
}


extension CVRecorderView : AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard output != nil,
              sampleBuffer != nil,
              connection != nil,
              CMSampleBufferDataIsReady(sampleBuffer) else { return }

        let writable = canWrite()

        if writable,
           sessionAtSourceTime == nil {
            //Start writing
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        }

        if writable, output == output {
            //              ... //Your old code when make the overlay here
            
            if videoWriterInput.isReadyForMoreMediaData {
                //Write video buffer
                print("<<<<<<  videoWriterInput.append --- \(recorderState)")
                videoWriterInput.append(sampleBuffer)
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let deltaTime = timestamp - lastTimestamp
                if deltaTime >= CMTimeMake(value: 1, timescale: Int32(fps)) {
                    lastTimestamp = timestamp
                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                    //        print("fps\(timestamp)")
                    delegate?.videoCapture(self, didCaptureVideoFrame: imageBuffer, timestamp: timestamp)
                }
            }
        } else if writable,
                  output == audioDataOutput,
                  audioWriterInput.isReadyForMoreMediaData {
            //Write audio buffer
            //            print("<<<<<<  audioWriterInput.append(")
            audioWriterInput.append(sampleBuffer)
        }else{
            switch recorderState{
                
            case .Stopped:
                let i = 0
                //                 print("<<<<<<<< should not have got a call when player is stopped")
            case .Recording:
                print("<<<<<<<< should be here when player is Recording")
            case .Paused:
                let i = 0
                //                print("<<<<<<<< not writing when player is paused")
            case .NotReady:
                print("<<<<<<<< should not have got a call when player is not ready")
            }
        }
    }
}
