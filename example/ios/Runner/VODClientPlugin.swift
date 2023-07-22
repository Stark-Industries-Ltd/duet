//
//  VODClientPlugin.swift
//  Runner
//
//  Created by DucManh on 13/05/2023.
//

import AVFoundation
import Flutter

typealias Codable = Decodable & Encodable

struct VODModel: Codable {
    let lessonId: Int
    let sectionId: Int
    let videoId: String
    let fileName: String
    let uploadAuth: String
    let uploadAddress: String
    let pathVideo: String
    var pathUpload: String?

    private enum CodingKeys : String, CodingKey {
        case lessonId = "lesson_id"
        case sectionId = "section_id"
        case videoId = "video_id"
        case fileName = "file_name"
        case uploadAuth = "upload_auth"
        case uploadAddress = "upload_address"
        case pathVideo = "path_video"
        case pathUpload = "path_upload"
    }

    init(lessonId: Int,
         sectionId: Int,
         videoId: String,
         fileName: String,
         uploadAuth: String,
         uploadAddress: String,
         pathVideo: String) {
        self.lessonId = lessonId
        self.sectionId = sectionId
        self.videoId = videoId
        self.fileName = fileName
        self.uploadAuth = uploadAuth
        self.uploadAddress = uploadAddress
        self.pathVideo = pathVideo
    }
}

class VODClientPlugin {

    static var channel: FlutterMethodChannel?

    static func initChannel(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.vod.client", binaryMessenger: messenger)
        channel?.setMethodCallHandler({(call: FlutterMethodCall,
                                       result: @escaping FlutterResult) -> Void in

            // Note: this method is invoked on the UI thread.
            let arguments = call.arguments as? [String: AnyObject]

            if call.method == "UPLOAD" {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: arguments ?? [:], options: [])
                    let vodModel = try JSONDecoder().decode(VODModel.self, from: jsonData)
                    VODUploadManager.shared.uploadFile(vodModel: vodModel)
                } catch {
                    print(error)
                }
            }
        })
    }

    static func notifyFlutter(event: String, arguments: Any?) {
        channel?.invokeMethod(event, arguments: arguments)
    }
}
