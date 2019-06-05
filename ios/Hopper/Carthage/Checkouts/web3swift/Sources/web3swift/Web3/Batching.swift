//
//  Promise+Batching.swift
//  web3swift
//
//  Created by Alexander Vlasov on 17.06.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit

/// Request dispatcher. Allows you to send multiple JsonRpcRequests in one URLRequest
public class JsonRpcRequestDispatcher {
    /// Time that dispatcher waits before send the request
    public var MAX_WAIT_TIME: TimeInterval = 0.1
    /// Dispatch policy
    public var policy: DispatchPolicy
    /// Dispatch queue for responses
    public var queue: DispatchQueue

    private var provider: Web3Provider
    private var lockQueue: DispatchQueue
    private var batches: [Batch] = [Batch]()

    public init(provider: Web3Provider, queue: DispatchQueue, policy: DispatchPolicy) {
        self.provider = provider
        self.queue = queue
        self.policy = policy
        lockQueue = DispatchQueue(label: "batchingQueue") // serial simplest queue
//        DispatchQueue(label: "batchingQueue", qos: .userInitiated)
        batches.append(Batch(provider: self.provider, capacity: 32, queue: self.queue, lockQueue: lockQueue))
    }

    internal final class Batch {
        var capacity: Int
        var promisesDict = [Int: (promise: Promise<JsonRpcResponse>, resolver: Resolver<JsonRpcResponse>)]()
        var requests = [JsonRpcRequest]()
        var pendingTrigger: Guarantee<Void>?
        var provider: Web3Provider
        var queue: DispatchQueue
        var lockQueue: DispatchQueue
        var triggered: Bool = false
        func add(_ request: JsonRpcRequest, maxWaitTime: TimeInterval) throws -> Promise<JsonRpcResponse> {
            if triggered {
                throw Web3Error.nodeError("Batch is already in flight")
            }
            let requestID = request.id
            let promiseToReturn = Promise<JsonRpcResponse>.pending()
            lockQueue.async {
                if self.promisesDict[requestID] != nil {
                    promiseToReturn.resolver.reject(Web3Error.processingError("Request ID collision"))
                }
                self.promisesDict[requestID] = promiseToReturn
                self.requests.append(request)
                if self.pendingTrigger == nil {
                    self.pendingTrigger = after(seconds: maxWaitTime).done(on: self.queue) {
                        self.trigger()
                    }
                }
                if self.requests.count == self.capacity {
                    self.trigger()
                }
            }
            return promiseToReturn.promise
        }

        func trigger() {
            lockQueue.async {
                guard !self.triggered else { return }
                self.triggered = true
                let requestsBatch = JsonRpcRequestBatch(requests: self.requests)
                self.provider.sendAsync(requestsBatch, queue: self.queue).done(on: self.queue) { batch in
                    for response in batch.responses {
                        if self.promisesDict[response.id] == nil {
                            for k in self.promisesDict.keys {
                                self.promisesDict[k]?.resolver.reject(Web3Error.nodeError("Unknown request id"))
                            }
                            return
                        }
                    }
                    for response in batch.responses {
                        let promise = self.promisesDict[response.id]!
                        promise.resolver.fulfill(response)
                    }
                }.catch(on: self.queue) { err in
                    for k in self.promisesDict.keys {
                        self.promisesDict[k]?.resolver.reject(err)
                    }
                }
            }
        }

        init(provider: Web3Provider, capacity: Int, queue: DispatchQueue, lockQueue: DispatchQueue) {
            self.provider = provider
            self.capacity = capacity
            self.queue = queue
            self.lockQueue = lockQueue
        }
    }

    func getBatch() throws -> Batch {
        guard case let .Batch(batchLength) = policy else {
            throw Web3Error.inputError("Trying to batch a request when policy is not to batch")
        }
        let currentBatch = batches.last!
        if currentBatch.requests.count % batchLength == 0 || currentBatch.triggered {
            let newBatch = Batch(provider: provider, capacity: Int(batchLength), queue: queue, lockQueue: lockQueue)
            batches.append(newBatch)
            return newBatch
        }
        return currentBatch
    }
    
    /// Dispatch policy
    public enum DispatchPolicy {
        /// Sends up to N JsonRpcRequests in one URLRequest
        case Batch(Int)
        /// Sends one JsonRpcRequest in one URLRequest
        case NoBatching
    }

    func addToQueue(request: JsonRpcRequest) -> Promise<JsonRpcResponse> {
        switch policy {
        case .NoBatching:
            return provider.sendAsync(request, queue: queue)
        case .Batch:
            let promise = Promise<JsonRpcResponse> {
                seal in
                self.lockQueue.async {
                    do {
                        let batch = try self.getBatch()
                        let internalPromise = try batch.add(request, maxWaitTime: self.MAX_WAIT_TIME)
                        internalPromise.done(on: self.queue) { resp in
                            seal.fulfill(resp)
                        }.catch(on: self.queue) { err in
                            seal.reject(err)
                        }
                    } catch {
                        seal.reject(error)
                    }
                }
            }
            return promise
        }
    }
}
