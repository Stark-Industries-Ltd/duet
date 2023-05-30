import Flutter
import UIKit

enum DuetType: String {
    case recordDuet  = "RECORD_DUET"
    case pauseDuet   = "PAUSE_DUET"
    case resumeDuet  = "RESUME_DUET"
    case resetDuet   = "RESET_DUET"
    case recordAudio = "RECORD_AUDIO"
    case pauseAudio  = "PAUSE_AUDIO"
    case startCamera  = "START_CAMERA"
    case stopCamera  = "STOP_CAMERA"
    case resetCamera  = "RESET_CAMERA"
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
        case DuetType.resetDuet.rawValue:
            FLNativeView.controller?.resetRecoding()
        case DuetType.recordAudio.rawValue:
            FLNativeView.controller?.startRecordingAudio()
        case DuetType.pauseAudio.rawValue:
            FLNativeView.controller?.pauseRecordingAudio()
        case DuetType.startCamera.rawValue:
            FLNativeView.controller?.startCamera()
        case DuetType.stopCamera.rawValue:
            FLNativeView.controller?.stopCamera()
        case DuetType.resetCamera.rawValue:
            FLNativeView.controller?.resetCamera()
        case DuetType.playSound.rawValue:
            FLNativeView.controller?.playSound(url: (call.arguments as? String) ?? "")
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
