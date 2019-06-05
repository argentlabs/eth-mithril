//
//  Request.swift
//  web3swift
//
//  Created by Dmitry on 14/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit

enum JsonRpcError: Error {
    case syntaxError(code: Int, message: String)
    case responseError(code: Int, message: String)
    var localizedDescription: String {
        switch self {
        case let .syntaxError(code: code, message: message):
            return "Json rpc syntax error: \(message) (\(code))"
        case let .responseError(code: code, message: message):
            return "Request failed: \(message) (\(code))"
        }
    }
}

/// Work in progress. Will be released in 2.2
open class Request {
    public var id = Counter.increment()
    public var method: String
    public var promise: Promise<AnyReader>
    public var resolver: Resolver<AnyReader>
    
    public init(method: String) {
        self.method = method
        (promise,resolver) = Promise.pending()
    }
    
    open func response(data: AnyReader) throws {
        
    }
    open func failed(error: Error) {
        
    }
    open func request() -> [Any] {
        return []
    }
    
    open func requestBody() -> Any {
        var dictionary = [String: Any]()
        dictionary["jsonrpc"] = "2.0"
        dictionary["method"] = method
        dictionary["id"] = id
        dictionary["params"] = request()
        return dictionary
    }
    
    open func request(url: URL) throws -> URLRequest {
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        let body = requestBody()
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        return urlRequest
    }
    
    open func checkJsonRpcSyntax(data: AnyReader) throws {
        try data.at("jsonrpc").string().starts(with: "2.")
        if let error = try? data.at("error") {
            let code = try error.at("code").int()
            let message = try error.at("message").string()
            if data.contains("id") {
                throw JsonRpcError.responseError(code: code, message: message)
            } else {
                throw JsonRpcError.syntaxError(code: code, message: message)
            }
        } else {
            try data.at("id").int()
        }
    }
    open func _response(data: AnyReader) throws {
        try checkJsonRpcSyntax(data: data)
        let result = try data.at("result")
        try response(data: result)
        resolver.fulfill(result)
    }
    open func _failed(error: Error) {
        failed(error: error)
        resolver.reject(error)
    }
}

/// Work in progress. Will be released in 2.2
open class CustomRequest: Request {
    public var parameters: [Any]
    public init(method: String, parameters: [Any]) {
        self.parameters = parameters
        super.init(method: method)
    }
    open override func request() -> [Any] {
        return parameters
    }
}

/// Work in progress. Will be released in 2.2
open class RequestBatch: Request {
    private(set) var requests = [Request]()
    public init() {
        super.init(method: "")
    }
    open func append(_ request: Request) {
        if let batch = request as? RequestBatch {
            requests.append(contentsOf: batch.requests)
        } else {
            requests.append(request)
        }
    }
    open override func response(data: AnyReader) throws {
        try data.array {
            let id = try $0.at("id").int()
            guard let request = requests.first(where: {$0.id == id}) else { return }
            do {
                try request._response(data: $0)
            } catch {
                request._failed(error: error)
            }
        }
    }
    open override func _response(data: AnyReader) throws {
        try response(data: data)
        resolver.fulfill(data)
    }
    open override func requestBody() -> Any {
        return requests.map { $0.requestBody() }
    }
}
