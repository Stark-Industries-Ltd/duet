import Flutter
import AVFoundation
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
    var controller: UIViewController?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        var viewArgs: DuetViewArgs?
        let arguments = args as? [String: Any]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: arguments ?? [:], options: [])
            viewArgs = try JSONDecoder().decode(DuetViewArgs.self, from: jsonData)
        } catch {
            let message = "FLNativeView init \(error)"
            print(message)
            if #available(iOS 13.0, *) {
                SwiftDuetPlugin.notifyFlutter(event: .ALERT, arguments: message)
            } else {
                // Fallback on earlier versions
            }
        }
        
        if #available(iOS 13.0, *) {
            let storyboard = UIStoryboard.init(name: "Camera", bundle: Bundle.init(for: CameraViewController.self))
            let controller = storyboard.instantiateViewController(withIdentifier: "CameraID") as! CameraViewController
            controller.viewArgs = viewArgs
            self.controller = controller
        } else {
            // Fallback on earlier versions
        }
        
        
        super.init()
    }

    func view() -> UIView {
        if #available(iOS 13.0, *) {
            return controller!.view
        } else {
            return UIView()
        }
    }
}

struct DuetViewArgs: Codable {
    var url: String
    var image: String
    var userName: String
    var userId: Int
    var classId: Int
    var lessonId: Int

    private enum CodingKeys : String, CodingKey {
        case url = "url"
        case image = "image"
        case userName = "user_name"
        case userId = "user_id"
        case classId = "class_id"
        case lessonId = "lesson_id"
    }

    init(url: String,
         image: String,
         userName: String,
         userId: Int,
         classId: Int,
         lessonId: Int) {
        self.url = url
        self.image = image
        self.userName = userName
        self.userId = userId
        self.classId = classId
        self.lessonId = lessonId
    }

    var urlVideo: URL? {
        return url.starts(with: "http") ? URL(string: url) : URL(fileURLWithPath: url)
    }
}
