//
//  TxPool.swift
//  web3swift-iOS
//
//  Created by Dmitry on 28/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import BigInt

/**
 Native realisation of txpool
 - Important: Doesn't works with Infura provider
 */
public class TxPool {
    /**
     - Important: Doesn't works with Infura provider
     */
    public static var `default`: TxPool {
        return TxPool(web3: .default)
    }
    var web3: Web3
    /**
     - Important: Doesn't works with Infura provider
     */
    public init(web3: Web3) {
        self.web3 = web3
    }
    
    /**
     - Important: Doesn't works with Infura provider | main thread friendly
     - Returns: number of pending and queued transactions
     - Throws:
     DictionaryReader.Error if server has different response than expected |
     Web3Error.nodeError for node error |
     Any URLSession.dataTask Error
     */
    public func status() -> Promise<TxPoolStatus> {
		let request = JsonRpcRequest(method: .txPoolStatus)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue ) { try TxPoolStatus($0.response()) }
    }
    
    /**
     - Important: Doesn't works with Infura provider | main thread friendly
     - Returns: main information about pending and queued transactions
     - Throws:
     DictionaryReader.Error if server has different response than expected |
     Web3Error.nodeError for node error |
     Any URLSession.dataTask Error
     */
    public func inspect() -> Promise<TxPoolInspect> {
		let request = JsonRpcRequest(method: .txPoolInspect)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue ) { try TxPoolInspect($0.response()) }
    }
    
    /**
     - Important: Doesn't works with Infura provider | main thread friendly
     - Returns: full information for all pending and queued transactions
     - Throws:
     DictionaryReader.Error if server has different response than expected |
     Web3Error.nodeError for node error |
     Any URLSession.dataTask Error
     */
    public func content() -> Promise<TxPoolContent> {
		let request = JsonRpcRequest(method: .txPoolContent)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue ) { try TxPoolContent($0.response()) }
    }
}

extension AnyReader {
    func split(_ separator: String, _ expectedSize: Int) throws -> [AnyReader] {
        let string = try self.string()
        let array = string.components(separatedBy: separator)
        guard array.count >= expectedSize else { throw unconvertible(to: "[Any]") }
        return array.map { AnyReader($0) }
    }
}

/// txPool.status() response
public struct TxPoolStatus {
    /// Number of pending transactions
    public var pending: Int
    /// Number of queued transactions
    public var queued: Int
    init(_ dictionary: AnyReader) throws {
        pending = try dictionary.at("pending").int()
        queued = try dictionary.at("queued").int()
    }
}

/// txPool.inspect() response
public class TxPoolInspect {
    /// array of pending transactions
    public let pending: [Transaction]
    /// array of queued transactions
    public let queued: [Transaction]
    init(_ dictionary: AnyReader) throws {
        pending = try TxPoolInspect.parse(dictionary.at("pending"))
        queued = try TxPoolInspect.parse(dictionary.at("queued"))
    }
    init() {
        pending = []
        queued = []
    }
    private static func parse(_ reader: AnyReader) throws -> [Transaction] {
        var array = [Transaction]()
        try reader.dictionary {
            let from = try $0.address()
            try $1.dictionary {
                let nonce = try $0.int()
                let transaction = try Transaction($1, from: from, nonce: nonce)
                array.append(transaction)
            }
        }
        return array
    }
    
    /// TxPoolInspect Transaction
    /// Contains main information about transaction
    public class Transaction {
        /// Transaction sender address
        public let from: Address
        /// Nonce
        public let nonce: Int
        /// Recipient address (user or smart contract)
        public let to: Address
        /// Number of ether sended to recipient
        public let value: BigUInt
        /// Transaction gas limit
        public let gasLimit: BigUInt
        /// Transaction gas price
        public let gasPrice: BigUInt
        init(_ reader: AnyReader, from: Address, nonce: Int) throws {
            self.from = from
            self.nonce = nonce
            let string = try reader.split(" ", 7)
            to = try string[0].address()
            value = try string[1].uint256()
            gasLimit = try string[4].uint256()
            gasPrice = try string[7].uint256()
        }
    }
}

/// txPool.content() response
public class TxPoolContent {
    /// Array of pending transactions
    public let pending: [Transaction]
    /// Array of queued transactions
    public let queued: [Transaction]
    init(_ dictionary: AnyReader) throws {
        pending = try TxPoolContent.parse(dictionary.at("pending"))
        queued = try TxPoolContent.parse(dictionary.at("queued"))
    }
    init() {
        pending = []
        queued = []
    }
    private static func parse(_ reader: AnyReader) throws -> [Transaction] {
        var array = [Transaction]()
        try reader.dictionary {
            let from = try $0.address()
            try $1.dictionary {
                let nonce = try $0.int()
                let transaction = try Transaction($1, from: from, nonce: nonce)
                array.append(transaction)
            }
        }
        return array
    }
    
    /// Transaction object from TxPoolContent
    /// Contains full information about transaction
    public class Transaction {
        /// Transaction sender address
        public let from: Address
        /// Nonce
        public let nonce: Int
        /// Recipient address (user or smart contract)
        public let to: Address
        /// Number of ether sended to recipient
        public let value: BigUInt
        /// Transaction gas limit
        public let gasLimit: BigUInt
        /// Transaction gas price
        public let gasPrice: BigUInt
        /// Transaction input data
        public let input: Data
        /// Transaction hash
        public let hash: Data
        /// v value
        public let v: BigUInt
        /// r value
        public let r: BigUInt
        /// s value
        public let s: BigUInt
        /// block hash
        public let blockHash: Data
        /// trnsaction index
        public let transactionIndex: BigUInt
        init(_ reader: AnyReader, from: Address, nonce: Int) throws {
            self.from = from
            self.nonce = nonce
            input = try reader.at("input").data()
            gasPrice = try reader.at("gasPrice").uint256()
            s = try reader.at("s").uint256()
            to = try reader.at("to").address()
            value = try reader.at("value").uint256()
            gasLimit = try reader.at("gas").uint256()
            hash = try reader.at("hash").data()
            v = try reader.at("v").uint256()
            transactionIndex = try reader.at("transactionIndex").uint256()
            r = try reader.at("r").uint256()
            blockHash = try reader.at("blockHash").data()
        }
    }
}
