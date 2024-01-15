//
//  NetworkManager.swift
//  healthcare
//
//  Created by MB-0037 on 2023/08/04.
//

import Foundation
import Alamofire
import KakaoSDKUser

enum ServerDirection {
    case development
    case production
}

final class NetworkManager {
    static let shared: NetworkManager = NetworkManager()
    
    private let currentServer: ServerDirection
    private let reachabilityManager = NetworkReachabilityManager()
    private let manager: Session
    private var status: NetworkReachabilityManager.NetworkReachabilityStatus = NetworkReachabilityManager.NetworkReachabilityStatus.notReachable
    let timeoutInterval: TimeInterval = 20

    private init() {
        currentServer = .development
        
        let timeoutInterval: TimeInterval = timeoutInterval
        let httpMaximumConnectionsPerHost: Int = 3
        
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        manager = Session(configuration: configuration)
        
        reachabilityManager?.startListening { (status) in
            self.status = status
        }
    }

    private var baseURL: String {
        return NetworkConfig.apiURL
    }
    
    
    var isReachable: Bool {
        return reachabilityManager?.isReachable ?? false
    }
    
    private func addHeaders(headers: HTTPHeaders? = nil) -> HTTPHeaders {
        var newHeaders = headers != nil ? headers! : HTTPHeaders()
        newHeaders.add(name: "Accept", value: "application/json")
        newHeaders.add(name: "Content-Type", value: "application/json")
        return newHeaders
    }
    
    private func get<T: Codable> (_ path: String, responseType: T.Type, parameters: Parameters? = nil, headers: HTTPHeaders? = nil, encoding: ParameterEncoding = URLEncoding.default) async throws -> T {
        let newHeaders: HTTPHeaders = addHeaders(headers: headers)
        
        Logger.log("\nMethod: GET\npath: \(path)\nheader: \(newHeaders)\nparams: \(String(describing: parameters))")
        do {
            self.addIndicator()
            let get = manager.request(path, method: .get, parameters: parameters, encoding: encoding, headers: newHeaders)
                        .validate(statusCode: 200..<300)
//                .serializingDecodable(responseType)
//                .value
            self.removeIndicator()
            let dataString = get.serializingString()
            let stringValue = try await dataString.value
            Logger.log("result String\n======\n\(stringValue)\n------")
            
            let dataTask = get.serializingDecodable(responseType.self)
            let response = await dataTask.response
            let result = await dataTask.result
            Logger.log("response \(String(describing: response.response?.allHeaderFields))")
            Logger.log("response \(result)")
            
            let value = try await dataTask.value
            
            let data = try? JSONEncoder().encode(value)
            Logger.log("\(String(describing: data))")
            
            return value
        } catch let error {
            Logger.log("error - \(String(describing: error.localizedDescription))")

            guard let afError = error as? AFError else {
                throw error
            }
            
            DispatchQueue.main.async {
                CommonUtil.getSceneDelegate()?.showAlert(title: "네트워크 에러(\(String(describing: afError.responseCode)))", message: afError.localizedDescription, handler: nil)
            }
            Logger.log("error - \(String(describing: afError.localizedDescription))")
            throw afError
        }
    }
    
    private func post<T: Codable>(_ path: String, responseType: T.Type, parameters: Parameters? = nil, headers: HTTPHeaders? = nil, encoding: ParameterEncoding = JSONEncoding.default) async throws -> T {
        let newHeaders: HTTPHeaders = addHeaders(headers: headers)

        Logger.log("\nMethod: POST\npath: \(path)\nheader: \(newHeaders)\nparams: \(String(describing: parameters))")
        
        do {
            self.addIndicator()

            let post = manager.request(path, method: .post, parameters: parameters, encoding: encoding, headers: newHeaders)
            self.removeIndicator()
            let dataString = post.serializingString()
            let stringValue = try await dataString.value
            Logger.log("result String\n======\n\(stringValue)\n------")
            
            let dataTask = post.serializingDecodable(responseType.self)
            let response = await dataTask.response
            let result = await dataTask.result
            Logger.log("response \(String(describing: response.response?.allHeaderFields))")
            Logger.log("response \(result)")
            
            let value = try await dataTask.value
            
            let encoder = JSONEncoder()
            
            if let data = try? encoder.encode(value),
               let jsonString = String(data: data, encoding: .utf8) {
                Logger.log("\(jsonString)")
            }
            
            return value
        } catch let error {
            Logger.log("error - \(String(describing: error.localizedDescription))")

            guard let afError = error as? AFError else {
                throw error
            }
            
            DispatchQueue.main.async {
                CommonUtil.getSceneDelegate()?.showAlert(title: "네트워크 에러(\(String(describing: afError.responseCode)))", message: afError.localizedDescription, handler: nil)
            }
            
            Logger.log("error - \(String(describing: afError.localizedDescription))")
            throw afError
        }
    }
    
