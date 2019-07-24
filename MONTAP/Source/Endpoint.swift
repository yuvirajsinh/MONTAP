//
//  Endpoint.swift
//  MTNetworking
//
//  Created by Yuvrajsinh Jadeja on 05/04/19.
//  Copyright © 2019 Moneytap. All rights reserved.
//

import Alamofire

public protocol Endpoint {
    //var baseURL: String { get } // https://example.com
    var path: String { get } // /users/
    //var fullURL: String { get } // This will automatically be set. https://example.com/users/
    var method: HTTPMethod { get } // .get
    var encoding: ParameterEncoding { get } // URLEncoding.default
    var queryParams: Parameters { get } // Used as query parameters ["foo" : "bar"]
    var body: Parameters { get } // Used as body parameters ["foo" : "bar"]
    var bodyArray: [Any] { get } // Used as body array parameters [["foo": "bar"]]
    var headers: HTTPHeaders { get } // ["Authorization" : "Bearer SOME_TOKEN"]
}

public extension Endpoint {
    // The encoding's are set up so that all GET requests parameters
    // will default to be url encoded and everything else to be json encoded
    var encoding: ParameterEncoding {
        return method == .get ? URLEncoding.default : JSONEncoding.default
    }
    
    // Should always be the same no matter what
//    var fullURL: String {
//        return baseURL + path
//    }
    
    var queryParams: Parameters {
        return Parameters()
    }
    
    // A lot of requests don't require parameters
    // so we just set them to be empty
    var body: Parameters {
        return Parameters()
    }
    
    // A lot of requests don't require body as Array
    // so we just set them to be empty
    var bodyArray: [Any] {
        return [Any]()
    }
}
