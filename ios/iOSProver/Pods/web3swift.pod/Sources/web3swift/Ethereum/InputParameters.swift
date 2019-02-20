//
//  InputParameters.swift
//  web3swift
//
//  Created by Dmitry on 20/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

public enum TopicFilter {
    case any, exact(Data), or(Data,Data)
}

open class TopicFilters: JEncodable {
    public var filters = [TopicFilter]()
    public init() {}
    
    open func append(_ filter: TopicFilter) {
        self.filters.append(filter)
    }
    open func jsonRpcValue(with network: NetworkProvider) -> Any {
        var mapped = [Any]()
        for filter in filters {
            switch filter {
            case .any:
                mapped.append(NSNull())
            case .exact(let data):
                mapped.append(data.hex.withHex)
            case let .or(a, b):
                mapped.append([a.hex.withHex, b.hex.withHex])
            }
        }
        return mapped
    }
}



open class FilterOptions: JEncodable {
    /// fromBlock: QUANTITY|TAG - (optional, default: "latest") Integer block number, or "latest" for the last mined block or "pending", "earliest" for not yet mined transactions.
    public var from: BlockNumber?
    
    /// toBlock: QUANTITY|TAG - (optional, default: "latest") Integer block number, or "latest" for the last mined block or "pending", "earliest" for not yet mined transactions.
    public var to: BlockNumber?
    
    /// address: DATA|Array, 20 Bytes - (optional) Contract address or a list of addresses from which logs should originate.
    public var address = [Address]()
    
    /// topics: Array of DATA, - (optional) Array of 32 Bytes DATA topics. Topics are order-dependent. Each topic can also be an array of DATA with "or" options.
    public var topics = TopicFilters()
    
    init() {}
    
    public var dictionary: JDictionary {
        return JDictionary()
            .set("from", from)
            .set("to", to)
            .set("address", JArray(address).nilIfEmpty())
            .set("topics", topics)
    }
    
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return dictionary
    }
}

open class FilterLogOptions: FilterOptions {
    /// blockhash: DATA, 32 Bytes - (optional) With the addition of EIP-234 (Geth >= v1.8.13 or Parity >= v2.1.0), blockHash is a new filter option which restricts the logs returned to the single block with the 32-byte hash blockHash. Using blockHash is equivalent to fromBlock = toBlock = the block number with hash blockHash. If blockHash is present in the filter criteria, then neither fromBlock nor toBlock are allowed.
    public var blockHash: Data?
    public override var dictionary: JDictionary {
        return super.dictionary.set("blockHash", blockHash)
    }
}
