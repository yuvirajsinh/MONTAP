//
//  Buco.swift
//  MTNetworking
//
//  Created by Yuvrajsinh Jadeja on 05/04/19.
//  Copyright © 2019 Moneytap. All rights reserved.
//

import Alamofire
import AlamofireObjectMapper
import ObjectMapper

public class MONTAP {
    public static let shared = MONTAP()
    // You can set this to a var if you want
    // to be able to create your own SessionManager
    let manager: SessionManager = SessionManager()
    //static let shared = Bucko()
    private var baseURL: String?
    
    public var adapter: RequestAdapter? {
        didSet {
            manager.adapter = adapter
        }
    }
    
    public var retrier: RequestRetrier? {
        didSet {
            manager.retrier = retrier
        }
    }
    
    private init() {
        
    }
    
    public func setBaseURL(_ url: String) {
        baseURL = url
    }
}

public extension MONTAP {
    func request<Model: Mappable, ErrorModel: Mappable>(responseType: Model.Type, errorType: ErrorModel.Type, endpoint: Endpoint, success: @escaping (Model) -> Void, failure: @escaping (ErrorModel) -> Void) -> DataRequest? {
        
        guard let url = buildURL(with: endpoint) else {
            let fullURL = baseURL ?? "" + endpoint.path
            let error = AFError.invalidURL(url: fullURL)
            failure(errorToObject(errorType: errorType, error: error))
            return nil
        }
        
        let request = manager.request(url, method: endpoint.method, parameters: endpoint.body, encoding: endpoint.encoding, headers: endpoint.headers)
        debugPrint("==========> START")
        debugPrint(request)
        debugPrint("==========> END")
        request.validate(statusCode: 200..<300)
        .responseString { (response: DataResponse<String>) in
            debugPrint("<========== START")
            debugPrint(response)
            debugPrint("<========== END")
        }
        .responseObject { (response: DataResponse<Model>) in
            if response.result.isSuccess, let value = response.result.value {
                success(value)
            }
            else if let data = response.data, var json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
                json["statusCode"] = response.response?.statusCode
                
                if let errorModel = ErrorModel(JSON: json) {
                    failure(errorModel)
                }
                else {
                    failure(ErrorModel(JSON: [:])!)
                }
            }
            else if let error = response.result.error {
                failure(self.errorToObject(errorType: errorType, error: error, statusCode: response.response?.statusCode))
            }
            else {
                failure(ErrorModel(JSON: [:])!)
            }
            
            
            //////////
            /*if response.result.isSuccess {
                if let responseCode = response.response?.statusCode, (200..<300).contains(responseCode) {
                    success(response.result.value!)
                }
                else if let data = response.data, var json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
                    json["statusCode"] = response.response?.statusCode
                    
                    if let errorModel = ErrorModel(JSON: json) {
                        failure(errorModel)
                    }
                    else {
                        failure(ErrorModel(JSON: [:])!)
                    }
                }
                else {
                    failure(ErrorModel(JSON: [:])!)
                }
            }
            else if let error = response.result.error {
                failure(self.errorToObject(error: error, statusCode: response.response?.statusCode))
            }
            else {
                failure(ErrorModel(JSON: [:])!)
            }*/
        }
        return request
    }
    
    func requestArray<Model: Mappable, ErrorModel: Mappable>(responseType: Model.Type, errorType: ErrorModel.Type, endpoint: Endpoint, success: @escaping (Model) -> Void, failure: @escaping (ErrorModel) -> Void) -> DataRequest? {
        
        guard let urlRequest = buildRequest(with: endpoint) else {
            let fullURL = baseURL ?? "" + endpoint.path
            let error = AFError.invalidURL(url: fullURL)
            failure(errorToObject(errorType: errorType, error: error))
            return nil
        }
        
        let request = manager.request(urlRequest)
        
        debugPrint("==========> START")
        debugPrint(request)
        debugPrint("==========> END")
        request.validate(statusCode: 200..<300)
            .responseString { (response: DataResponse<String>) in
                debugPrint("<========== START")
                debugPrint(response)
                debugPrint("<========== END")
            }
            .responseObject { (response: DataResponse<Model>) in
                if response.result.isSuccess, let value = response.result.value {
                    success(value)
                }
                else if let data = response.data, var json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
                    json["statusCode"] = response.response?.statusCode
                    
                    if let errorModel = ErrorModel(JSON: json) {
                        failure(errorModel)
                    }
                    else {
                        failure(ErrorModel(JSON: [:])!)
                    }
                }
                else if let error = response.result.error {
                    failure(self.errorToObject(errorType: errorType, error: error, statusCode: response.response?.statusCode))
                }
                else {
                    failure(ErrorModel(JSON: [:])!)
                }
        }
        return request
    }
    
    /*func upload(endpoint: Endpoint, image: UIImage, success: @escaping (Model) -> Void, failure: @escaping (ErrorModel) -> Void) {
        guard let request = buildRequest(with: endpoint) else { return }

        manager.upload(multipartFormData: { (multipartFormData) in
            // Append parameters to MultipartFormData
            if endpoint.body.count > 0 {
                do {
                    let paramData = try JSONSerialization.data(withJSONObject: endpoint.body, options: [])
                    multipartFormData.append(paramData, withName: "metadata")
                }
                catch {
                    failure(self.errorToObject(error: error))
                }
            }
            // Append image data to MultipartFormData
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                multipartFormData.append(imageData, withName: "file", fileName: "file.jpeg", mimeType: "image/jpeg")
            }
        },
        with: request,
        encodingCompletion: { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseObject(completionHandler: { (response: DataResponse<Model>) in
                    debugPrint(response)
                    guard let model = response.value else {
                        failure(ErrorModel(JSON: [:])!)
                        return
                    }
                    success(model)
                })
            case .failure(let encodingError):
               debugPrint(encodingError)
               failure(self.errorToObject(error: encodingError))
            }
        })
    }*/
}

