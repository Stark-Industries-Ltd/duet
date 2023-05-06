//
//  AudioRecorder.swift
//  duet
//
//  Created by HauTran on 04/05/2023.
//

import Foundation
import AVFAudio
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private let audioEngine = AVAudioEngine()
    var audioRecorder: AVAudioRecorder?
    var audioFilename: URL?

    override init() {
        super.init()
        self.audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.aac")

        AudioRecorder.setAudio()
        if #available(iOS 13.0, *) {
            setAudioEngine()
        }
    }

    @available(iOS 13.0, *)
    func setAudioEngine(){
        do {
            let audioInput = audioEngine.inputNode
            audioInput.isVoiceProcessingBypassed = true
            try audioInput.setVoiceProcessingEnabled(true)
            let audioFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.connect(audioInput, to: audioEngine.mainMixerNode, format:audioFormat)
        } catch {
            print("Could not enable voice processing \(error)")
            return
        }
    }

    static func setAudio(){
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try session.setActive(true)
        } catch let error {
            print("<< session \(error)")
        }
    }

    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 64000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            print("AUDIO RECORDER <<<<< \(error)")
        }
    }

    func finishRecording(_ completion: @escaping((URL) -> Void)) {
        audioRecorder?.stop()
        audioRecorder = nil
        if let audioFilename = audioFilename {
            completion(audioFilename)
        }
    }
}
