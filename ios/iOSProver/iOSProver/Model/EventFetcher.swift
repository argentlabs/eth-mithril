//
//  EventFetcher.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 14/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import PromiseKit
import web3swift
import BigInt

class EventFetcher {
    
    enum EventFetcherError: Error {
        case invalidBlockNumber
        case invalidParams
    }

    private static let bgq = DispatchQueue.global(qos: .userInitiated)
    private static func loadWeb3Async(url: URL) -> Promise<web3swift.Web3> {
        return Promise { seal in
            bgq.async {
                let web3 = web3swift.Web3(url: url)
                DispatchQueue.main.async {
                    seal.resolve(web3, nil)
                }
            }
        }
    }
    
    static func fetchEvents(rpcPath: String,
                            name: String,
                            abiData: Data,
                            contractAddress: String,
                            startBlock: UInt64,
                            pollingPeriod: TimeInterval? = nil,
                            filters: [String: EventFilterable]? = nil,
                            web3Instance: Web3? = nil,
                            completion: @escaping ([EventParserResult]?, Error?) -> ()) {
        
        guard let url = URL(string: rpcPath), let jsonAbi = String(data: abiData, encoding: .utf8) else {
            completion(nil, EventFetcherError.invalidParams)
            return
        }
        
        var web3: Web3!
        var lastBlockNumber: UInt64!
        firstly { () -> Promise<Web3> in
            web3Instance != nil ? Promise { $0.resolve(web3Instance!, nil) } : loadWeb3Async(url: url)
        }.then(on: bgq) { web3Instance -> Promise<BigUInt> in
            web3 = web3Instance
            return web3.eth.getBlockNumberPromise()
        }.then(on: bgq) { blockNum -> Promise<[EventParserResult]>  in
            guard let blockNumInt = UInt64(blockNum.description) else { throw EventFetcherError.invalidBlockNumber }
            lastBlockNumber = blockNumInt
            let contract = try web3.contract(jsonAbi, at: Address(contractAddress))
            let filter = EventFilter(fromBlock: .blockNumber(startBlock),
                                     toBlock: .blockNumber(lastBlockNumber),
                                     addresses: [Address(contractAddress)])
            return contract.getIndexedEventsPromise(eventName: name, filter: filter, joinWithReceipts: false)
        }.done(on: bgq) { result in
            let filtered = result.filter { event in
                filters?.allSatisfy { (constr: (paramName: String, paramVal: EventFilterable)) -> Bool in
                    return constr.paramVal.isEqualTo(event.decodedResult[constr.paramName] as AnyObject)
                } != false
            }
            // print("fetched from block:\(startBlock) to block:\(lastBlockNumber!), found:\(filtered.count)")
            
            if filtered.isEmpty, let pollPeriod = pollingPeriod {
                after(seconds: pollPeriod).done {
                    fetchEvents(rpcPath: rpcPath,
                                name: name,
                                abiData: abiData,
                                contractAddress: contractAddress,
                                startBlock: lastBlockNumber,
                                pollingPeriod: pollingPeriod,
                                filters: filters,
                                web3Instance: web3,
                                completion: completion)
                }
            } else {
                completion(filtered, nil)
            }
            
            
        }.catch { error in
            completion(nil, error)
        }

    }
    
    static func fetchEventsPromise(rpcPath: String,
                                   name: String,
                                   abiData: Data,
                                   contractAddress: String,
                                   startBlock: UInt64,
                                   pollingPeriod: TimeInterval? = nil,
                                   filters: [String: EventFilterable]? = nil,
                                   web3Instance: Web3? = nil) -> Promise<[EventParserResult]> {
        return Promise { seal in
            fetchEvents(rpcPath: rpcPath,
                        name: name,
                        abiData: abiData,
                        contractAddress: contractAddress,
                        startBlock: startBlock,
                        pollingPeriod: pollingPeriod,
                        filters: filters,
                        web3Instance: web3Instance,
                        completion: seal.resolve)
        }
    }
}
