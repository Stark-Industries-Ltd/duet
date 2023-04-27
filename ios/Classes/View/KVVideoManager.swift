//
//  KVVideoManager.swift
//  TCCoreCamera
//
//  Created by DucManh on 22/04/2023.
//  Copyright © 2023 Taras Chernyshenko. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import MobileCoreServices
import AVKit

struct VideoData {
    var index:Int?
    var image:UIImage?
    var asset:AVAsset?
    var isVideo = false
}

struct TextData {
    var text = ""
    var fontSize:CGFloat = 40
    var textColor = UIColor.red
    var showTime:CGFloat = 0
    var endTime:CGFloat = 0
    var textFrame = CGRect(x: 0, y: 0, width: 500, height: 500)
}

class KVVideoManager {
    static let shared = KVVideoManager()

    let defaultSize = CGSize(width: 720, height: 1280) // Default video size
    var videoDuration = 30.0 // Duration of output video when merging videos & images
    var imageDuration = 5.0 // Duration of each image

    typealias Completion = (URL?, Error?) -> Void

    //
    // Merge array videos
    //
    func merge(arrayVideos:[AVAsset], completion:@escaping Completion) -> Void {
        doMerge(arrayVideos: arrayVideos, animation: false, completion: completion)
    }

    //
    // Merge array videos with transition animation
    //
    func mergeWithAnimation(arrayVideos:[AVAsset], completion:@escaping Completion) -> Void {
        doMerge(arrayVideos: arrayVideos, animation: true, completion: completion)
    }

    //
    // Add background music to video
    //
    func merge(video: AVAsset, withBackgroundMusic music: AVAsset, completion:@escaping Completion) -> Void {
        // Init composition
        let mixComposition = AVMutableComposition()
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []

        // Get video track
        guard let videoTrack = video.tracks(withMediaType: AVMediaType.video).first else {
            completion(nil, nil)
            return
        }

        // Get audio track
        var audioTrack:AVAssetTrack?
        if music.tracks(withMediaType: AVMediaType.audio).count > 0 {
            audioTrack = music.tracks(withMediaType: AVMediaType.audio).first
        }

        // Init video & audio composition track
        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

        let startTime = CMTime.zero
        let duration = video.duration
        var insertTime = CMTime.zero

        do {
            // Add video track to video composition at specific time
            try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                       of: videoTrack,
                                                       at: insertTime)

            // Add audio track to audio composition at specific time
            if let audioTrack = audioTrack {
                let audioDuration = music.duration > video.duration ? video.duration : music.duration
                try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: audioDuration),
                                                           of: audioTrack,
                                                           at: insertTime)
            }

            // Add instruction for video track
            if let videoCompositionTrack = videoCompositionTrack {
                let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack, asset: video, targetSize: video.videoSize)
                arrayLayerInstructions.append(layerInstruction)
            }

            // Increase the insert time
            insertTime = CMTimeAdd(insertTime, duration)
        } catch {
            print("Load track error")
            completion(nil, nil)
        }

        let path = NSTemporaryDirectory().appending("mergedVideo.mp4")
        let exportURL = URL(fileURLWithPath: path)

        // Check exist and remove old file
        FileManager.default.removeItemIfExisted(exportURL)

        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions

        // Main video composition
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = video.videoSize

        // Init exporter
        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportURL
        exporter?.outputFileType = AVFileType.mp4
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainComposition

        // Do export
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter: exporter, videoURL: exportURL, completion: completion)
            }
        })
    }

    private func doMerge(arrayVideos:[AVAsset], animation:Bool, completion:@escaping Completion) -> Void {
        var insertTime = CMTime.zero
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []
        var renderSize = arrayVideos.first?.videoSize ?? defaultSize

        // Silence sound (in case video has no sound track)
//        guard let silenceURL = Bundle.main.url(forResource: "silence", withExtension: "mp3") else {
//            print("Missing resource")
//            completion(nil, nil)
//            return
//        }

//        let silenceAsset = AVAsset(url:silenceURL)
//        let silenceSoundTrack = silenceAsset.tracks(withMediaType: AVMediaType.audio).first

        // Init composition
        let mixComposition = AVMutableComposition()

        for videoAsset in arrayVideos {
            // Get video track
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }

            // Get audio track
            var audioTrack: AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }
//            else {
//                audioTrack = silenceSoundTrack
//            }

            // Init video & audio composition track
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

            do {
                let startTime = CMTime.zero
                let duration = videoAsset.duration

                // Add video track to video composition at specific time
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                           of: videoTrack,
                                                           at: insertTime)

                // Add audio track to audio composition at specific time
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                               of: audioTrack,
                                                               at: insertTime)
                }

                // Add instruction for video track
                if let videoCompositionTrack = videoCompositionTrack {
                    let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack, asset: videoAsset, targetSize: renderSize)

                    // Hide video track before changing to new track
                    let endTime = CMTimeAdd(insertTime, duration)

                    if animation {
                        let durationAnimation = 1.0.toCMTime()

                        layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: CMTimeRange(start: endTime, duration: durationAnimation))
                    }
                    else {
                        layerInstruction.setOpacity(0, at: endTime)
                    }

                    arrayLayerInstructions.append(layerInstruction)
                }

                // Increase the insert time
                insertTime = CMTimeAdd(insertTime, duration)
            }
            catch {
                print("Load track error")
            }
        }

        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions

        // Main video composition
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = renderSize

        // Export to file
        let path = NSTemporaryDirectory().appending("mergedVideo.mp4")
        let exportURL = URL(fileURLWithPath: path)

        // Remove file if existed
        FileManager.default.removeItemIfExisted(exportURL)

        // Init exporter
        let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportURL
        exporter?.outputFileType = AVFileType.mp4
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainComposition

        // Do export
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter: exporter, videoURL: exportURL, completion: completion)
            }
        })
    }
}

