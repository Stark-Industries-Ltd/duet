//
//  URL+Extension .swift
//  duet
//
//  Created by DucManh on 27/04/2023.
//

import Foundation
import AVFoundation
import AVKit
import Photos

extension URL {

    func gridMergeVideos(urlVideo: URL, cGSize: CGSize) {
        DPVideoMerger().gridMergeVideos(
            withFileURLs: [urlVideo, self],
            videoResolution: cGSize,
            completion: {
                (_ mergedVideoFile: URL?, _ error: Error?) -> Void in
                guard let mergedVideoFile = mergedVideoFile else {
                    return
                }
                mergedVideoFile.saveVideoToAlbum()
            }
        )
    }

    func saveVideoToAlbum() {
        let info = ""
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self)
        }) { (success, error) in
            if success {
                print(info)
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
