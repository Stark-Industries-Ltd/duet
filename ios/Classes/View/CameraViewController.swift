//
//  ViewController.swift
//  CustomCamera
//
//  Created by DucManh on 27/04/2023.
//

import UIKit
import AVFoundation
import Photos
import MediaPlayer

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

    var cameraView: CameraEngine?

    private lazy var captureStack = CVRecorder(delegate: self)
    private var isObjectDetectionEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView = CameraEngine()
        configVideo()
        loadImageBackground()

        //Update system volume
        MPVolumeView.setVolume(0.5)

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
        self.player?.volume = 0.3

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
        cameraView?.startup(cameraPreviewContainer)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioPlayer = nil
        player = nil
        cameraView?.stopSession()
        cameraView = nil
        AudioRecorderManager.shared.resetAudio()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func playSound(url: String, result: @escaping FlutterResult) {
        guard let key = SwiftDuetPlugin.registrar?.lookupKey(forAsset: url),
              let path = Bundle.main.path(forResource: key, ofType: nil) else {
            result(false)
            return
        }
        let url = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.5
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                result(true)
                self.audioPlayer?.play()
            }
        } catch let error {
            result(false)
            print(error.localizedDescription)
        }
    }

    func saveVideoToAlbum(path: String, result: @escaping FlutterResult) {
        URL(fileURLWithPath: path).saveVideoToAlbum(result: result)
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
        cameraView?.startCapture()
    }

    func pauseRecording() {
        player?.pause()
        cameraView?.pauseCapture()
    }

    func resumeRecording() {
        player?.play()
        cameraView?.resumeCapture()
    }

    private func finishRecording() {
        cameraView?.stopCapturing { [weak self] cameraRecordUrl in
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
        guard let videoUrl = videoUrl else { return }
        cameraRecordUrl.gridMergeVideos(urlVideo: videoUrl,
                                        cGSize: CGSize(width: 810, height: 720)
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
//Update system volume
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