// MARK:- Private methods
extension KVVideoManager {
    private func videoCompositionInstructionForTrack(track: AVCompositionTrack?, asset: AVAsset, targetSize: CGSize) -> AVMutableVideoCompositionLayerInstruction {
        guard let track = track else {
            return AVMutableVideoCompositionLayerInstruction()
        }

        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

        let transform = assetTrack.fixedPreferredTransform
        let assetInfo = orientationFromTransform(transform)

        var scaleToFitRatio = targetSize.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            // Scale to fit target size
            scaleToFitRatio = targetSize.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)

            // Align center Y
            let newY = targetSize.height/2 - (assetTrack.naturalSize.width * scaleToFitRatio)/2
            let moveCenterFactor = CGAffineTransform(translationX: 0, y: newY)

            let finalTransform = transform.concatenating(scaleFactor).concatenating(moveCenterFactor)

            instruction.setTransform(finalTransform, at: .zero)
        } else {
            // Scale to fit target size
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)

            // Align center Y
            let newY = targetSize.height/2 - (assetTrack.naturalSize.height * scaleToFitRatio)/2
            let moveCenterFactor = CGAffineTransform(translationX: 0, y: newY)

            let finalTransform = transform.concatenating(scaleFactor).concatenating(moveCenterFactor)

            instruction.setTransform(finalTransform, at: .zero)
        }

        return instruction
    }

    private func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false

        switch [transform.a, transform.b, transform.c, transform.d] {
        case [0.0, 1.0, -1.0, 0.0]:
            assetOrientation = .right
            isPortrait = true

        case [0.0, -1.0, 1.0, 0.0]:
            assetOrientation = .left
            isPortrait = true

        case [1.0, 0.0, 0.0, 1.0]:
            assetOrientation = .up

        case [-1.0, 0.0, 0.0, -1.0]:
            assetOrientation = .down

        default:
            break
        }

        return (assetOrientation, isPortrait)
    }

    private func setOrientation(image:UIImage?, onLayer:CALayer, outputSize:CGSize) -> Void {
        guard let image = image else { return }

        if image.imageOrientation == UIImage.Orientation.up {
            // Do nothing
        }
        else if image.imageOrientation == UIImage.Orientation.left {
            let rotate = CGAffineTransform(rotationAngle: .pi/2)
            onLayer.setAffineTransform(rotate)
        }
        else if image.imageOrientation == UIImage.Orientation.down {
            let rotate = CGAffineTransform(rotationAngle: .pi)
            onLayer.setAffineTransform(rotate)
        }
        else if image.imageOrientation == UIImage.Orientation.right {
            let rotate = CGAffineTransform(rotationAngle: -.pi/2)
            onLayer.setAffineTransform(rotate)
        }
    }

    private func exportDidFinish(exporter:AVAssetExportSession?, videoURL:URL, completion:@escaping Completion) -> Void {
        if exporter?.status == AVAssetExportSession.Status.completed {
            print("Exported file: \(videoURL.absoluteString)")
            completion(videoURL,nil)
        }
        else if exporter?.status == AVAssetExportSession.Status.failed {
            completion(videoURL,exporter?.error)
        }
    }

    private func makeTextLayer(string:String, fontSize:CGFloat, textColor:UIColor, frame:CGRect, showTime:CGFloat, hideTime:CGFloat) -> CXETextLayer {
        let textLayer = CXETextLayer()
        textLayer.string = string
        textLayer.fontSize = fontSize
        textLayer.foregroundColor = textColor.cgColor
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.opacity = 0
        textLayer.frame = frame


        let fadeInAnimation = CABasicAnimation.init(keyPath: "opacity")
        fadeInAnimation.duration = 0.5
        fadeInAnimation.fromValue = NSNumber(value: 0)
        fadeInAnimation.toValue = NSNumber(value: 1)
        fadeInAnimation.isRemovedOnCompletion = false
        fadeInAnimation.beginTime = CFTimeInterval(showTime)
        fadeInAnimation.fillMode = CAMediaTimingFillMode.forwards

        textLayer.add(fadeInAnimation, forKey: "textOpacityIN")

        if hideTime > 0 {
            let fadeOutAnimation = CABasicAnimation.init(keyPath: "opacity")
            fadeOutAnimation.duration = 1
            fadeOutAnimation.fromValue = NSNumber(value: 1)
            fadeOutAnimation.toValue = NSNumber(value: 0)
            fadeOutAnimation.isRemovedOnCompletion = false
            fadeOutAnimation.beginTime = CFTimeInterval(hideTime)
            fadeOutAnimation.fillMode = CAMediaTimingFillMode.forwards

            textLayer.add(fadeOutAnimation, forKey: "textOpacityOUT")
        }

        return textLayer
    }
}

class CXETextLayer : CATextLayer {

    override init() {
        super.init()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(layer: aDecoder)
    }

    override func draw(in ctx: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10

        ctx.saveGState()
        ctx.translateBy(x: 0.0, y: yDiff)
        super.draw(in: ctx)
        ctx.restoreGState()
    }
}
