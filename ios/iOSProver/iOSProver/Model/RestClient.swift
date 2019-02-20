//
//  RestClient.swift
//  Coinstream
//
//  Created by Olivier van den Biggelaar on 28/07/2017.
//  Copyright © 2017 Olivier van den Biggelaar. All rights reserved.
//

import Foundation

class RestClient {
    private let endPoint: String
    
    init(endPoint: String) {
        self.endPoint = endPoint
    }
    
    init() {
        self.endPoint = ""
    }
    
    enum ContentType: String {
        case json
        case x_www_form_urlencoded
        case text
        
        var headerValue: String {
            if case .text = self {
                return "text/plain"
            } else {
                return "application/\(rawValue.replacingOccurrences(of: "_", with: "-"))"
            }
        }
        
        static func encode(params: Dictionary<String, String>) -> String {
            let paramStrings = params.sorted(by: { $0 < $1 }).map { (key, value) -> String in
                if let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                    let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                    return "\(escapedKey)=\(escapedValue)"
                }
                return ""
            }
            return paramStrings.joined(separator: "&")
        }
        
        static func JSONStringify(_ value: Any, prettyPrinted: Bool = false) -> String? {
            let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : []
            if JSONSerialization.isValidJSONObject(value) {
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: options)
                    return String(data: data, encoding: .utf8)
                }  catch { NSLog("RestClient Error: JSON serialization failed") }
            }
            NSLog("RestClient Error: invalid JSON object was passed")
            return nil
        }
        
        func httpBody(fromParams params: [String: Any]) -> Data? {
            let body: String?
            switch self {
            case .x_www_form_urlencoded:
                body = type(of: self).encode(params: params as? [String: String] ?? [:])
            case .json:
                body = type(of: self).JSONStringify(params)
            case .text:
                body = nil
            }
            return body?.data(using: .utf8)
        }
    }
    
    public func request(
        forPath path: String,
        withMethod method: String,
        params: Dictionary<String, Any>? = nil,
        headers: Dictionary<String, String>? = nil,
        contentType: ContentType = .x_www_form_urlencoded
        ) -> URLRequest {
        
        var stringURL = endPoint + path
        if method == "GET", let params = params as? [String: String], !params.isEmpty {
            stringURL += "?\(ContentType.encode(params: params))"
        }
        
        let request = NSMutableURLRequest(url: URL(string: stringURL)!)
        request.httpMethod = method
        request.setValue(contentType.headerValue, forHTTPHeaderField: "Content-Type")
        
        if method == "POST", let params = params {
            request.httpBody = contentType.httpBody(fromParams: params)
        }
        
        if let headers = headers {
            for (headerField, headerValue) in headers {
                request.addValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        
        return request as URLRequest
    }
    
    public func postRequest(
        forPath path: String = "",
        params: Dictionary<String, Any>? = nil,
        headers: Dictionary<String, String>? = nil,
        contentType: ContentType = .x_www_form_urlencoded
        ) -> URLRequest {
        return request(forPath: path, withMethod: "POST", params: params, headers: headers, contentType: contentType)
    }
    
    public func getRequest(
        forPath path: String,
        params: Dictionary<String, Any>? = nil,
        headers: Dictionary<String, String>? = nil,
        contentType: ContentType = .x_www_form_urlencoded
        ) -> URLRequest {
        return request(forPath: path, withMethod: "GET", params: params, headers: headers, contentType: contentType)
    }
    
    public func query(_ request: URLRequest, completion: ((_ statusCode: Int, _ json: Any?, _ error: Error?) -> ())? = nil) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request) { (data, response, error) in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            if let data = data {
                var json = try? JSONSerialization.jsonObject(with: data)
                if json == nil { json = String(data: data, encoding: .utf8) }
                completion?(statusCode, json, nil)
            } else if let error = error {
                NSLog("RestClient query error: \(error.localizedDescription)")
                completion?(statusCode, nil, error)
            }
        }
        task.resume()
    }
}
