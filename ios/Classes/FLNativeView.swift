import Flutter
import UIKit

@available(iOS 10.0, *)
class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
              return FlutterStandardMessageCodec.sharedInstance()
        }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
}

@available(iOS 10.0, *)
class FLNativeView: NSObject, FlutterPlatformView {
    static var controller: CameraViewController?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        var viewArgs: DuetViewArgs?
        if let data = args as? [String: Any] {
            viewArgs = DuetViewArgs(data: data)
        }
        
        let storyboard = UIStoryboard.init(name: "Camera", bundle: Bundle.init(for: CameraViewController.self))
        let controller = storyboard.instantiateViewController(withIdentifier: "CameraID") as! CameraViewController
        
        controller.viewArgs = viewArgs
        FLNativeView.controller = controller
        
        super.init()
    }

    func view() -> UIView {
        return FLNativeView.controller!.view
    }
}

struct DuetViewArgs {

    var urlVideo: URL?
    var image: String
    var lessonId: Int
    var userId: Int

    init(data: [String: Any]) {
        let _url = (data["url"] as? String) ?? ""
        self.urlVideo = _url.starts(with: "http") ? URL(string: _url) : URL(fileURLWithPath: _url)
        self.image = (data["image"] as? String) ?? ""
        self.lessonId = (data["lesson_id"] as? Int) ?? 0
        self.userId = (data["user_id"] as? Int) ?? 0
    }
}
