//
//  Web3+Provider.swift
//  web3swift
//
//  Created by Alexander Vlasov on 19.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation
import PromiseKit

/// Providers abstraction for custom providers (websockets, other custom private key managers). At the moment should not be used.
public protocol Web3Provider {
    /// sends request to the node
    func sendAsync(_ request: JsonRpcRequest, queue: DispatchQueue) -> Promise<JsonRpcResponse>
    /// sends multiple requests to the node
    func sendAsync(_ requests: JsonRpcRequestBatch, queue: DispatchQueue) -> Promise<JsonRpcResponseBatch>
    /// network id which used for local signing
    var network: NetworkId? { get set }
    /// keystore manager which contains private keys
    var attachedKeystoreManager: KeystoreManager { get set }
    /// node url address
    var url: URL { get }
    /// url session
    var session: URLSession { get }
}

/// The default http provider.
public class Web3HttpProvider: Web3Provider {
    /// node url address
    public var url: URL
    /// network id which used for local signing
    public var network: NetworkId?
    /// keystore manager which contains private keys
    public var attachedKeystoreManager: KeystoreManager
    /// url session
    public var session = URLSession(configuration: .default)
    
    /// default init with any address and network id. works with infura, localnode and any other node
    public init?(_ httpProviderURL: URL, network net: NetworkId? = nil, keystoreManager manager: KeystoreManager = KeystoreManager()) {
        do {
            guard httpProviderURL.scheme == "http" || httpProviderURL.scheme == "https" else { return nil }
            url = httpProviderURL
            if net == nil {
                let request = JsonRpcRequest(method: .getNetwork)
                let response = try Web3HttpProvider.post(request, providerURL: httpProviderURL, queue: DispatchQueue.global(qos: .userInteractive), session: session).wait()
                if response.error != nil {
                    if response.message != nil {
                        print(response.message!)
                    }
                    return nil
                }
                guard let result: String = response.getValue(), let intNetworkNumber = Int(result) else { return nil }
                network = NetworkId(intNetworkNumber)
                if network == nil { return nil }
            } else {
                network = net
            }
        } catch {
            return nil
        }
        attachedKeystoreManager = manager
    }
    
    static func post(_ request: JsonRpcRequest, providerURL: URL, queue: DispatchQueue = .main, session: URLSession) -> Promise<JsonRpcResponse> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask?
        queue.async {
            do {
                let encoder = JSONEncoder()
                let requestData = try encoder.encode(request)
                var urlRequest = URLRequest(url: providerURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                urlRequest.httpBody = requestData
                //                let debugValue = try JSONSerialization.jsonObject(with: requestData, options: JSONSerialization.ReadingOptions(rawValue: 0))
                //                print(debugValue)
                //                let debugString = String(data: requestData, encoding: .utf8)
                //                print(debugString)
                task = session.dataTask(with: urlRequest) { data, _, error in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil else {
                        rp.resolver.reject(Web3Error.nodeError("Node response is empty"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        return rp.promise.ensure(on: queue) {
            task = nil
            }.map(on: queue) { (data: Data) throws -> JsonRpcResponse in
                let parsedResponse = try JSONDecoder().decode(JsonRpcResponse.self, from: data)
                if parsedResponse.error != nil {
                    throw Web3Error.nodeError("Received an error message from node\n" + String(describing: parsedResponse.error!))
                }
                return parsedResponse
        }
    }
    
    static func post(_ request: JsonRpcRequestBatch, providerURL: URL, queue: DispatchQueue = .main, session: URLSession) -> Promise<JsonRpcResponseBatch> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask?
        queue.async {
            do {
                let encoder = JSONEncoder()
                let requestData = try encoder.encode(request)
                var urlRequest = URLRequest(url: providerURL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                urlRequest.httpBody = requestData
                //                let debugValue = try JSONSerialization.jsonObject(with: requestData, options: JSONSerialization.ReadingOptions(rawValue: 0))
                //                print(debugValue)
                //                let debugString = String(data: requestData, encoding: .utf8)
                //                print(debugString)
                task = session.dataTask(with: urlRequest) { data, _, error in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil, data!.count != 0 else {
                        rp.resolver.reject(Web3Error.nodeError("Node response is empty"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        return rp.promise.ensure(on: queue) {
            task = nil
            }.map(on: queue) { (data: Data) throws -> JsonRpcResponseBatch in
                //                let debugValue = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
                //                print(debugValue)
                let parsedResponse = try JSONDecoder().decode(JsonRpcResponseBatch.self, from: data)
                return parsedResponse
        }
    }
    
    public func sendAsync(_ request: JsonRpcRequest, queue: DispatchQueue = .main) -> Promise<JsonRpcResponse> {
        return Web3HttpProvider.post(request, providerURL: url, queue: queue, session: session)
    }
    
    public func sendAsync(_ requests: JsonRpcRequestBatch, queue: DispatchQueue = .main) -> Promise<JsonRpcResponseBatch> {
        return Web3HttpProvider.post(requests, providerURL: url, queue: queue, session: session)
    }
}
