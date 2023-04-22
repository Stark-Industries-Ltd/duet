import Flutter
import UIKit

@available(iOS 10.0, *)
public class SwiftDuetPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {

    let factory = FLNativeViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "<platform-view-type>")

    let channel = FlutterMethodChannel(name: "duet", binaryMessenger: registrar.messenger())
    let instance = SwiftDuetPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
