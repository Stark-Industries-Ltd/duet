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

@available(iOS 13.0, *)
protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ capture: CVRecorderView, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)
    func videoCaptureDidChangedCamera(currentCameraPosition: AVCaptureDevice.Position)
    func videoCaptureStateDidChanged(_ currentState: RecorderState)
}

@available(iOS 13.0, *)
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
        let audioDevice = AVCaptureDevice.default( .builtInMicrophone, for: .audio, position: .front)

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
            let queue = DispatchQueue(label: "CameraEngine.record-video")

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
            let message = "CVRecorderView setupCamera \(error.localizedDescription)"
            print(message)
            SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: message)
        }
    }

    private var _filename = ""

    func setupWriter() {
        do {
            _filename = UUID().uuidString
            let videoPath = URL.documents.appendingPathComponent("\(_filename).mp4")
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
            let message = "CVRecorderView setupWriter \(error.localizedDescription)"
            print(message)
            SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: message)
        }
    }
}

@available(iOS 13.0, *)
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


@available(iOS 13.0, *)
extension CVRecorderView {
    fileprivate func canWrite() -> Bool {
        return recorderState == .Recording
        && videoWriter != nil
        && videoWriter.status == .writing
    }
}

@available(iOS 13.0, *)
extension CVRecorderView : AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }

        let writable = canWrite()

        if writable,
           sessionAtSourceTime == nil {
            //Start writing
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        }

        if writable, output == output {

            if videoWriterInput.isReadyForMoreMediaData {
                //Write video buffer
                videoWriterInput.append(sampleBuffer)
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let deltaTime = timestamp - lastTimestamp
                if deltaTime >= CMTimeMake(value: 1, timescale: Int32(fps)) {
                    lastTimestamp = timestamp
                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                    delegate?.videoCapture(self, didCaptureVideoFrame: imageBuffer, timestamp: timestamp)
                }
            }
        } else if writable,
                  output == audioDataOutput,
                  audioWriterInput.isReadyForMoreMediaData {
            audioWriterInput.append(sampleBuffer)
        } else {
            switch recorderState {
            case .Stopped:
                print("<<<<<<<< should not have got a call when player is stopped")
                break
            case .Recording:
                print("<<<<<<<< should be here when player is Recording")
            case .Paused:
                print("<<<<<<<< not writing when player is paused")
                break
            case .NotReady:
                print("<<<<<<<< should not have got a call when player is not ready")
            }
        }
    }
}
