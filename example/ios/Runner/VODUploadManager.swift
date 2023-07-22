//
//  VODUploadManager.swift
//  Runner
//
//  Created by DucManh on 12/05/2023.
//

import Foundation
import Photos

class VODUploadManager {
    static let shared = VODUploadManager()
    private let client = VODUploadClient()
    private var vodModel: VODModel?

    init() {
        setListener()
    }

    private func setListener() {
        let finishCallbackFunc: OnUploadFinishedListener = { (fileInfo, result) in
            guard var vodModel = self.vodModel else {
                return
            }
            vodModel.pathUpload = fileInfo?.object
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(vodModel)
                let json = String(data: jsonData, encoding: String.Encoding.utf8)
                VODClientPlugin.notifyFlutter(event: "SUCCESS", arguments: json)
            } catch {
                print(error)
            }
        }
        let failedCallbackFunc: OnUploadFailedListener = { (fileInfo, code, message) in
            let error = "Upload Video Error code \(code ?? "") \(message ?? "")"
            VODClientPlugin.notifyFlutter(event: "ERROR", arguments: error)
        }
        let progressCallbackFunc: OnUploadProgressListener = { (fileInfo, uploadedSize, totalSize) in
            //             print("upload progress callback.")
            VODClientPlugin.notifyFlutter(event: "PROGRESS", arguments: "\(uploadedSize)|\(totalSize)")
        }

        let tokenExpiredCallbackFunc: OnUploadTokenExpiredListener = {
            print("upload token expired callback.")
        }
        let retryCallbackFunc: OnUploadRertyListener = {
            print("upload retry begin callback.")
        }
        let retryResumeCallbackFunc: OnUploadRertyResumeListener = {
            print("upload retry end callback.")
        }
        let uploadStartedCallbackFunc: OnUploadStartedListener  = { [weak self] fileInfo in
            guard let self = self else { return }
            print("upload upload started callback.")
            self.client.setUploadAuthAndAddress(fileInfo,
                                                uploadAuth: self.vodModel?.uploadAuth,
                                                uploadAddress: self.vodModel?.uploadAddress)
        }
        let listener = VODUploadListener()
        listener.finish = finishCallbackFunc
        listener.failure = failedCallbackFunc
        listener.progress = progressCallbackFunc
        listener.expire = tokenExpiredCallbackFunc
        listener.retry = retryCallbackFunc
        listener.retryResume = retryResumeCallbackFunc
        listener.started = uploadStartedCallbackFunc
        client.setListener(listener)
    }

    func uploadFile(vodModel: VODModel) {
        guard !vodModel.uploadAuth.isEmpty,
              !vodModel.uploadAddress.isEmpty else {
            let error = "Upload Video Error code uploadAuth null uploadAddress null"
            VODClientPlugin.notifyFlutter(event: "ERROR", arguments: error)
            return
        }
        self.vodModel = vodModel
        let path = URL(fileURLWithPath: vodModel.pathVideo)
        let vodInfo = VodInfo()
        vodInfo.title = vodModel.fileName
        vodInfo.cateId = 19
        self.client.addFile(path.path, vodInfo: vodInfo)
        self.client.start()
    }
}
