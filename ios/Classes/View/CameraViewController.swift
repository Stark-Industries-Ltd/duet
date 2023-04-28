//
//  ViewController.swift
//  CustomCamera
//
//  Created by Taras Chernyshenko on 6/27/17.
//  Copyright © 2017 Taras Chernyshenko. All rights reserved.
//

//import UIKit
//import AVKit
//import AVFoundation
//import Photos

import UIKit
//import CVRecorder
import AVFoundation
import Photos

class CameraViewController: UIViewController {

    //IBOutlets
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var cameraPreviewContainer: UIView!
    @IBOutlet private weak var togglePauseResumeButton : UIButton?
    @IBOutlet private weak var toggleRecordingButton : UIButton?
    @IBOutlet private weak var changeCamera : UIButton?
    @IBOutlet private weak var cvToggleButton : UIButton?
    @IBOutlet weak var heightContraintVideo: NSLayoutConstraint!
    private var player: AVPlayer?
    var viewArgs: DuetViewArgs?

    // private ivars
    private lazy var captureStack = CVRecorder(delegate: self)
    private var isObjectDetectionEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        initVideo()
    }

    private func initVideo() {

        //2. Create AVPlayer object
//        var asset: AVAsset
//        if let url = viewArgs?.url {
//            asset = AVAsset(url: url)
//        }else{
            guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
                debugPrint("video.m4v not found")
                return
            }
            let asset = AVAsset(url: URL(fileURLWithPath: path))
//        }
        //2. Create AVPlayer object
        let videoSize = asset.videoSize
        let playerItem = AVPlayerItem(asset: asset)
        let ratio = videoSize.height / videoSize.width
        self.player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        let withScreen = UIScreen.main.bounds.width
        heightContraintVideo.constant = withScreen * ratio
        playerLayer.frame = CGRect(x: 0, y: 0,
                                   width: withScreen,
                                   height: withScreen * ratio)
        self.videoView.layer.addSublayer(playerLayer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }

    private func gridMergeVideos(cGSize: CGSize) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("video.mp4")

        guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
            print("video.m4v not found")
            return
        }
        let url = URL(fileURLWithPath: path)
        DPVideoMerger().gridMergeVideos(
            withFileURLs: [url, url],
            videoResolution: cGSize,
            completion: {
                (_ mergedVideoFile: URL?, _ error: Error?) -> Void in
                if error != nil {
                    let errorMessage = "Could not merge videos: \(error?.localizedDescription ?? "error")"
                    let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                    alert.addAction( UIAlertAction( title: "OK", style: .default, handler: { (a) in } ) )

                    self.present(alert, animated: true) {() -> Void in }
                    return
                }

                self.saveInPhotoLibrary(with: mergedVideoFile!)
            }
        )
    }

    @IBAction func exportVideo(_ sender: UIButton) {
        let width = self.view.frame.width
        let height = self.view.frame.height - UIApplication.shared.statusBarFrame.height
        self.gridMergeVideos( cGSize: CGSize(width: width, height: height))
    }

    private func saveInPhotoLibrary(with fileURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                print(error.debugDescription)
            }
        }
    }

}

extension CameraViewController {

    private func updateChangeCameraControl(_ currentRecorderState: RecorderState) {
        switch currentRecorderState {
        case .Stopped:
            changeCamera?.isUserInteractionEnabled = true
            changeCamera?.backgroundColor = .green
            changeCamera?.setTitle("Change Camera", for: .normal)
        case .Paused:
            fallthrough
        case .Recording:
            fallthrough
        case .NotReady:
            changeCamera?.isUserInteractionEnabled = false
            changeCamera?.backgroundColor = .gray
            changeCamera?.setTitle("Change Camera Disabled", for: .normal)
        }
    }

    private func updatePauseResumeControl(_ currentRecorderState: RecorderState){
        switch currentRecorderState {
        case .Paused:
            togglePauseResumeButton?.isUserInteractionEnabled = true
            togglePauseResumeButton?.backgroundColor = .green
            togglePauseResumeButton?.setTitle("Resume", for: .normal)
        case .Recording:
            togglePauseResumeButton?.isUserInteractionEnabled = true
            togglePauseResumeButton?.backgroundColor = .green
            togglePauseResumeButton?.setTitle("Pause", for: .normal)
        case .Stopped:
            fallthrough
        case .NotReady:
            togglePauseResumeButton?.isUserInteractionEnabled = false
            togglePauseResumeButton?.backgroundColor = .gray
            togglePauseResumeButton?.setTitle("Pause", for: .normal)
        }
    }

