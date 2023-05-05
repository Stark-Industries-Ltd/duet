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
    private var cgSize: CGSize?

    private lazy var captureStack = CVRecorder(delegate: self)
    private var isObjectDetectionEnabled = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initVideo()
    }

    private func initVideo() {

        //2. Create AVPlayer object
        var asset: AVAsset
        //        if let url = viewArgs?.url {
        //            asset = AVAsset(url: url)
        //            videoUrl = url
        //        } else {
        guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
            print("video.m4v not found")
            return
        }
        asset = AVAsset(url: URL(fileURLWithPath: path))
        videoUrl = URL(fileURLWithPath: path)
        //        }
        //2. Create AVPlayer object
        let videoSize = asset.videoSize
        let ratio = videoSize.height / videoSize.width
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))

        // Register for notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil) // Add observer

        let playerLayer = AVPlayerLayer(player: player)
        let width = UIScreen.main.bounds.width / 2
        let height = width * ratio
        heightContraintCamera.constant = height
        heightContraintVideo.constant = height
        playerLayer.frame = CGRect(x: 0, y: 0,
                                   width: width,
                                   height: height)

        let audioSession = AVAudioSession.sharedInstance()

        //Executed right before playing avqueueplayer media
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            fatalError("Error Setting Up Audio Session")
        }

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
        let width = UIScreen.main.bounds.width
        let height = heightContraintCamera.constant
        cgSize = CGSize(width: width, height: height)
        captureStack.loadCaptureStack(parentViewForPreview: cameraPreviewContainer,
                                      videoUrl: videoUrl,
                                      cgSize: cgSize)
        print(cameraPreviewContainer.frame.width)
        print(cameraPreviewContainer.frame.height)
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
        guard let videoUrl = videoUrl, let cgSize = cgSize else { return }
        CameraEngine.shared.stopCapturing { url in
            url.gridMergeVideos(urlVideo: videoUrl, cGSize: cgSize)
        }
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
