//
//  Web3+TransactionIntermediate.swift
//  web3swift-iOS
//
//  Created by Alexander Vlasov on 26.02.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation
import PromiseKit

extension Web3Contract {
    /// An event parser to fetch events produced by smart-contract related transactions. Should not be constructed manually, but rather by calling the corresponding function on the Web3Contract object.
    public struct EventParser: EventParserProtocol {
        /// Contract for parsing
        public var contract: ContractProtocol
        /// Event name
        public var eventName: String
        /// Event filter
        public var filter: EventFilter?
        var web3: Web3
        /// Init with event and contract. Returns nil if contract doesn't have that method
        public init? (web3 web3Instance: Web3, eventName: String, contract: ContractProtocol, filter: EventFilter? = nil) {
            guard let _ = contract.allEvents.index(of: eventName) else { return nil }
            self.eventName = eventName
            web3 = web3Instance
            self.contract = contract
            self.filter = filter
        }
        
        /**
         Parses the transaction for events matching the EventParser settings.
         - Parameter transaction: web3swift native EthereumTransaction object
         - Returns: Array of events
         - Important: This call is synchronous
         */
        public func parseTransaction(_ transaction: EthereumTransaction) throws -> [EventParserResult] {
            return try parseTransactionPromise(transaction).wait()
        }

        /**
         Parses the transaction for events matching the EventParser settings.
         - Parameter hash: Transaction hash
         - Returns: Array of events
         - Important: This call is synchronous
         */
        public func parseTransactionByHash(_ hash: Data) throws -> [EventParserResult] {
            return try parseTransactionByHashPromise(hash).wait()
        }
        
        /**
         Parses the block for events matching the EventParser settings.
         - Parameter blockNumber: Ethereum network block number
         - Returns: Array of events
         - Important: This call is synchronous
         */
        public func parseBlockByNumber(_ blockNumber: UInt64) throws -> [EventParserResult] {
            return try parseBlockByNumberPromise(blockNumber).wait()
        }

        /**
         Parses the block for events matching the EventParser settings.
         - Parameter block: Native web3swift block object
         - Returns: array of events
         - Important: This call is synchronous
         */
        public func parseBlock(_ block: Block) throws -> [EventParserResult] {
            return try parseBlockPromise(block).wait()
        }
    }
}

