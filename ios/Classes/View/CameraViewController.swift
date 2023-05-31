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
    private var audioPlayer: AVAudioPlayer?
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
        let durationTime = CMTimeGetSeconds(asset.duration)
        videoUrl = url

        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))

        let interval = CMTime(value: 1, timescale: 2)

        self.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) {[weak self] progressTime in
            guard let self = self else {
                return
            }
            let seconds = CMTimeGetSeconds(progressTime)
            if seconds > 0 {
                SwiftDuetPlugin.notifyFlutter(event: .VIDEO_TIMER, arguments: "\(seconds)")
                print(seconds)
            }

            if durationTime == seconds {
                self.player?.seek(to: CMTime.zero)
                self.finishRecording()
            }
        }

        AudioRecorderManager.shared.initAudio()

        let playerLayer = AVPlayerLayer(player: player)
        let width = UIScreen.main.bounds.width / 2
        let height = width * asset.ratio

        playerLayer.frame = CGRect(x: 0, y: 0,
                                   width: width,
                                   height: height)

        heightContraintCamera.constant = height
        heightContraintVideo.constant = height

        self.videoView.layer.addSublayer(playerLayer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CameraEngine.shared.startup(cameraPreviewContainer)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func playSound(url: String) {
        guard let key = SwiftDuetPlugin.registrar?.lookupKey(forAsset: url),
              let path = Bundle.main.path(forResource: key, ofType: nil) else {
            return
        }
        let url = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension CameraViewController {

    func startCamera() {
        CameraEngine.shared.startSession()
    }

    func stopCamera() {
        CameraEngine.shared.stopSession()
    }

    func resetCamera() {
        CameraEngine.shared.resetCapture()
    }
}

extension CameraViewController {
    func startRecordingAudio() {
        AudioRecorderManager.shared.startRecording()
    }

    func pauseRecordingAudio() {
        AudioRecorderManager.shared.pauseRecording()
    }
}

extension CameraViewController {

    func startRecording() {
        player?.play()
        CameraEngine.shared.startCapture()
    }

    func pauseRecording() {
        player?.pause()
        CameraEngine.shared.pauseCapture()
    }

    func resumeRecording() {
        player?.play()
        CameraEngine.shared.resumeCapture()
    }

    func resetRecoding() {
        player?.pause()
        player?.seek(to: CMTime.zero)
        startCamera()
        AudioRecorderManager.shared.resetAudio()
    }

    private func finishRecording() {
        CameraEngine.shared.stopCapturing { [weak self] cameraRecordUrl in
            SwiftDuetPlugin.notifyFlutter(event: .VIDEO_RECORDED, arguments: cameraRecordUrl.path)
            guard let self = self else {
                return
            }
            self.mergeVideos(cameraRecordUrl: cameraRecordUrl)
        }

        AudioRecorderManager.shared.finishRecording { url in
            SwiftDuetPlugin.notifyFlutter(event: .AUDIO_RESULT, arguments: url.path)
        }
    }

    private func mergeVideos(cameraRecordUrl: URL) {
        let width = UIScreen.main.bounds.width
        let height = heightContraintCamera.constant
        guard let videoUrl = videoUrl else { return }
        cameraRecordUrl.gridMergeVideos(urlVideo: videoUrl,
                                        cGSize: CGSize(width: 1920, height: 1080)
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
