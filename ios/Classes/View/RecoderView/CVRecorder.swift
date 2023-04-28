//
//  CVRecorder.swift
//  CVRecorder
//
//  Created by Ankit Sachan on 04/05/22.
//

import UIKit
import CoreMedia
import AVFoundation
import Vision

public protocol CVRecorderDelegate: AnyObject {
    func didChangedCamera(_ currentCameraPosition: AVCaptureDevice.Position)
    //    func didStartedRecording()
    func didChangedRecorderState(_ currentRecorderState:  RecorderState)
}


public class CVRecorder {
    //private ivars
    private weak var delegate: CVRecorderDelegate?
    private weak var parentViewForPreview: UIView?
    private var recoderView: CVRecorderView!
    var videoUrl: URL?
    var cgSize: CGSize?

    var recorderState : RecorderState = .NotReady{
        didSet{ delegate?.didChangedRecorderState(recorderState) }
    }

    public init(delegate: CVRecorderDelegate){
        self.delegate = delegate
    }

}

//Public interfaces
extension CVRecorder{
    public func loadCaptureStack(parentViewForPreview: UIView){
        self.parentViewForPreview = parentViewForPreview
        CameraEngine.shared.startup(parentViewForPreview, devicePosition: .front)
        recorderState = .Stopped
    }
    
    public func changeCamera(){
        //        recoderView.changeCamera()
        print("<<<<<<<<<<< TBD: for Camera engine")
    }
    
    public func toggleRecording(){
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
//                SwiftDuetPlugin.notifyFlutter(event: EventType.VIDEO_RECORDED, arguments: url)
                url.gridMergeVideos(urlVideo: videoUrl, cGSize: cgSize)
            }
        case .NotReady:
            print("************** Not ready ")
        }
        
    }
    
    public func togglePauseResumeRecording(){
        //        recoderView.togglePauseRecording()
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
        if recoderView == nil{
            let recoderView = CVRecorderView(frame: parentViewForPreview!.bounds)
            recoderView.delegate = self
            self.recoderView = recoderView
        }
        recoderView.setupCamera(parentViewForPreview!, devicePosition: .front)
    }
}

extension CVRecorder : VideoCaptureDelegate{
    func videoCaptureDidChangedCamera(currentCameraPosition: AVCaptureDevice.Position) {
        delegate?.didChangedCamera(currentCameraPosition)
    }
    
    func videoCaptureStateDidChanged(_ currentState: RecorderState) {
        delegate?.didChangedRecorderState(currentState)
    }
    
    func videoCapture(_ capture: CVRecorderView, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime) {
        
    }
}
