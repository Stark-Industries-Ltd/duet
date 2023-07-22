import Flutter
import UIKit

enum DuetType: String {
    case recordDuet  = "RECORD_DUET"
    case pauseDuet   = "PAUSE_DUET"
    case resumeDuet  = "RESUME_DUET"
    case recordAudio = "RECORD_AUDIO"
    case pauseAudio  = "PAUSE_AUDIO"
    case playSound  = "PLAY_SOUND"
    case saveVideoToAlbum = "SAVE_VIDEO_TO_ALBUM"
    case merge = "MERGE"
}

@available(iOS 10.0, *)
public class SwiftDuetPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?
    static var registrar: FlutterPluginRegistrar?

    public static func register(with registrar: FlutterPluginRegistrar) {

        let factory = FLNativeViewFactory(messenger: registrar.messenger())

        registrar.register(factory, withId: "<platform-view-type>")

        self.channel = FlutterMethodChannel(name: "duet", binaryMessenger: registrar.messenger())
        self.registrar = registrar
        registrar.addMethodCallDelegate(SwiftDuetPlugin(), channel: channel!)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print(call.method)
        switch(call.method){
        case DuetType.recordDuet.rawValue:
            FLNativeView.controller?.startRecording()
            result("")
        case DuetType.pauseDuet.rawValue:
            FLNativeView.controller?.pauseRecording()
            result("")
        case DuetType.resumeDuet.rawValue:
            FLNativeView.controller?.resumeRecording()
            result("")
        case DuetType.recordAudio.rawValue:
            FLNativeView.controller?.startRecordingAudio()
            result("")
        case DuetType.pauseAudio.rawValue:
            FLNativeView.controller?.pauseRecordingAudio()
            result("")
        case DuetType.playSound.rawValue:
            let url = (call.arguments as? String) ?? ""
            FLNativeView.controller?.playSound(url: url, result: result)
        case DuetType.saveVideoToAlbum.rawValue:
            let path = (call.arguments as? String) ?? ""
            FLNativeView.controller?.saveVideoToAlbum(path: path, result: result)
        case DuetType.merge.rawValue:
            do{
                let a = (call.arguments as? String)!.split(separator: "|")
                print(a)
                let origin = String(a[0])
                let user = String(a[1])
                var originUrl: URL? {
                    return origin.starts(with: "http") ? URL(string: origin) : URL(fileURLWithPath: origin)
                }
                var userUrl: URL? {
                    return user.starts(with: "http") ? URL(string: user) : URL(fileURLWithPath: user)
                }
                DPVideoMerger().gridMergeVideos(
                    duetViewArgs: DuetViewArgs(url: "String",
                                               image: "String",
                                               userName: "String",
                                               userId: 1,
                                               classId: 1,
                                               lessonId: 1),
                    videoFileURLs: [originUrl!, userUrl!],
                    videoResolution: CGSize(width: 810, height: 720),
                    completion: { mergedVideoFile, error in
                        if let error = error {
                            SwiftDuetPlugin.notifyFlutter(event: .VIDEO_ERROR, arguments: "\(error)")
                        }

                        guard let mergedVideoFile = mergedVideoFile else {
                            return
                        }
                        SwiftDuetPlugin.notifyFlutter(event: .VIDEO_MERGED, arguments: mergedVideoFile.path)
                    }
                )
            }
            
        default:
            result("iOS " + UIDevice.current.systemVersion)
        }
    }

    public static func notifyFlutter(event: EventType, arguments: Any?) {
        SwiftDuetPlugin.channel?.invokeMethod(event.rawValue, arguments: arguments)
    }
}

public enum EventType: String {
    case AUDIO_RESULT
    case VIDEO_RECORDED
    case VIDEO_MERGED
    case VIDEO_TIMER
    case VIDEO_ERROR
}
