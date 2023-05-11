//
//  ViewController.swift
//  CustomCamera
//
//  Created by DucManh on 27/04/2023.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {

    //IBOutlets
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var cameraPreviewContainer: UIView!
    @IBOutlet weak var heightContraintCamera: NSLayoutConstraint!
    @IBOutlet weak var heightContraintVideo: NSLayoutConstraint!
    @IBOutlet weak var imageBackground: UIImageView!
    private var player: AVPlayer?
    var viewArgs: DuetViewArgs?
    private var videoUrl: URL?

    private lazy var captureStack = CVRecorder(delegate: self)
    private var isObjectDetectionEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configVideo()
        loadImageBackground()
    }

    private func loadImageBackground() {
        guard let image = viewArgs?.image,
           let key = SwiftDuetPlugin.registrar?.lookupKey(forAsset: image),
           let path = Bundle.main.path(forResource: key, ofType: nil) else {
               print("load image error")
               return
        }
        imageBackground.image = UIImage(contentsOfFile: path)
    }

    private func configVideo() {
        guard let url = viewArgs?.urlVideo else {
            print("load video error")
            return
        }
        let asset = AVAsset(url: url)
        videoUrl = url

        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))

        // Register for notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil) // Add observer

        let playerLayer = AVPlayerLayer(player: player)
        let width = UIScreen.main.bounds.width / 2
        let height = width * asset.ratio

        playerLayer.frame = CGRect(x: 0, y: 0,
                                   width: width,
                                   height: height)

        AudioRecorder.setAudio()
        heightContraintCamera.constant = height
        heightContraintVideo.constant = height

        self.videoView.layer.addSublayer(playerLayer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCaptureStack()
    }

    // Notification Handling
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        player?.seek(to: CMTime.zero)
        finishRecording()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension CameraViewController {

    private func setupCaptureStack() {
        captureStack.loadCaptureStack(parentViewForPreview: cameraPreviewContainer)
    }
}

extension CameraViewController {

    func startRecording() {
        player?.play()
        CameraEngine.shared.startCapture()
//        AudioRecorderManager.shared.startRecording()
        captureStack.recorderState = .Recording
    }

    func pauseRecording() {
        player?.pause()
        CameraEngine.shared.pauseCapture()
//        AudioRecorderManager.shared.finishRecording { url in
//            url.presentShareActivity(viewController: self)
//        }
        captureStack.recorderState = .Paused
    }

    func resumeRecording() {
        player?.play()
        CameraEngine.shared.resumeCapture()
//        AudioRecorderManager.shared.startRecording()
        captureStack.recorderState = .Recording
    }

    func resetRecoding() {
        player?.pause()
        player?.seek(to: CMTime.zero)
        CameraEngine.shared.resetCapture()
//        AudioRecorderManager.shared.resetAudio()
        captureStack.recorderState = .Stopped
    }

    private func finishRecording() {
        captureStack.recorderState = .Stopped
        CameraEngine.shared.stopCapturing { [weak self] cameraRecordUrl in
//            SwiftDuetPlugin.notifyFlutter(event: .VIDEO_RECORDED, arguments: cameraRecordUrl.path)
            guard let self = self else {
                return
            }
            self.mergeVideos(cameraRecordUrl: cameraRecordUrl)
        }

//        AudioRecorderManager.shared.finishRecording { url in
//
//        }
    }

    private func mergeVideos(cameraRecordUrl: URL) {
        let width = UIScreen.main.bounds.width
        let height = heightContraintCamera.constant
        guard let videoUrl = videoUrl else { return }
        cameraRecordUrl.gridMergeVideos(urlVideo: videoUrl,
                                        cGSize: CGSize(width: width, height: height)
        )
    }
}

extension CameraViewController: CVRecorderDelegate {
    func didChangedCamera(_ currentCameraPosition: AVCaptureDevice.Position) {
        switch currentCameraPosition {
        case .unspecified:
            print("------- Changed to back unspecified")
        case .back:
            print("------- Changed to back camera")
        case .front:
            print("------- Changed to front camera")
        @unknown default:
            print("------- Changed to unknown default")
        }
    }

    func didChangedRecorderState(_ currentRecorderState:  RecorderState) {
        print("<<<<<< changed state -- \(currentRecorderState)")
    }
}
