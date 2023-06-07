import Flutter
import UIKit

enum DuetType: String {
    case recordDuet  = "RECORD_DUET"
    case pauseDuet   = "PAUSE_DUET"
    case resumeDuet  = "RESUME_DUET"
    case recordAudio = "RECORD_AUDIO"
    case pauseAudio  = "PAUSE_AUDIO"
    case playSound  = "PLAY_SOUND"
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
        case DuetType.pauseDuet.rawValue:
            FLNativeView.controller?.pauseRecording()
        case DuetType.resumeDuet.rawValue:
            FLNativeView.controller?.resumeRecording()
        case DuetType.recordAudio.rawValue:
            FLNativeView.controller?.startRecordingAudio()
        case DuetType.pauseAudio.rawValue:
            FLNativeView.controller?.pauseRecordingAudio()
        case DuetType.playSound.rawValue:
            if let arguments = call.arguments as? [String: AnyObject] {
                FLNativeView.controller?.playSound(args: arguments)
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
}
