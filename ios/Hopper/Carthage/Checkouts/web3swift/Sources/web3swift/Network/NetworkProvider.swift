//
//  NetworkProvider.swift
//  web3swift
//
//  Created by Dmitry on 14/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit

extension URLSession {
    /// Default web3 url session.
    /// Uses custom delegate queue to process responses from non-main thread.
    /// You can set it with .shared or your own session if you want some customization
    public static var web3 = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue())
}

/// Network provider. Manages your requests
public class NetworkProvider {
    /// Provider url
    public let url: URL
    
    /// Main lock for this provider. Makes it thread safe
    public let lock = NSLock()
    
    /// Time that provider waits before sending all requests
    public var interval: Double = 0.1
    
    /// Contains requests in the current queue.
    public private(set) var queue = RequestBatch()
    
    /// Returns true if queue is not empty and provider waits .interval seconds before send all requests
    public private(set) var isWaiting: Bool = false
    
    /// Transport protocol. By now only implemented URLSession. Its possible to use websockets
    public let transport: NetworkProtocol
    
    /// Init with url. (uses URLSession.web3 as default NetworkProtocol)
    public init(url: URL) {
        transport = URLSession.web3
        self.url = url
    }
    
    /// Init with url and network protocol
    public init(url: URL, transport: NetworkProtocol) {
        self.transport = transport
        self.url = url
    }
    
    /// Send jsonrpc request.
    /// Automatically waits for promises to complete then adds request to the queue.
    ///
    /// - Parameters:
    ///   - method: Api method
    ///   - parameters: Input parameters
    /// - Returns: Promise with response
    open func send(_ method: String, _ parameters: JEncodable...) -> Promise<AnyReader> {
        // Mapping types, requesting promises
        let mapped = parameters.map { $0.jsonRpcValue(with: self) }
        
        // Making request with mapped parameters
        // We will replace promises later after they complete
        let request = CustomRequest(method: method, parameters: mapped)
        
        // Checking for promises and waiting
        let promises = mapped.compactMap { $0 as? Promise<Any> }
        when(fulfilled: promises).done(on: .web3) { _ in
            // Mapping promise results
            request.parameters = mapped.map { element in
                if let promise = element as? Promise<Any> {
                    return (promise.value! as! JEncodable).jsonRpcValue(with: self)
                } else {
                    return element
                }
            }
            // Sending request
            self.send(request: request)
        }.catch(on: .web3, request.resolver.reject)
        return request.promise
    }
    
    /// Sends multiple requests without waiting for the queue.
    open func send(requests: [Request]) {
        sync {
            requests.forEach { queue.append($0) }
            sendAll()
        }
    }
    
    /// Appends request to the queue. Waits for .interval seconds then sends
    open func append(request: Request) {
        sync {
            queue.append(request)
            wait()
        }
    }
    
    /// Send request without waiting for the queue.
    open func send(request: Request) {
        sync {
            queue.append(request)
            sendAll()
        }
    }
    
    /// Sends all request from the current queue.
    /// Automatically called from .send(request:) and append(request:).
    /// Should be runned in .sync { sendAll() } for thread safety
    open func sendAll() {
        cancel()
        let request = queue
        queue = RequestBatch()
        transport.send(request: request, to: url)
    }
    
    /// Locks current thread executes code and unlocks
    public func sync(_ execute: ()->()) {
        lock.lock()
        execute()
        lock.unlock()
    }
    private func wait() {
        guard !isWaiting else { return }
        isWaiting = true
        after(seconds: interval).done(waited)
    }
    private func waited() {
        lock.lock()
        defer { lock.unlock() }
        guard isWaiting else { return }
        isWaiting = false
        sendAll()
    }
    private func cancel() {
        guard isWaiting else { return }
        isWaiting = false
    }
}
