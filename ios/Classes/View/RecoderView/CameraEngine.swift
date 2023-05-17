//
//  CameraEngine.swift
//  CVRecorder
//
//  Created by DucManh on 27/04/2023.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import Vision

public class CameraEngine: NSObject {

    public static let shared = CameraEngine()
    private var session: AVCaptureSession!
    private var preview: AVCaptureVideoPreviewLayer!
    private var captureQueue: DispatchQueue!
    private let serialQueue = DispatchQueue(label: "CameraEngine.serialQueue")
    private let detectorSerialQueue = DispatchQueue(label: "CameraEngine.detectorSerialQueue")
    private var audioConnection: AVCaptureConnection?
    private var videoConnection: AVCaptureConnection?
    private var encoder: VideoEncoder?
    private var isCapturing = false
    private var isPaused = false
    private var discont = false
    private var currentFile = 0
    private var timeOffset: CMTime!
    private var lastVideo: CMTime!
    private var lastAudio: CMTime!

    private var parentWidth = 0
    private var parentHeight = 0

    var channels: Int!
    var sampleRate: Float64!

    public func startup(_ parentView: UIView) {
        guard session == nil else {
            return
        }
        print("Starting up server")

        self.isCapturing = false
        isPaused = false
        currentFile = 0
        discont = false

        //create capture device with video
        session = AVCaptureSession()
        session.sessionPreset = .photo
        let cameraDevice = cameraWithPosition(position: .front)
        //Setup your microphone
        let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)

        do {
            session.beginConfiguration()
            // Add camera to your session
            if let cameraDevice = cameraDevice {
                let deviceInput = try AVCaptureDeviceInput(device: cameraDevice)
                if session.canAddInput(deviceInput) {
                    session.addInput(deviceInput)
                }
            }

            // Add microphone to your session
            if let audioDevice = audioDevice {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
            }

            captureQueue = DispatchQueue(label: "CameraEngine.record-video")
            let videoout = AVCaptureVideoDataOutput()
            videoout.setSampleBufferDelegate(self, queue: captureQueue)
            let settings: [String : Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
            ]

            videoout.videoSettings = settings
            videoout.alwaysDiscardsLateVideoFrames = false
            session.addOutput(videoout)
            videoout.connection(with: AVMediaType.video)?.videoOrientation = .portrait
            videoConnection = videoout.connection(with: .video)
            if videoConnection?.isVideoStabilizationSupported == true {
                videoConnection?.preferredVideoStabilizationMode = .auto
            }

            parentHeight = Int(parentView.frame.height)
            parentWidth = Int(parentView.frame.width)

            let audioout = AVCaptureAudioDataOutput()
            audioout.setSampleBufferDelegate(self, queue: captureQueue)
            session.addOutput(audioout)
            audioConnection = audioout.connection(with: .audio)
            session.commitConfiguration()

            let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            // importent line of code what will did a trick
            previewLayer.videoGravity = .resizeAspectFill
            let rootLayer = parentView.layer
            rootLayer.masksToBounds = true
            previewLayer.frame = CGRect(x: 0, y: 0,
                                        width: parentView.frame.width,
                                        height: parentView.frame.height
            )
            rootLayer.insertSublayer(previewLayer, at: 0)
            self.preview = previewLayer
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        } catch (let error) {
            print("********** camera engine startup() \(error.localizedDescription)")
        }
    }

    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: AVMediaType.video, position: .unspecified)
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }

        return nil
    }

    public func startCapture() {
        captureQueue.sync {
            if !self.isCapturing {
                print("<<<<<<<<< Start capturing")
                encoder = nil
                isPaused = false
                discont = false
                timeOffset = CMTime.zero
                isCapturing = true
            }
        }
    }

    public func stopCapturing(_ completion: @escaping((URL) -> Void)) {
        captureQueue.sync {
            if self.isCapturing {
                print("<<<<<<<<< stop capturing")
                currentFile += 1
                //serialize with audio and video capture
                isCapturing = false
                captureQueue.async {
                    self.encoder?.finishwithCompletionHandler { [weak self] url in
                        completion(url)
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            self.isCapturing = false
                            self.encoder = nil
                        }
                    }
                }
            }
        }
    }

    public func resetCapture() {
        self.isCapturing = false
        self.encoder = nil
    }

    public func pauseCapture() {
        captureQueue.sync {
            if self.isCapturing {
                print("<<<<<<<<< Initiating pause capture")
                self.isPaused = true
                discont = true
            }
        }
    }

    public func resumeCapture() {
        captureQueue.sync {
            if self.isCapturing {
                print("<<<<<<<<< resuming capture")
                self.isPaused = false
            }
        }
    }

    public func startSession() {
        guard session != nil else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    public func stopSession() {
        guard session != nil else {
            return
        }
        session.stopRunning()
    }
}

