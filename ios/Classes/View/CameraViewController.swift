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
    private var player: AVPlayer?
    var viewArgs: DuetViewArgs?
    private var videoUrl: URL?

    private lazy var captureStack = CVRecorder(delegate: self)
    private var isObjectDetectionEnabled = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initVideo()
    }

    private func initVideo() {

        //2. Create AVPlayer object
        var asset: AVAsset
        if let url = viewArgs?.url {
            asset = AVAsset(url: url)
            videoUrl = url
        } else {
            guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
                print("video.m4v not found")
                return
            }
            asset = AVAsset(url: URL(fileURLWithPath: path))
            videoUrl = URL(fileURLWithPath: path)
        }
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))

        // Register for notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil) // Add observer

        let playerLayer = AVPlayerLayer(player: player)
        let width = UIScreen.main.bounds.width / 2
        let height = width * asset.ratio
        heightContraintCamera.constant = height
        heightContraintVideo.constant = height
        playerLayer.frame = CGRect(x: 0, y: 0,
                                   width: width,
                                   height: height)

        // Executed right before playing avqueueplayer media
        AudioRecorder.setAudio()

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
        captureStack.recorderState = .Recording
        CameraEngine.shared.startCapture()
        player?.play()
    }

    func pauseRecording() {
        captureStack.recorderState = .Paused
        CameraEngine.shared.pauseCapture()
        player?.pause()
    }

    func resumeRecording() {
        captureStack.recorderState = .Recording
        CameraEngine.shared.resumeCapture()
        player?.play()
    }

    func resetRecoding() {
        captureStack.recorderState = .Stopped
        CameraEngine.shared.resetCapture()
        player?.pause()
        player?.seek(to: CMTime.zero)
    }

    private func finishRecording() {
        captureStack.recorderState = .Stopped
        CameraEngine.shared.stopCapturing { [weak self] cameraRecordUrl in
            SwiftDuetPlugin.notifyFlutter(event: .VIDEO_RECORDED, arguments: cameraRecordUrl.path)
            guard let self = self else {
                return
            }
            self.mergeVideos(cameraRecordUrl: cameraRecordUrl)
        }
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
