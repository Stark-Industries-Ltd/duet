//
//  CVRecorder.swift
//  CVRecorder
//
//  Created by DucManh on 27/04/2023.
//

import UIKit
import CoreMedia
import AVFoundation
import Vision

public protocol CVRecorderDelegate: AnyObject {
    func didChangedRecorderState(_ currentRecorderState:  RecorderState)
}

public class CVRecorder {
    private weak var delegate: CVRecorderDelegate?
    private weak var parentViewForPreview: UIView?
    private var recoderView: CVRecorderView!
    private var videoUrl: URL?
    private var cgSize: CGSize?

    var recorderState: RecorderState = .NotReady {
        didSet {
            delegate?.didChangedRecorderState(recorderState)
        }
    }

    public init(delegate: CVRecorderDelegate) {
        self.delegate = delegate
    }
}

extension CVRecorder {
    public func loadCaptureStack(parentViewForPreview: UIView,
                                 videoUrl: URL?,
                                 cgSize: CGSize) {
        self.parentViewForPreview = parentViewForPreview
        self.videoUrl = videoUrl
        self.cgSize = cgSize
        CameraEngine.shared.startup(parentViewForPreview, devicePosition: .front)
        recorderState = .Stopped
    }

    public func toggleRecording() {
        switch recorderState {
        case .Stopped:
            recorderState = .Recording
            CameraEngine.shared.startCapture()
        case .Recording:
            fallthrough
        case .Paused:
            recorderState = .Stopped
            guard let videoUrl = videoUrl, let cgSize = cgSize else { return }
            CameraEngine.shared.stopCapturing { url in
                url.gridMergeVideos(urlVideo: videoUrl, cGSize: cgSize)
            }
        case .NotReady:
            print("************** Not ready ")
        }
    }

    public func togglePauseResumeRecording() {
        switch recorderState {
        case .Stopped:
            print("************** pause should not be available while camera is not recording thus check the UI ")
        case .Recording:
            recorderState = .Paused
            CameraEngine.shared.pauseCapture()
        case .Paused:
            recorderState = .Recording
            CameraEngine.shared.resumeCapture()
        case .NotReady:
            print("************** Not ready ")
        }
    }
}

extension CVRecorder {
    func prepareRecorderView() {
        guard let parentViewForPreview = parentViewForPreview else {
            return
        }
        if recoderView == nil {
            let recoderView = CVRecorderView(frame: parentViewForPreview.bounds)
            recoderView.delegate = self
            self.recoderView = recoderView
        }
        recoderView.setupCamera(parentViewForPreview, devicePosition: .front)
    }
}

extension CVRecorder: VideoCaptureDelegate {
    func videoCaptureDidChangedCamera(currentCameraPosition: AVCaptureDevice.Position) {
    }

    func videoCaptureStateDidChanged(_ currentState: RecorderState) {
        delegate?.didChangedRecorderState(currentState)
    }

    func videoCapture(_ capture: CVRecorderView, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime) {
        
    }
}
