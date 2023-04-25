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
    
    public enum CameraType {
        case photo
        case video
    }
    
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
    private var recordingURL: URL?
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
    open var camereType: CameraType = .photo {
        didSet {
            self.updateFileStorage(with: self.camereType)
        }
    }
    
    open var maxZoomFactor: CGFloat = 10.0
    
    var kStreamSize : CGSize
    
    init(view: UIView) {
        self.view = view
        kStreamSize = view.frame.size
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
        self.updateFileStorage(with: self.camereType)
        self.initialize()
        self.configureWriters()
        self.configurePreview()
        self.configureSession()
    }
    
    open func startRecording() {
        self.isRecording = true
        switch self.camereType {
        case .photo:
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        case .video:
            self.configureWriters()
            self.updateFileStorage(with: self.camereType)
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
    }
    
    open func stopRecording() {
        self.isRecording = false
        self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
        self.audioOutput.setSampleBufferDelegate(nil, queue: nil)
        self.assetWriter?.finishWriting {
            if let fileURL = self.recordingURL {
                self.videoCompletion?(fileURL)
            }
            self.isRecording = false
            self.isRecordingSessionStarted = false
        }
    }
    
    private func updateFileStorage(with mode: CameraType) {
        var fileURL: URL
        switch mode {
        case .video:
            fileURL = URL(fileURLWithPath: "\(NSTemporaryDirectory() as String)/video.mov")
        case .photo:
            fileURL = URL(fileURLWithPath: "\(NSTemporaryDirectory() as String)/image.mp4")
        }
        self.recordingURL = fileURL
        let fileManager = FileManager()
        if fileManager.isDeletableFile(atPath: fileURL.path) {
            _ = try? fileManager.removeItem(atPath: fileURL.path)
        }
    }
    
    private func initialize() {
        self.session.sessionPreset = .high
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
            if let fileURL = self.recordingURL {
                self.assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mov)
            }
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
        DispatchQueue(label: "startRunning").async {
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
//        print("Capture")
        if !self.isRecordingSessionStarted {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.assetWriter?.startSession(atSourceTime: presentationTime)
            self.isRecordingSessionStarted = true
        }
        
//        if captureOutput is AVCaptureVideoDataOutput {
//            print(connection)
//            if #available(iOS 13.0, *) {
//                let newBuffer = croppedSampleBuffer(sampleBuffer: sampleBuffer, rect: CGRect(x: 0, y: 0, width: kStreamSize.width, height: kStreamSize.height))
//                                print(sampleBuffer.imageBuffer!)
//
//
//                self.appendSampleBuffer(newBuffer)
//            } else {
//                // Fallback on earlier versions
//
//
//                self.appendSampleBuffer(sampleBuffer)
//            }
//        }else{
            
            
            self.appendSampleBuffer(sampleBuffer)
//        }
    }
    
//    func croppedSampleBuffer(sampleBuffer:CMSampleBuffer, rect:CGRect)->CMSampleBuffer? {
//            
//            guard let imageBufferIn = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//                return nil
//            }
//            
//            CVPixelBufferLockBaseAddress(imageBufferIn, .readOnly)
//            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBufferIn);
//            let originWidth = CVPixelBufferGetWidth(imageBufferIn);
//            let bytesPerPixel = bytesPerRow / originWidth;
//            var cropX = Int(rect.origin.x)
//            let cropY = Int(rect.origin.y);
//            // Start pixel in RGB color space can't be odd.
//            if (cropX % 2 != 0) {
//                cropX+=1;
//            }
//            
//            guard let baseAddress = CVPixelBufferGetBaseAddress(imageBufferIn)?.assumingMemoryBound(to: UInt8.self) else{
//                return nil
//            }
//            
//            let cropStartOffset = cropY * bytesPerRow + cropX * bytesPerPixel;
//            let pixelBuffer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
//            let pixelFormat = CVPixelBufferGetPixelFormatType(imageBufferIn)
//            var error:CVReturn
//            let options = [
//                kCVPixelBufferCGImageCompatibilityKey as String : true,
//                kCVPixelBufferCGBitmapContextCompatibilityKey as String : true,
//                kCVPixelBufferWidthKey as String : rect.size.width,
//                kCVPixelBufferHeightKey as String : rect.size.height,
//                ] as CFDictionary
//            
//            error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,                 // allocator
//                Int(rect.size.width),                     // width
//                Int(rect.size.height),                    // height
//                pixelFormat,                         // pixelFormatType
//                baseAddress + cropStartOffset,                           // baseAddress
//                bytesPerRow,                         // bytesPerRow
//                nil,                                // releaseCallback
//                nil,                                // releaseRefCon
//                options,   // pixelBufferAttributes
//                pixelBuffer)
//            
//            if (error != kCVReturnSuccess) {
//                print("Crop CVPixelBufferCreateWithBytes error \(error)");
//                return nil;
//            }
//            
//            var ciImage:CIImage = CIImage(cvImageBuffer: imageBufferIn)
//            ciImage = ciImage.cropped(to: rect)
//            // CIImage is not in the original point after cropping. So we need to pan.
//            ciImage = ciImage.transformed(by: CGAffineTransform(translationX: CGFloat(-cropX), y: CGFloat(-cropY)))
//            
//            guard let gCIContext = self.gCIContext,  let croppedPixelBuffer = pixelBuffer.pointee else {
//                return nil
//            }
//            
//            gCIContext.render(ciImage, to: croppedPixelBuffer)
//            // Prepares sample timing info.
//            let sampleTime = UnsafeMutablePointer<CMSampleTimingInfo>.allocate(capacity: MemoryLayout<CMSampleTimingInfo>.size)
//            sampleTime.initialize(to: CMSampleTimingInfo(
//                duration: CMSampleBufferGetDuration(sampleBuffer),
//                presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
//                decodeTimeStamp: CMSampleBufferGetDecodeTimeStamp(sampleBuffer)))
//            let videoInfo: UnsafeMutablePointer<CMVideoFormatDescription?> = UnsafeMutablePointer.allocate(capacity: MemoryLayout<CMVideoFormatDescription?>.size)
//            error =
//                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: croppedPixelBuffer, formatDescriptionOut: videoInfo);
//            if (error != kCVReturnSuccess) {
//                print("CMVideoFormatDescriptionCreateForImageBuffer error \(error as Int32)")
//                return nil;
//            }
//            guard let videoInfoDesc = videoInfo.pointee else {
//                return nil
//            }
//            // Creates `CMSampleBufferRef`.
//            let resultBuffer: UnsafeMutablePointer<CMSampleBuffer?> = UnsafeMutablePointer.allocate(capacity: MemoryLayout<CMSampleBuffer?>.size)
//            error = CMSampleBufferCreateForImageBuffer(
//                allocator: kCFAllocatorDefault,
//                imageBuffer: croppedPixelBuffer,
//                dataReady: true,
//                makeDataReadyCallback: nil,
//                refcon: nil,
//                formatDescription: videoInfoDesc,
//                sampleTiming: sampleTime,
//                sampleBufferOut: resultBuffer);
//            if (error != kCVReturnSuccess) {
//                print("CMSampleBufferCreateForImageBuffer error \(error as Int32)");
//            }
//            CVPixelBufferUnlockBaseAddress(imageBufferIn, .readOnly);
//            return resultBuffer.pointee;
//        }
//    
    
//    private func pushStream(_ output: CIImage) {
//        let kStreamSize = view.frame.size
//       var newPixelBuffer: CVPixelBuffer? = nil
//       CVPixelBufferCreate(kCFAllocatorDefault,
//                           Int(kStreamSize.width),
//                           Int(kStreamSize.height),
//                           kCVPixelFormatType_32BGRA,
//                           nil,
//                           &newPixelBuffer)
//
//       kCIContext.render(output, to: newPixelBuffer!)
//       lfLiveSession.pushVideo(newPixelBuffer)
//     }
//
    
    private func convert(_ sampleBuffer: CMSampleBuffer) -> CIImage? {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)!
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let newContext = CGContext(data: baseAddress,
                                   width: width,
                                   height: height,
                                   bitsPerComponent: 8,
                                   bytesPerRow: bytesPerRow,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        if(newContext == nil){
            return nil
        }
       let imageRef = newContext!.makeImage()!
       CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

       var output = CIImage(cgImage: imageRef)

        var transform = output.orientationTransform(forExifOrientation: 6) // UIImageOrientation.right
        output = output.transformed(by: transform)

       let ratio = kStreamSize.width / output.extent.size.width
        transform = output.orientationTransform(forExifOrientation: 1)
       transform = transform.scaledBy(x: ratio, y: ratio)
        output = output.transformed(by: transform)

        transform = output.orientationTransform(forExifOrientation: 1)
       transform = transform.translatedBy(x: 0, y: -(output.extent.size.height - kStreamSize.height) / 2)
        output = output.transformed(by: transform)

        return output.cropped(to: CGRect(origin: CGPoint.zero, size: kStreamSize))
     }

    
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
//        if let buffer = photoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil),
//            let image = UIImage(data: data) {
//            self.photoCompletion?(image)
//        }
//    }
//    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
//
//    }
    
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
