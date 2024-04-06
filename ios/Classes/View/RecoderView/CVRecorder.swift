//
//  CVRecorder.swift
//  CVRecorder
//
//  Created by DucManh on 27/04/2023.
//

import UIKit
import CoreMedia
import AVFoundation

public protocol CVRecorderDelegate: AnyObject {
    func didChangedRecorderState(_ currentRecorderState:  RecorderState)
}

@available(iOS 13.0, *)
public class CVRecorder {
    private weak var delegate: CVRecorderDelegate?
    private var recoderView: CVRecorderView!

    public init(delegate: CVRecorderDelegate) {
        self.delegate = delegate
    }
}
@available(iOS 13.0, *)

extension CVRecorder: VideoCaptureDelegate {
    func videoCaptureDidChangedCamera(currentCameraPosition: AVCaptureDevice.Position) {
    }

    func videoCaptureStateDidChanged(_ currentState: RecorderState) {
        delegate?.didChangedRecorderState(currentState)
    }

    func videoCapture(_ capture: CVRecorderView, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime) {
        
    }
}
