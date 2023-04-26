//
//  ViewController.swift
//  CustomCamera
//
//  Created by Taras Chernyshenko on 6/27/17.
//  Copyright © 2017 Taras Chernyshenko. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Photos

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet private weak var topView: UIView?
    @IBOutlet private weak var middleView: UIView?
    @IBOutlet private weak var innerView: UIView?
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var heightContraintVideo: NSLayoutConstraint!
    private var cameraManager: TCCoreCamera?
    private var fileUrls = [URL]()
    private var player: AVPlayer?
    private var audioSession = AVAudioSession.sharedInstance()

    @IBAction private func recordingButton(_ sender: UIButton) {
        guard let cameraManager = self.cameraManager else { return }
        if cameraManager.isRecording {
            cameraManager.stopRecording()
            self.setupStartButton()
            player?.pause()
        } else {
            cameraManager.startRecording()
            self.setupStopButton()
            self.player?.play()
        }
    }

    private func initVideo() {
        guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        //2. Create AVPlayer object
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let videoSize = asset.videoSize()
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
        settingAudioSession()
    }

    private func settingAudioSession() {
        //Executed right before playing avqueueplayer media
        do {
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setActive(true)
        } catch {
            fatalError("Error Setting Up Audio Session")
        }
    }

    @IBAction func exportVideo(_ sender: UIButton) {
        mergeVideoCamera()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.topView?.layer.borderWidth = 1.0
        self.topView?.layer.borderColor = UIColor.darkGray.cgColor
        self.topView?.layer.cornerRadius = 32
        self.middleView?.layer.borderWidth = 4.0
        self.middleView?.layer.borderColor = UIColor.white.cgColor
        self.middleView?.layer.cornerRadius = 32
        self.innerView?.layer.borderWidth = 32.0
        self.innerView?.layer.cornerRadius = 32
        self.setupStartButton()
        initVideo()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cameraManager = TCCoreCamera(view: self.cameraView)
        self.cameraManager?.videoCompletion = { fileURL in
            print("finished writing to \(fileURL.absoluteString)")
            self.fileUrls.append(fileURL)
        }

    }

    private func setupStartButton() {
        self.topView?.backgroundColor = UIColor.clear
        self.middleView?.backgroundColor = UIColor.clear
        
        self.innerView?.layer.borderWidth = 32.0
        self.innerView?.layer.borderColor = UIColor.white.cgColor
        self.innerView?.layer.cornerRadius = 32
        self.innerView?.backgroundColor = UIColor.lightGray
        self.innerView?.alpha = 0.2
    }
    
    private func setupStopButton() {
        self.topView?.backgroundColor = UIColor.white
        self.middleView?.backgroundColor = UIColor.white
        
        self.innerView?.layer.borderColor = UIColor.red.cgColor
        self.innerView?.backgroundColor = UIColor.red
        self.innerView?.alpha = 1.0
    }

    override var prefersStatusBarHidden: Bool {
        return true
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

    private func mergeVideoCamera() {
        let assets = self.fileUrls.compactMap { url in
            if (try? url.checkResourceIsReachable()) == true {
                return AVAsset(url: url)
            }
            return nil
        }

        let width = self.view.frame.width
        let height = self.view.frame.height - UIApplication.shared.statusBarFrame.height

        KVVideoManager.shared.mergeWithAnimation(arrayVideos: assets) { fileURL, error in
            guard let fileURL = fileURL else {
                print("Merge video error: \(error)")
                return
            }
            guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
                debugPrint("video.m4v not found")
                return
            }
            let url = URL(fileURLWithPath: path)
            DPVideoMerger().gridMergeVideos(
                withFileURLs: [url, fileURL],
                videoResolution: CGSize(width: width, height: height),
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
    }

}

extension AVAsset {
    func videoSize() -> CGSize {
        let tracks = self.tracks(withMediaType: AVMediaType.video)
        if (tracks.count > 0){
            let videoTrack = tracks[0]
            let size = videoTrack.naturalSize
            let txf = videoTrack.preferredTransform
            let realVidSize = size.applying(txf)
            print(videoTrack)
            print(txf)
            print(size)
            print(realVidSize)
            return realVidSize
        }
        return CGSize(width: 0, height: 0)
    }
}
