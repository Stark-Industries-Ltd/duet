////
////  AudioRecorderManager.swift
////  duet
////
////  Created by DucManh on 11/05/2023.
////
//
//import Foundation
//import AVFAudio
//
//class AudioRecorderManager: NSObject, AVAudioRecorderDelegate {
//
//    static let shared = AudioRecorderManager()
//    private let audioEngine = AVAudioEngine()
//    var audioRecorder: AVAudioRecorder?
//    private var numberItem = 0
//
//    private var audioUrlItem: URL {
//        return URL.documents.appendingPathComponent("recording\(numberItem).aac")
//    }
//
//    let settings = [
//        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//        AVSampleRateKey: 44100,
//        AVEncoderBitRateKey: 64000,
//        AVNumberOfChannelsKey: 1,
//        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//    ]
//
//    override init() {
//        super.init()
//        AudioRecorder.setAudio()
//        setAudioEngine()
//    }
//
//    func setAudioEngine() {
//        do {
//            let audioInput = audioEngine.inputNode
//            if #available(iOS 13.0, *) {
//                audioInput.isVoiceProcessingBypassed = true
//                try audioInput.setVoiceProcessingEnabled(true)
//            } else {
//                // Fallback on earlier versions
//            }
//            let audioFormat = audioEngine.inputNode.outputFormat(forBus: 0)
//            audioEngine.connect(audioInput, to: audioEngine.mainMixerNode, format:audioFormat)
//        } catch {
//            print("Could not enable voice processing \(error)")
//            return
//        }
//    }
//
//    func startRecording() {
//        numberItem += 1
//        do {
//            audioRecorder = try AVAudioRecorder(url: audioUrlItem, settings: settings)
//            audioRecorder?.delegate = self
//            audioRecorder?.record()
//        } catch let error {
//            print("AUDIO RECORDER <<<<< \(error)")
//        }
//    }
//
//    func finishRecording(_ completion: @escaping((URL) -> Void)) {
//        audioRecorder?.stop()
//        audioRecorder = nil
//        completion(audioUrlItem)
//    }
//
//    func resetAudio() {
//        audioRecorder?.stop()
//        audioRecorder = nil
//    }
//}