extension Web3Contract.EventParser {
    /**
     Parses the transaction for events matching the EventParser settings.
     - Parameter transaction: web3swift native EthereumTransaction object
     - Returns: Promise that returns array of events
     - Important: This call is synchronous
     */
    public func parseTransactionPromise(_ transaction: EthereumTransaction) -> Promise<[EventParserResult]> {
        let queue = web3.requestDispatcher.queue
        do {
            guard let hash = transaction.hash else {
                throw Web3Error.processingError("Failed to get transaction hash") }
            return parseTransactionByHashPromise(hash)
        } catch {
            let returnPromise = Promise<[EventParserResult]>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }

    /**
     Parses the transaction for events matching the EventParser settings.
     - Parameter hash: Transaction hash
     - Returns: Promise that returns array of events
     - Important: This call is synchronous
     */
    public func parseTransactionByHashPromise(_ hash: Data) -> Promise<[EventParserResult]> {
        let queue = web3.requestDispatcher.queue
        return web3.eth.getTransactionReceiptPromise(hash).map(on: queue) { receipt throws -> [EventParserResult] in
            guard let results = parseReceiptForLogs(receipt: receipt, contract: self.contract, eventName: self.eventName, filter: self.filter) else {
                throw Web3Error.processingError("Failed to parse receipt for events")
            }
            return results
        }
    }

    /**
     Parses the block for events matching the EventParser settings.
     - Parameter blockNumber: Ethereum network block number
     - Returns: Promise that returns array of events
     - Important: This call is synchronous
     */
    public func parseBlockByNumberPromise(_ blockNumber: UInt64) -> Promise<[EventParserResult]> {
        let queue = web3.requestDispatcher.queue
        do {
            if filter != nil && (filter?.fromBlock != nil || filter?.toBlock != nil) {
                throw Web3Error.inputError("Can not mix parsing specific block and using block range filter")
            }
            return web3.eth.getBlockByNumberPromise(blockNumber).then(on: queue) { res in
                self.parseBlockPromise(res)
            }
        } catch {
            let returnPromise = Promise<[EventParserResult]>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }

    /**
     Parses the block for events matching the EventParser settings.
     - Parameter block: Native web3swift block object
     - Returns: Promise that returns array of events
     - Important: This call is synchronous
     */
    public func parseBlockPromise(_ block: Block) -> Promise<[EventParserResult]> {
        let queue = web3.requestDispatcher.queue
        do {
            guard let bloom = block.logsBloom else {
                throw Web3Error.processingError("Block doesn't have a bloom filter log")
            }
            if contract.address != nil {
                let addressPresent = block.logsBloom?.test(topic: contract.address!.addressData)
                if addressPresent != true {
                    let returnPromise = Promise<[EventParserResult]>.pending()
                    queue.async {
                        returnPromise.resolver.fulfill([EventParserResult]())
                    }
                    return returnPromise.promise
                }
            }
            guard let eventOfSuchTypeIsPresent = self.contract.testBloomForEventPrecence(eventName: self.eventName, bloom: bloom) else {
                throw Web3Error.processingError("Error processing bloom for events")
            }
            if !eventOfSuchTypeIsPresent {
                let returnPromise = Promise<[EventParserResult]>.pending()
                queue.async {
                    returnPromise.resolver.fulfill([EventParserResult]())
                }
                return returnPromise.promise
            }
            return Promise { seal in

                var pendingEvents: [Promise<[EventParserResult]>] = [Promise<[EventParserResult]>]()
                for transaction in block.transactions {
                    switch transaction {
                    case .null:
                        seal.reject(Web3Error.processingError("No information about transactions in block"))
                        return
                    case let .transaction(tx):
                        guard let hash = tx.hash else {
                            seal.reject(Web3Error.processingError("Failed to get transaction hash"))
                            return
                        }
                        let subresultPromise = self.parseTransactionByHashPromise(hash)
                        pendingEvents.append(subresultPromise)
                    case let .hash(hash):
                        let subresultPromise = self.parseTransactionByHashPromise(hash)
                        pendingEvents.append(subresultPromise)
                    }
                }
                when(resolved: pendingEvents).done(on: queue) { (results: [Result<[EventParserResult]>]) throws in
                    var allResults = [EventParserResult]()
                    for res in results {
                        guard case let .fulfilled(subresult) = res else {
                            throw Web3Error.processingError("Failed to parse event for one transaction in block")
                        }
                        allResults.append(contentsOf: subresult)
                    }
                    seal.fulfill(allResults)
                }.catch(on: queue) { err in
                    seal.reject(err)
                }
            }
        } catch {
            let returnPromise = Promise<[EventParserResult]>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
}

extension Web3Contract {
    /**
     Fetches events by doing a lookup on "indexed" parameters of the event. Smart-contract developer can make some of event values "indexed" for such fast queries.
     - Parameter eventName: Event name, should be present in ABI interface of the contract
     - Parameter filter: EventFilter object setting the block limits for query
     - Parameter joinWithReceipts: Bool indicating whether TransactionReceipt should be fetched separately for every matched transaction
     - Returns: Array of events
     - Important: This call is synchronous
     */
    public func getIndexedEvents(eventName: String?, filter: EventFilter, joinWithReceipts: Bool = false) throws -> [EventParserResult] {
        return try getIndexedEventsPromise(eventName: eventName, filter: filter, joinWithReceipts: joinWithReceipts).wait()
    }
    
    /**
     Fetches events by doing a lookup on "indexed" parameters of the event. Smart-contract developer can make some of event values "indexed" for such fast queries.
     - Parameter eventName: Event name, should be present in ABI interface of the contract
     - Parameter filter: EventFilter object setting the block limits for query
     - Parameter joinWithReceipts: Bool indicating whether TransactionReceipt should be fetched separately for every matched transaction
     - Returns: Promise that returns array of events
     - Important: This call is synchronous
     */
    public func getIndexedEventsPromise(eventName: String?, filter: EventFilter, joinWithReceipts: Bool = false) -> Promise<[EventParserResult]> {
        let queue = web3.requestDispatcher.queue
        do {
            guard let rawContract = self.contract as? ContractV2 else {
                throw Web3Error.nodeError("ABIv1 is not supported for this method")
            }
            guard let preEncoding = encodeTopicToGetLogs(contract: rawContract, eventName: eventName, filter: filter) else {
                throw Web3Error.processingError("Failed to encode topic for request")
            }
            //            var event: ABIv2.Element.Event? = nil
            if eventName != nil {
                guard let _ = rawContract.events[eventName!] else {
                    throw Web3Error.processingError("No such event in a contract")
                }
                //                event = ev
            }
			let request = JsonRpcRequest(method: .getLogs, parameters: preEncoding)
            let fetchLogsPromise = web3.dispatch(request).map(on: queue) { response throws -> [EventParserResult] in
                guard let value: [EventLog] = response.getValue() else {
                    if response.error != nil {
                        throw Web3Error.nodeError(response.error!.message)
                    }
                    throw Web3Error.nodeError("Empty or malformed response")
                }
                let allLogs = value
                let decodedLogs = allLogs.compactMap({ (log) -> EventParserResult? in
                    let (n, d) = self.contract.parseEvent(log)
                    guard let evName = n, let evData = d else { return nil }
                    var res = EventParserResult(eventName: evName, transactionReceipt: nil, contractAddress: log.address, decodedResult: evData)
                    res.eventLog = log
                    return res
                }).filter { (res: EventParserResult?) -> Bool in
                    if eventName != nil {
                        if res != nil && res?.eventName == eventName && res!.eventLog != nil {
                            return true
                        }
                    } else {
                        if res != nil && res!.eventLog != nil {
                            return true
                        }
                    }
                    return false
                }
                return decodedLogs
            }
            if !joinWithReceipts {
                return fetchLogsPromise
            }
            return fetchLogsPromise.thenMap(on: queue) { singleEvent in
                self.web3.eth.getTransactionReceiptPromise(singleEvent.eventLog!.transactionHash).map(on: queue) { receipt in
                    var joinedEvent = singleEvent
                    joinedEvent.transactionReceipt = receipt
                    return joinedEvent
                }
            }
        } catch {
            let returnPromise = Promise<[EventParserResult]>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
}
