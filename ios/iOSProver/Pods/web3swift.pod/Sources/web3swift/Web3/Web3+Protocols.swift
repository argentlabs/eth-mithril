//
//  Web3+Protocols.swift
//  web3swift-iOS
//
//  Created by Alexander Vlasov on 26.02.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation
import class PromiseKit.Promise

/// Protocol for generic Ethereum event parser
public protocol EventParserProtocol {
    /**
     Parses the transaction for events matching the EventParser settings.
     - Parameter transaction: web3swift native EthereumTransaction object
     - Returns: array of events
     - Important: This call is synchronous
     */
    func parseTransaction(_ transaction: EthereumTransaction) throws -> [EventParserResult]
    
    /**
     Parses the transaction for events matching the EventParser settings.
     - Parameter hash: Transaction hash
     - Returns: array of events
     - Important: This call is synchronous
     */
    func parseTransactionByHash(_ hash: Data) throws -> [EventParserResult]
    
    /**
     Parses the block for events matching the EventParser settings.
     - Parameter block: Native web3swift block object
     - Returns: array of events
     - Important: This call is synchronous
     */
    func parseBlock(_ block: Block) throws -> [EventParserResult]
    
    /**
     Parses the block for events matching the EventParser settings.
     - Parameter blockNumber: Ethereum network block number
     - Returns: array of events
     - Important: This call is synchronous
     */
    func parseBlockByNumber(_ blockNumber: UInt64) throws -> [EventParserResult]
    
    /**
     Parses the transaction for events matching the EventParser settings.
     - Parameter transaction: web3swift native EthereumTransaction object
     - Returns: promise that returns array of events
     - Important: This call is synchronous
     */
    func parseTransactionPromise(_ transaction: EthereumTransaction) -> Promise<[EventParserResult]>
    
    /**
     Parses the transaction for events matching the EventParser settings.
     - Parameter hash: Transaction hash
     - Returns: promise that returns array of events
     - Important: This call is synchronous
     */
    func parseTransactionByHashPromise(_ hash: Data) -> Promise<[EventParserResult]>
    
    /**
     Parses the block for events matching the EventParser settings.
     - Parameter blockNumber: Ethereum network block number
     - Returns: promise that returns array of events
     - Important: This call is synchronous
     */
    func parseBlockByNumberPromise(_ blockNumber: UInt64) -> Promise<[EventParserResult]>
    
    /**
     Parses the block for events matching the EventParser settings.
     - Parameter block: Native web3swift block object
     - Returns: promise that returns array of events
     - Important: This call is synchronous
     */
    func parseBlockPromise(_ block: Block) -> Promise<[EventParserResult]>
    
}

/// Enum for the most-used Ethereum networks. Network ID is crucial for EIP155 support
public struct NetworkId {
	/// Network id number
    public var rawValue: BigUInt
	/// NetworkId(1) init
    public init(_ rawValue: BigUInt) {
        self.rawValue = rawValue
    }
	
	/// Init with int value
    public init(_ rawValue: Int) {
        self.rawValue = BigUInt(rawValue)
    }
	
	/// Returns array of all known networks (mainnet, ropsten, rinkeby and kovan)
    public var all: [NetworkId] {
        return [.mainnet, .ropsten, .rinkeby, .kovan]
    }

	/// Default networkid (.mainnet)
    public static var `default`: NetworkId = .mainnet
	/// - Returns: 1
    public static var mainnet: NetworkId { return 1 }
	/// - Returns: 3
    public static var ropsten: NetworkId { return 3 }
	/// - Returns: 4
    public static var rinkeby: NetworkId { return 4 }
	/// - Returns: 42
    public static var kovan: NetworkId { return 42 }
}

extension NetworkId: RawRepresentable {
    /// RawRepresentable init
    public init(rawValue: BigUInt) {
        self.rawValue = rawValue
    }
}

extension NetworkId: CustomStringConvertible {
    /// Returns network name
    public var description: String {
        switch rawValue {
        case 1: return "mainnet"
        case 3: return "ropsten"
        case 4: return "rinkeby"
        case 42: return "kovan"
        default: return ""
        }
    }
}

extension NetworkId: ExpressibleByIntegerLiteral {
    /// Literal type used for ExpressibleByIntegerLiteral
    public typealias IntegerLiteralType = Int
    /// ExpressibleByIntegerLiteral init so you can do
    /// ```
    /// let networkId: NetworkId = 1
    /// ```
    public init(integerLiteral value: Int) {
        rawValue = BigUInt(value)
    }
}
