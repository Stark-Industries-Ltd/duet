//
//  VideoEncoder.swift
//  CVRecorder
//
//  Created by DucManh on 27/04/2023.
//

import Foundation
import AVFoundation
import Photos

class VideoEncoder {
    let path: URL
    private let _writer: AVAssetWriter!
    private let _videoInput: AVAssetWriterInput!
    private let _audioInput: AVAssetWriterInput!
    private let _audioRecorder = AudioRecorder()
    
    init(path: URL, height: Int, width: Int, channels: Int, samples: Float64) throws {
        self.path = path
        do {
            if FileManager.default.fileExists(atPath: path.path){
                try FileManager.default.removeItem(at: path)
            }

            _writer = try AVAssetWriter(url: path, fileType: .mp4)

            //Add video input
            _videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 2300000,
                ],
            ])
            _videoInput.expectsMediaDataInRealTime = true
            if _writer.canAdd(_videoInput) {
                _writer.add(_videoInput)
            }
            // add audio
            _audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000,
            ])
            _audioInput.expectsMediaDataInRealTime = true
            if _writer.canAdd(_audioInput) {
                _writer.add(_audioInput)
            }
        } catch (let error) {
            print("<<<<<<<<<< error obserevd \(error.localizedDescription)")
            throw error
        }
    }

    func finishwithCompletionHandler(_ completion: @escaping((URL) -> Void)) {
        _writer.finishWriting {
            let url = self._writer.outputURL
            self.saveVideoToAlbum(videoUrl: url)
            completion(url)
            self._audioRecorder.finishRecording { url in
                print("AUDIO URL <<< \(url)" )
                if let vc = FLNativeView.controller {
                    url.presentShareActivity(viewController: vc)
                }
            }
        }
    }

    func encodeFrame(sampleBuffer: CMSampleBuffer, isVideo: Bool) -> Bool {
        if (_writer.status == .unknown) {
            let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            _writer.startWriting()
            _writer.startSession(atSourceTime: startTime)
            _audioRecorder.startRecording()
        }

        if (_writer.status == .failed) {
            print("_writer failed \(_writer.error?.localizedDescription ?? "")")
            return false
        }

        if isVideo {
            if (_videoInput.isReadyForMoreMediaData == true) {
                _videoInput.append(sampleBuffer)
                return true
            }
        } else {
            if(_audioInput.isReadyForMoreMediaData) {
                _audioInput.append(sampleBuffer)
                return true
            }
        }
        return false
    }

    deinit{
        debugPrint("_encoder deinitialized")
    }

}

extension VideoEncoder {
    private func saveVideoToAlbum(videoUrl: URL) {
        var info = ""
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        }) { (success, error) in
            if success {
                info = "success"
            } else {
                info = "Error = \(error.debugDescription)"
            }
            print(info)
        }
    }
}
