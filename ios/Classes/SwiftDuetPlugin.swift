import Flutter
import UIKit

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
        case "RECORD":
            FLNativeView.controller?.startRecording()
            result("RECORD result from native")
            break
        case "PAUSE":
            FLNativeView.controller?.pauseRecording()
            result("RECORD result from native")
            break
        case "RESUME":
            FLNativeView.controller?.resumeRecording()
            result("RECORD result from native")
            break
        case "RESET":
            result("RESET result from native")
            FLNativeView.controller?.resetRecoding()
            break
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
}