    private func updateToggleRecordingControl(_ currentRecorderState: RecorderState) {
        switch currentRecorderState {
        case .Paused:
            fallthrough
        case .Recording:
            toggleRecordingButton?.isUserInteractionEnabled = true
            toggleRecordingButton?.backgroundColor = .green
            toggleRecordingButton?.setTitle("Stop", for: .normal)
        case .Stopped:
            toggleRecordingButton?.isUserInteractionEnabled = true
            toggleRecordingButton?.backgroundColor = .green
            toggleRecordingButton?.setTitle("Start", for: .normal)
        case .NotReady:
            toggleRecordingButton?.isUserInteractionEnabled = false
            toggleRecordingButton?.backgroundColor = .gray
            toggleRecordingButton?.setTitle("Not Ready", for: .normal)
        }
    }


    private func disableChangeCameraControl(){
        changeCamera?.isUserInteractionEnabled = false
        changeCamera?.backgroundColor = .gray
    }

    private func enableChangeCameraControl(){
        changeCamera?.isUserInteractionEnabled = true
        changeCamera?.backgroundColor = .green
    }

    private func changeControlStates(_ currentRecorderState: RecorderState) {
        updatePauseResumeControl(currentRecorderState)
        updateToggleRecordingControl(currentRecorderState)
        updateChangeCameraControl(currentRecorderState)
    }

    private func setup(){
        setupCaptureStack()
    }

//    private func startPreview() {
//        captureStack.loadCaptureStack(parentViewForPreview: cameraPreviewContainer)
//    }

    private func setupCaptureStack() {
        captureStack.loadCaptureStack(parentViewForPreview: cameraPreviewContainer)
        print(cameraPreviewContainer.frame.width)
        print(cameraPreviewContainer.frame.height)
    }
}

extension CameraViewController {
    @IBAction func pausePressed() {
        captureStack.togglePauseResumeRecording()
        if (captureStack.recorderState == .Recording) {
            player?.play()
        } else {
            player?.pause()
        }
    }

    @IBAction func toggleRecording() {
        captureStack.toggleRecording()
        if (captureStack.recorderState == .Recording) {
            player?.play()
        } else {
            player?.pause()
        }
    }

    @IBAction func changeCameraPresed() {
        captureStack.changeCamera()
    }

    @IBAction func toggleDetection(_ toggleButton: UIButton) {
        isObjectDetectionEnabled = !isObjectDetectionEnabled
        if isObjectDetectionEnabled {
            toggleButton.setImage(UIImage(named: "open"), for: .normal)
        } else {
            toggleButton.setImage(UIImage(named: "close"), for: .normal)
        }
        captureStack.toggleDetection(isObjectDetectionEnabled)
    }
}


extension CameraViewController: CVRecorderDelegate{
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
        changeControlStates(currentRecorderState)
    }
}

extension CameraViewController {
    @IBAction func navigateToPlayerScreen(){
//        let playerVc = VideoPlayerViewController(nibName: "VideoPlayerViewController", bundle: nil)
//        self.navigationController?.pushViewController(playerVc, animated: true)
    }
}