extension CameraEngine: AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    func adjustTime(sampleBuffer: CMSampleBuffer, by offset: CMTime) -> CMSampleBuffer? {
        var out:CMSampleBuffer?
        var count:CMItemCount = CMSampleBufferGetNumSamples(sampleBuffer)
        let pInfo = UnsafeMutablePointer<CMSampleTimingInfo>.allocate(capacity: count)
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: pInfo, entriesNeededOut: &count)
        var i = 0
        while i<count {
            pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset)
            pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset)
            i+=1
        }
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sampleBuffer, sampleTimingEntryCount: count, sampleTimingArray: pInfo, sampleBufferOut: &out)
        return out
    }

    func setAudioFormat(fmt: CMFormatDescription) {
        guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt) else {
            return
        }
        sampleRate = asbd.pointee.mSampleRate
        channels = Int(asbd.pointee.mChannelsPerFrame)
    }

    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        var bVideo = true
        serialQueue.sync {
            var sampleBuffer = sampleBuffer
            bVideo = connection == self.videoConnection
            if !self.isCapturing || self.isPaused {
                return
            }

            if self.encoder == nil && !bVideo {

                if let fmt = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    self.setAudioFormat(fmt: fmt)
                }

                let path = URL.documents.appendingPathComponent("video.mp4")
                if FileManager.default.isDeletableFile(atPath: path.path) {
                    do {
                        // delete old video
                        try FileManager.default.removeItem(at: path)
                    } catch {
                        print(error.localizedDescription)
                    }
                }

                do {
                    self.encoder = try VideoEncoder(path: path,
                                                    height: self.parentHeight,
                                                    width: self.parentWidth,
                                                    channels: self.channels,
                                                    samples: self.sampleRate)
                } catch (let error) {
                    print("*************** \(error.localizedDescription)")
                    return
                }
            }

            if discont {
                if bVideo {
                    return
                }
                self.discont = false

                //calc adjustment
                var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let last = bVideo ? self.lastVideo : self.lastAudio
                if (last!.isValid) {
                    if(self.timeOffset.isValid) {
                        pts = CMTimeSubtract(pts, self.timeOffset)
                    }

                    let offset = CMTimeSubtract(pts, last!)
                    print("Setting offset from \(bVideo ? "video": "audio")")
                    // this stops us having to set a scale for _timeOffset before we see the first video time
                    if self.timeOffset.value == 0 {
                        self.timeOffset = offset
                    } else {
                        self.timeOffset = CMTimeAdd(self.timeOffset, offset)
                    }
                    self.lastAudio.flags = []
                    self.lastVideo.flags = []
                    return
                }
            }

            if (self.timeOffset.value > 0) {
                if let unwrappedAdjustedBuffer = self.adjustTime(sampleBuffer: sampleBuffer, by: self.timeOffset) {
                    sampleBuffer = unwrappedAdjustedBuffer
                } else {
                    print("<<<<<<<< unable to adjust the buffer")
                }
            }

            // record most recent time so we know the length of the pause
            var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let duration = CMSampleBufferGetDuration(sampleBuffer)
            if duration.value > 0 {
                pts = CMTimeAdd(pts, duration)
            }

            if bVideo {
                self.lastVideo = pts
            } else {
                self.lastAudio = pts
            }
            //pass frame to encoder
            if self.encoder != nil {
                let _ = self.encoder?.encodeFrame(sampleBuffer: sampleBuffer, isVideo: bVideo)
            }
        }
    }
}

extension CMSampleBuffer {
    func resize(_ destSize: CGSize) -> CVPixelBuffer? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }
        // Lock the image buffer
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        // Get information about the image
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CGFloat(CVPixelBufferGetBytesPerRow(imageBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        let width = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        var pixelBuffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let topMargin = (height - destSize.height) / CGFloat(2)
        let leftMargin = (width - destSize.width) * CGFloat(2)
        let baseAddressStart = Int(bytesPerRow * topMargin + leftMargin)
        guard let baseAddress = baseAddress else {
            return nil
        }
        let addressPoint = baseAddress.assumingMemoryBound(to: UInt8.self)
        let status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                  Int(destSize.width),
                                                  Int(destSize.height),
                                                  kCVPixelFormatType_32BGRA,
                                                  &addressPoint[baseAddressStart],
                                                  Int(bytesPerRow),
                                                  nil,
                                                  nil,
                                                  options as CFDictionary,
                                                  &pixelBuffer)
        if (status != 0) {
            print(status)
            return nil
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer,CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
}
