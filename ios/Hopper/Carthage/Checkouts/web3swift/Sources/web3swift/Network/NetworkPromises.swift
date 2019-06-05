//
//  NetworkPromises.swift
//  web3swift
//
//  Created by Dmitry on 14/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit

/// Work in progress. Will be released in 2.2
public protocol NetworkProtocol {
    /// Sends request to url. To get
    func send(request: Request, to url: URL)
}

/// Work in progress. Will be released in 2.2
extension DispatchQueue {
    public static var web3 = DispatchQueue(label: "web3swift.queue")
    func promise<T>(_ execute: @escaping ()throws->(T)) -> Promise<T> {
        let (promise, resolver) = Promise<T>.pending()
        async {
            do {
                try resolver.fulfill(execute())
            } catch {
                resolver.reject(error)
            }
        }
        return promise
    }
    func resolver<T>(_ execute: @escaping (Resolver<T>)throws->()) -> Promise<T> {
        let (promise, resolver) = Promise<T>.pending()
        async {
            do {
                try execute(resolver)
            } catch {
                resolver.reject(error)
            }
        }
        return promise
    }
    
    func run<T>(_ resolver: Resolver<T>, _ code: @escaping ()throws->(T)) {
        async {
            do {
                try resolver.fulfill(code())
            } catch {
                resolver.reject(error)
            }
        }
    }
}

/// Work in progress. Will be released in 2.2
class PromiseOperation<T>: Operation {
    let resolver: Resolver<T>
    let execute: ()throws->(T)
    init(resolver: Resolver<T>, execute: @escaping ()throws->(T)) {
        self.resolver = resolver
        self.execute = execute
    }
    override func main() {
        do {
            let result = try execute()
            resolver.fulfill(result)
        } catch {
            resolver.reject(error)
        }
    }
}

extension URLSession: NetworkProtocol {
    public func send(request: Request, to url: URL) {
        send(request: request, to: url).done(on: .web3) { data in
            print("response: \(data.string)")
            let response = try AnyReader(json: data)
            do {
                try request._response(data: response)
            } catch {
                request._failed(error: error)
            }
        }.catch(request._failed)
    }
    private func send(request: Request, to url: URL) -> Promise<Data> {
        return DispatchQueue.web3.promise {
            try request.request(url: url)
        }.then(on: .web3) { request in
            self.send(request: request)
        }
    }
    private func send(request: URLRequest) -> Promise<Data> {
        let (promise, resolver) = Promise<Data>.pending()
        print("request: \(request.httpBody!.string)")
        dataTask(with: request) { data, response, error in
            if let error = error {
                resolver.reject(error)
            } else if let data = data, data.count > 0 {
                resolver.fulfill(data)
            } else {
                resolver.reject(Web3Error.nodeError("Node response is empty"))
            }
        }.resume()
        return promise
    }
}
