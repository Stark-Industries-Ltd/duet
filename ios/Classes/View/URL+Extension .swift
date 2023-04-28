//
//  URL+Extension .swift
//  duet
//
//  Created by DucManh on 27/04/2023.
//

import Foundation
import AVFoundation
import AVKit

extension URL {

    func extractAudioFromVideo(audioURL: URL, completion: @escaping (URL?, Error?) -> Void) {
        let asset = AVURLAsset(url: self)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil, NSError(domain: "com.example.extractaudio", code: -1, userInfo: nil))
            return
        }
        exporter.shouldOptimizeForNetworkUse = true
        exporter.outputFileType = .m4a
        exporter.outputURL = audioURL
        let audioRange = CMTimeRange(start: .zero, duration: asset.duration)
        exporter.timeRange = audioRange
        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                completion(audioURL, nil)

            case .failed, .cancelled:
                completion(nil, exporter.error)
            default:
                completion(nil, NSError(domain: "com.example.extractaudio", code: -1, userInfo: nil))
            }
        }
    }

    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func presentShareActivity(viewController: UIViewController) {
        let player = AVPlayer(url: self)
        DispatchQueue.main.async {
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            viewController.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
    }

}