//class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
//
//    @IBOutlet private weak var topView: UIView?
//    @IBOutlet private weak var middleView: UIView?
//    @IBOutlet private weak var innerView: UIView?
//    @IBOutlet weak var videoView: UIView!
//    @IBOutlet weak var cameraView: UIView!
//    @IBOutlet weak var heightContraintVideo: NSLayoutConstraint!
//    private var cameraManager: TCCoreCamera?
//
//    private var listRecoder = [RecoderModel]()
//
//    private var player: AVPlayer?
//    private var audioSession = AVAudioSession.sharedInstance()
//
//    var viewArgs: DuetViewArgs?
//
//    @IBAction private func recordingButton(_ sender: UIButton) {
//        record()
//    }
//
//    func record(){
//            guard let cameraManager = self.cameraManager else { return }
//            if cameraManager.isRecording {
//                cameraManager.stopRecording()
//                self.setupStartButton()
//                player?.pause()
//            } else {
//                cameraManager.startRecording()
//                self.setupStopButton()
//                self.player?.play()
//            }
//    }
//
//    private func initVideo() {
//
//        //2. Create AVPlayer object
//        var asset: AVAsset
//        if let url = viewArgs?.url {
//            asset = AVAsset(url: url)
//        }else{
//            guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
//                debugPrint("video.m4v not found")
//                return
//            }
//            asset = AVAsset(url: URL(fileURLWithPath: path))
//        }
//        //2. Create AVPlayer object
//        let videoSize = asset.videoSize
//        let playerItem = AVPlayerItem(asset: asset)
//        let ratio = videoSize.height / videoSize.width
//        self.player = AVPlayer(playerItem: playerItem)
//        let playerLayer = AVPlayerLayer(player: player)
//        let withScreen = UIScreen.main.bounds.width
//        heightContraintVideo.constant = withScreen * ratio
//        playerLayer.frame = CGRect(x: 0, y: 0,
//                                   width: withScreen,
//                                   height: withScreen * ratio)
//        self.videoView.layer.addSublayer(playerLayer)
//        settingAudioSession()
//    }
//
//    private func settingAudioSession() {
//        //Executed right before playing avqueueplayer media
//        do {
//            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
//            try audioSession.setActive(true)
//        } catch {
//            fatalError("Error Setting Up Audio Session")
//        }
//    }
//
//    @IBAction func exportVideo(_ sender: UIButton) {
////        guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
////            print("video.m4v not found")
////            return
////        }
////        let url = URL(fileURLWithPath: path)
////
////        url.extractAudioFromVideo(audioURL: URL(fileURLWithPath: "\(NSTemporaryDirectory() as String)/audioSave.mp3")) { url, error in
////            url?.presentShareActivity(viewController: self)
////        }
//        mergeVideosRecoder()
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.navigationController?.isNavigationBarHidden = true
//        self.topView?.layer.borderWidth = 1.0
//        self.topView?.layer.borderColor = UIColor.darkGray.cgColor
//        self.topView?.layer.cornerRadius = 32
//        self.middleView?.layer.borderWidth = 4.0
//        self.middleView?.layer.borderColor = UIColor.white.cgColor
//        self.middleView?.layer.cornerRadius = 32
//        self.innerView?.layer.borderWidth = 32.0
//        self.innerView?.layer.cornerRadius = 32
//        self.setupStartButton()
//        initVideo()
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        self.cameraManager = TCCoreCamera(view: self.cameraView)
//        self.cameraManager?.videoCompletion = { recoderModel in
//            print("finished writing to \(recoderModel.fileURL.absoluteString)")
//            self.saveInPhotoLibrary(with: recoderModel.fileURL)
//            self.listRecoder.append(recoderModel)
//        }
//    }
//
//    private func setupStartButton() {
//        self.topView?.backgroundColor = UIColor.clear
//        self.middleView?.backgroundColor = UIColor.clear
//
//        self.innerView?.layer.borderWidth = 32.0
//        self.innerView?.layer.borderColor = UIColor.white.cgColor
//        self.innerView?.layer.cornerRadius = 32
//        self.innerView?.backgroundColor = UIColor.lightGray
//        self.innerView?.alpha = 0.2
//    }
//
//    private func setupStopButton() {
//        self.topView?.backgroundColor = UIColor.white
//        self.middleView?.backgroundColor = UIColor.white
//
//        self.innerView?.layer.borderColor = UIColor.red.cgColor
//        self.innerView?.backgroundColor = UIColor.red
//        self.innerView?.alpha = 1.0
//    }
//
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }

//    private func mergeVideosRecoder() {
//        let assets = self.listRecoder.compactMap { recoder in
//            if (try? recoder.fileURL.checkResourceIsReachable()) == true {
//                return AVAsset(url: recoder.fileURL)
//            }
//            return nil
//        }
//
//        let width = self.view.frame.width
//        let height = self.view.frame.height - UIApplication.shared.statusBarFrame.height
//        guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
//            debugPrint("video.m4v not found")
//            return
//        }
//        if #available(iOS 13.0, *) {
//            print(NSDate.now)
//        } else {
//            // Fallback on earlier versions
//        }
//        KVVideoManager.shared.mergeWithAnimation(arrayVideos: [AVAsset(url: URL(fileURLWithPath: path)),
//                                                               AVAsset(url: listRecoder.first!.fileURL)]) { [weak self] fileURL, error in
//            guard let self = self, let fileURL = fileURL else {
//                print("Merge video error: \(error)")
//                return
//            }
//
//            SwiftDuetPlugin.notifyFlutter(event: EventType.VIDEO_RECORDED, arguments: fileURL.absoluteString)
////            self.saveInPhotoLibrary(with: fileURL)
//            self.gridMergeVideos(fileURL: fileURL, cGSize: CGSize(width: width, height: height))
//        }
//    }
//
//    private func gridMergeVideos(fileURL: URL, cGSize: CGSize) {
//        guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
//            print("video.m4v not found")
//            return
//        }
//        let url = URL(fileURLWithPath: path)
//        DPVideoMerger().gridMergeVideos(
//            withFileURLs: [url, fileURL],
//            videoResolution: cGSize,
//            completion: {
//                (_ mergedVideoFile: URL?, _ error: Error?) -> Void in
//                if error != nil {
//                    let errorMessage = "Could not merge videos: \(error?.localizedDescription ?? "error")"
//                    let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
//                    alert.addAction( UIAlertAction( title: "OK", style: .default, handler: { (a) in } ) )
//
//                    self.present(alert, animated: true) {() -> Void in }
//                    return
//                }
//
//                self.saveInPhotoLibrary(with: mergedVideoFile!)
//            }
//        )
//    }
//
//}
