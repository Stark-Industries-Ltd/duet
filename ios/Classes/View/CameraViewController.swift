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
import Combine

protocol DuetProtocol: AnyObject {
    func startRecordingAudio()
    func pauseRecordingAudio()
    func startRecording()
    func pauseRecording()
    func resumeRecording()
    func playSound(url: String, result: @escaping FlutterResult)
    func playAudioFromUrl(path: String, result: @escaping FlutterResult)
    func stopAudioPlayer(result: @escaping FlutterResult)
    func resetData(result: @escaping FlutterResult) 
    func retryMergeVideo(cameraUrl: String, result: @escaping FlutterResult)
}
@available(iOS 13.0, *)
class CameraViewController: UIViewController {

    let defaultVolume: Float = 0.5
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
    private var timeObserver: Any?
    private var observer: NSObjectProtocol?
    private let audioRecorderManager = AudioRecorderManager()
    

    private var cancelBag: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView = CameraEngine()
        configData()
        loadImageBackground()
        
        //Update system volume
        MPVolumeView.setVolume(defaultVolume)
        debugPrint("viewDidLoad")
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main) { _ in
                SwiftDuetPlugin.notifyFlutter(event: .WILL_ENTER_FOREGROUND, arguments: "")
            }
        
        SwiftDuetPlugin.instance?.delegate = self
    }

    deinit {
        debugPrint("deinit camera")
        SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: "Duet deinit")
        cancelBag.removeAll()
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
        if let timeObserver = timeObserver {
            NotificationCenter.default.removeObserver(timeObserver)
        }
        self.player?.pause();
        cameraView?.stopCapturing({ URL in
            print("Stop capturing")
        }) // Dừng camera
        cameraView = nil // Giải phóng camera
    }

    private func loadImageBackground() {
        guard let image = viewArgs?.image,
              let key = SwiftDuetPlugin.instance?.registrar?.lookupKey(forAsset: image),
              let path = Bundle.main.path(forResource: key, ofType: nil) else {
            print("load image error")
            return
        }
        imageBackground.image = UIImage(contentsOfFile: path)
    }

    private func configData() {
        guard let url = viewArgs?.urlVideo else {
            print("load video error")
            return
        }
        let asset = AVAsset(url: url)
        let durationTime = CMTimeGetSeconds(asset.duration)
        videoUrl = url

        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))

        let interval = CMTime(value: 1, timescale: 3)
        
        timeObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) {[weak self] progressTime in
            guard let self = self else {
                return
            }
            let seconds = CMTimeGetSeconds(progressTime)
            if seconds > 0 {
                SwiftDuetPlugin.notifyFlutter(event: .VIDEO_TIMER, arguments: "\(seconds)")
            }

            // Xử lý case seconds dừng ở 90.35693333333333, trong khi durationTime = 90.38933333333334
            if durationTime - 0.2 <= seconds {
                self.playerItemDidReachEnd()
            }
        }
        
        // Xử lý case seconds dừng ở 90.35693333333333, trong khi durationTime = 90.38933333333334
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
        .sink { _ in
            self.playerItemDidReachEnd()
        }
        .store(in: &cancelBag)

        audioRecorderManager.initAudio()

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
    
    func playerItemDidReachEnd() {
        self.player?.seek(to: CMTime.zero)
        self.player?.pause()
        SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: "flutter finishRecording")
        self.finishRecording()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraView?.startup(cameraPreviewContainer)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        audioPlayer = nil
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player = nil
        cameraView?.stopSession()
        cameraView = nil
        audioRecorderManager.resetAudio()
    }

    

    
}

@available(iOS 13.0, *)
extension CameraViewController: DuetProtocol {
    func startRecordingAudio() {
        audioRecorderManager.startRecording()
    }

    func pauseRecordingAudio() {
        audioRecorderManager.pauseRecording()
    }
    
    func startRecording() {
        player?.play()
        cameraView?.startCapture()
    }

    func resumeRecording() {
        player?.play()
        cameraView?.resumeCapture()
    }
    
    func playSound(url: String, result: @escaping FlutterResult) {
        guard let key = SwiftDuetPlugin.instance?.registrar?.lookupKey(forAsset: url),
              let path = Bundle.main.path(forResource: key, ofType: nil) else {
            result(false)
            SwiftDuetPlugin.notifyFlutter(event: .AUDIO_FINISH, arguments: "")
            return
        }
        let url = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1
            audioPlayer?.play()
            result(true)
        } catch let error {
            result(false)
            SwiftDuetPlugin.notifyFlutter(event: .AUDIO_FINISH, arguments: "")
            print(error.localizedDescription)
        }
    }
    
    func playAudioFromUrl(path: String, result: @escaping FlutterResult) {
        guard let url = URL(string: path) else {
            result(false)
            return
        }

        var downloadTask: URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: url,
                                                      completionHandler:
                { [weak self] (url, response, error) -> Void in
                guard let url = url, let self = self else {
                    result(false)
                    return
                }
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                    self.audioPlayer?.volume = 10
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.play()
                    result(true)
                } catch let error {
                    result(false)
                    print(error.localizedDescription)
                }
            })
        downloadTask.resume()
    }

    func stopAudioPlayer(result: @escaping FlutterResult) {
        self.audioPlayer?.stop()
        result("")
    }
    
    func resetData(result: @escaping FlutterResult) {
        //Update system volume
        MPVolumeView.setVolume(defaultVolume)
    }

    func pauseRecording() {
        player?.pause()
        cameraView?.pauseCapture()
    }
    
    func retryMergeVideo(cameraUrl: String, result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: cameraUrl)
        self.mergeVideos(cameraRecordUrl: url)
        result("")
    }
}

@available(iOS 13.0, *)
extension CameraViewController {
    private func finishRecording() {
        cameraView?.stopCapturing { [weak self] cameraRecordUrl in
            SwiftDuetPlugin.notifyFlutter(event: .VIDEO_RECORDED, arguments: cameraRecordUrl.path)
            guard let self = self else {
                return
            }
            self.mergeVideos(cameraRecordUrl: cameraRecordUrl)
        }

        audioRecorderManager.finishRecording { url in
            SwiftDuetPlugin.notifyFlutter(event: .AUDIO_RESULT, arguments: url.path)
        }
    }

    private func mergeVideos(cameraRecordUrl: URL) {
        guard let videoUrl = videoUrl, let duetViewArgs = viewArgs else { return }
        cameraRecordUrl.gridMergeVideos(duetViewArgs: duetViewArgs, urlVideo: videoUrl,
                                        cGSize: CGSize(width: 810, height: 720)
        )
    }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
extension CameraViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        SwiftDuetPlugin.notifyFlutter(event: .AUDIO_FINISH, arguments: "")
    }
}