    private func put<T: Codable>(_ path: String, responseType: T.Type, parameters: Parameters? = nil, headers: HTTPHeaders? = nil, encoding: ParameterEncoding = JSONEncoding.default) async throws -> T {
        let newHeaders: HTTPHeaders = addHeaders(headers: headers)
        

        let value =  try await manager.request(path, method: .put, parameters: parameters, encoding: encoding, headers: newHeaders)
//            .validate(statusCode: 200..<300)
            .serializingDecodable(responseType)
            .value
        
        let data = try? JSONEncoder().encode(value)
        Logger.log("\(String(describing: data))")
        
        return value
    }
    
    private func delete<T: Codable>(_ path: String, responseType: T.Type, parameters: Parameters? = nil, headers: HTTPHeaders? = nil, encoding: ParameterEncoding = URLEncoding.default) async throws -> T {
        let newHeaders: HTTPHeaders = addHeaders(headers: headers)

        let value =  try await manager.request(path, method: .delete, parameters: parameters, encoding: encoding, headers: newHeaders)
//            .validate(statusCode: 200..<300)
            .serializingDecodable(responseType)
            .value
        
        let data = try? JSONEncoder().encode(value)
        Logger.log("\(String(describing: data))")
        
        return value
    }
    
    private func upload<T: Codable>(_ path: String, imageName: String, imageData: Data, responseType: T.Type, parameters: Parameters? = nil, headers: HTTPHeaders? = nil, encoding: ParameterEncoding = JSONEncoding.default) async throws -> T {
        var newHeaders: HTTPHeaders = addHeaders(headers: headers)
        newHeaders.update(name: "Content-Type", value: "multipart/form-data; boundaryBoundary-\(UUID().uuidString)")
        
        let formData: (MultipartFormData) -> Void = { multiPart in
            if let parameters = parameters {
                for param in parameters {
                    if let temp = param.value as? String {
                        multiPart.append(temp.data(using: .utf8)!, withName: param.key)
                    }
                    if let temp = param.value as? Int {
                        multiPart.append("\(temp)".data(using: .utf8)!, withName: param.key)
                    }
                    if let temp = param.value as? NSArray {
                        temp.forEach({ element in
                            let keyObj = param.key + "[]"
                            if let string = element as? String {
                                multiPart.append(string.data(using: .utf8)!, withName: keyObj)
                            } else
                            if let num = element as? Int {
                                let value = "\(num)"
                                multiPart.append(value.data(using: .utf8)!, withName: keyObj)
                            }
                        })
                    }
                }
            }
            multiPart.append(imageData, withName: "file", fileName: "\(imageName).jpg", mimeType: "image/jpg")
        }
        Logger.log("\nMethod: POST(upload)\npath: \(path)\nheader: \(newHeaders)\nparams: \(String(describing: parameters))\nformData \(formData), \nimagedata : \(imageData.count)")
        do {
            self.addIndicator()

            let upload = manager.upload(multipartFormData: formData, to: path, method: .post, headers: newHeaders)
            Task {
                for await progress in upload.uploadProgress() {
                    debugPrint(progress)
                }
            }
            
            let dataString = upload.serializingString()
            let stringValue = try await dataString.value
            Logger.log("result String\n======\n\(stringValue)\n------")
            
            let dataTask = upload.serializingDecodable(responseType)
            self.removeIndicator()
            
            let response = await dataTask.response
            let result = await dataTask.result
            Logger.log("response \(String(describing: response.response?.allHeaderFields))")
            Logger.log("result = \(result)")
            let value = try await dataTask.value
            
            let encoder = JSONEncoder()
            
            if let data = try? encoder.encode(value),
               let jsonString = String(data: data, encoding: .utf8) {
                Logger.log("\(jsonString)")
            }
            
            return value
            
        } catch let error {
            guard let afError = error as? AFError else {
                throw error
            }
            DispatchQueue.main.async {
                CommonUtil.getSceneDelegate()?.showAlert(title: "네트워크 에러(\(afError.responseCode))", message: afError.localizedDescription, handler: nil)
            }
            throw afError
        }
    }
    
    func requestData(_ path: String) async throws -> Data {
        return try await manager.request(path).serializingData().value
    }
    
    func addIndicator () {
        DispatchQueue.main.async {
            (CommonUtil.getSceneDelegate())?.addActivityIndicatorView(text: nil)
        }
    }
    
    func removeIndicator () {
        DispatchQueue.main.async {
            (CommonUtil.getSceneDelegate())?.removeActivityIndicatorView()
        }
    }
}
