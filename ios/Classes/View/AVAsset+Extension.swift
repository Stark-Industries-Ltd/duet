//
//  AVAsset+Extension.swift
//  duet
//
//  Created by DucManh on 27/04/2023.
//

import Foundation
import AVFoundation

extension AVAsset {
    var videoSize: CGSize {
        let tracks = self.tracks(withMediaType: AVMediaType.video)
        if (tracks.count > 0) {
            let videoTrack = tracks[0]
            let size = videoTrack.naturalSize
            let txf = videoTrack.preferredTransform
            let realVidSize = size.applying(txf)
            return realVidSize
        }
        return CGSize(width: 0, height: 0)
    }

    var ratio: CGFloat {
        return self.videoSize.height / self.videoSize.width
    }
}