extension MONTAP {
    private func buildURL(with endpoint: Endpoint) -> URL? {
        guard let baseURLStr = baseURL else { return nil }
        guard let baseURL = URL(string: baseURLStr) else { return nil }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else { return nil }
        components.path = components.path + endpoint.path
        // Create query parameters if HTTPMethod is GET OR DELETE
        if endpoint.queryParams.count > 0 {
            components.queryItems = endpoint.queryParams.map({ URLQueryItem(name: $0.key, value: String(describing: $0.value)) })
        }
        
        guard let url = components.url else { return nil }
        return url
    }
    
    private func buildRequest(with endpoint: Endpoint) -> URLRequest? {
        guard let baseURL = URL(string: baseURL!) else { return nil }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else { return nil }
        components.path = components.path + endpoint.path
        // Create query parameters if HTTPMethod is GET OR DELETE
        if endpoint.queryParams.count > 0 {
            components.queryItems = endpoint.queryParams.map({ URLQueryItem(name: $0.key, value: String(describing: $0.value)) })
        }
        
        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        for (header, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: header)
        }
        var httpBody: Any? = endpoint.body
        
        if endpoint.method == .post && endpoint.bodyArray.count > 0 {
            httpBody = endpoint.bodyArray
        }
        
        if let httpBody = httpBody {
            do {
                let bodyData = try JSONSerialization.data(withJSONObject: httpBody, options: [])
                request.httpBody = bodyData
            }
            catch {
                debugPrint(error)
            }
        }
        
        return request
    }
    
    func errorToObject<ErrorModel: Mappable>(errorType: ErrorModel.Type, error: Error, statusCode: Int? = nil) -> ErrorModel {
        
        let errorObj = ErrorModel(JSON: error.JSON(statusCode: statusCode))
        
        return errorObj!
    }
}

// MARK: - Error extension to convert Error to map [String: Any]
extension Error {
    func JSON(statusCode: Int?) -> [String: Any] {
        let nsError = self as NSError
        
        var JSON = [String: Any]()
        JSON["error"] = nsError.localizedFailureReason
        JSON["error_description"] = nsError.localizedDescription
        JSON["status"] = nsError.code
        if let code = statusCode {
            JSON["statusCode"] = code
        }
        
        return JSON
    }
}
