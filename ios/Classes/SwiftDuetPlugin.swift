import Flutter
import UIKit

@available(iOS 10.0, *)
public class SwiftDuetPlugin: NSObject, FlutterPlugin {
  static var channel: FlutterMethodChannel?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
      
      let factory = FLNativeViewFactory(messenger: registrar.messenger())
      
      registrar.register(factory, withId: "<platform-view-type>")
      
      self.channel = FlutterMethodChannel(name: "duet", binaryMessenger: registrar.messenger())
      let instance = SwiftDuetPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel!)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      print(call.method)
      
      switch(call.method){
      case "RECORD":
          result("RECORD result from native")
//          FLNativeView.controller?.record()
          break
      case "RESET":
          result("RESET result from native")
          break
      default:
        result("iOS " + UIDevice.current.systemVersion)
      }
  }
    
    public static func notifyFlutter(event: EventType, arguments: Any?){
        SwiftDuetPlugin.channel?.invokeMethod(event.rawValue, arguments: arguments)
    }
}

public enum EventType: String {
    case AUDIO_RESULT
    case VIDEO_RECORDED
    case VIDEO_MERGED
}
