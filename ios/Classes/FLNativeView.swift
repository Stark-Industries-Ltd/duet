import Flutter
import UIKit

@available(iOS 10.0, *)
class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
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
            binaryMessenger: messenger)
    }
}

@available(iOS 10.0, *)
class FLNativeView: NSObject, FlutterPlatformView {
//    private var _view: UIView
    private var _vc: CameraViewController

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
//         _view = UIView()
//        _vc = CameraViewController()

        let storyboard = UIStoryboard.init(name: "Camera", bundle: Bundle.init(for: CameraViewController.self))
        let controller = storyboard.instantiateViewController(withIdentifier: "CameraID") as! CameraViewController
        _vc = controller

        super.init()
        // iOS views can be created here
//        createNativeView(view: _view)
//        createNativeView(view: _vc.view)
    }

    func view() -> UIView {
        return _vc.view
//         return _view
    }

//    func createNativeView(view _view: UIView){
//        _view.backgroundColor = UIColor.blue
//        let nativeLabel = UILabel()
//        nativeLabel.text = "Native text from iOS"
//        nativeLabel.textColor = UIColor.white
//        nativeLabel.textAlignment = .center
//        nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
//        _view.addSubview(nativeLabel)
//    }
}
