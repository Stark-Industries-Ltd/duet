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

    override init() {
        super.init()

        setAudio()
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
            let message = "Could not enable voice processing \(error)"
            print(message)
            SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: message)
            return
        }
    }

    func setAudio() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try session.setActive(true)
        } catch let error {
            let message = "<< Set audio session error: \(error)"
            print(message)
            SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: message)
        }
    }

}
