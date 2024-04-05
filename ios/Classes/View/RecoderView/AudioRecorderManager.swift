//
//  AudioRecorderManager.swift
//  duet
//
//  Created by DucManh on 11/05/2023.
//

import Foundation
import AVFAudio

class AudioRecorderManager: NSObject, AVAudioRecorderDelegate {

    static let shared = AudioRecorderManager()
    var audioRecorder: AVAudioRecorder?

    private let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVEncoderBitRateKey: 64000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    private var audioUrlItem: URL {
        return URL.documents.appendingPathComponent("recording.aac")
    }

    override init() {
        super.init()
        setAudio()
    }

    func initAudio() {}

    private func setAudio() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers, .interruptSpokenAudioAndMixWithOthers, .duckOthers])
//             try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try session.setActive(true)
        } catch let error {
            let message = "AudioRecorderManager session \(error)"
            print(message)
            SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: message)
        }
    }

    func startRecording() {
        guard audioRecorder == nil else {
            audioRecorder?.record()
            return
        }
        do {
            audioRecorder = try AVAudioRecorder(url: audioUrlItem, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            let message = "AUDIO RECORDER <<<<< \(error)"
            print(message)
            SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: message)
        }
    }

    func pauseRecording() {
        audioRecorder?.pause()
    }

    func finishRecording(_ completion: @escaping((URL) -> Void)) {
        audioRecorder?.stop()
        audioRecorder = nil
        completion(audioUrlItem)
    }

    func resetAudio() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
}
