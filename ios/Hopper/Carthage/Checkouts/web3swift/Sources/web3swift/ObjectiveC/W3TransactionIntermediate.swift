//
//  W3TransactionIntermediate.swift
//  web3swift
//
//  Created by Dmitry on 09/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension SolidityDataReader {
    public var objc: W3SolidityDataReader {
        return W3SolidityDataReader(self)
    }
}

@objc public class W3SolidityDataReader: NSObject, SwiftContainer {
    public let swift: SolidityDataReader
    public required init(_ swift: SolidityDataReader) {
        self.swift = swift
    }
    
    @objc public var data: Data {
        return swift.data
    }
    @objc public var position: Int {
        return swift.position
    }
    @objc public var headerSize: Int {
        return swift.headerSize
    }
    @objc public func uint256() throws -> W3UInt {
        return try swift.uint256().objc
    }
    @objc public func address() throws -> W3Address {
        return try swift.address().objc
    }
    @objc public func string() throws -> String {
        return try swift.string()
    }
    
    @objc public func header(_ size: Int) throws -> Data {
        return try swift.header(size)
    }
    @objc public func skip(_ count: Int) throws {
        try swift.skip(count)
    }
    @objc public func next(_ size: Int) throws -> Data {
        return try swift.next(size)
    }
    private func throwNumber<T>(default value: T, pointer: NSErrorPointer, block: ()throws->(T)) -> T {
        do {
            return try block()
        } catch {
            pointer?.pointee = error as NSError
            return value
        }
    }
    @objc public func bool(error: NSErrorPointer) -> Bool {
        return throwNumber(default: false, pointer: error) {
            try swift.bool()
        }
    }
    @objc public func uint8(error: NSErrorPointer) -> UInt8 {
        return throwNumber(default: 0, pointer: error) {
            try swift.uint8()
        }
    }
    @objc public func uint16(error: NSErrorPointer) -> UInt16 {
        return throwNumber(default: 0, pointer: error) {
            try swift.uint16()
        }
    }
    @objc public func uint32(error: NSErrorPointer) -> UInt32 {
        return throwNumber(default: 0, pointer: error) {
            try swift.uint32()
        }
    }
    @objc public func uint64(error: NSErrorPointer) -> UInt64 {
        return throwNumber(default: 0, pointer: error) {
            try swift.uint64()
        }
    }
    @objc public func uint(error: NSErrorPointer) -> UInt {
        return throwNumber(default: 0, pointer: error) {
            try swift.uint()
        }
    }
    @objc public func int8(error: NSErrorPointer) -> Int8 {
        return throwNumber(default: 0, pointer: error) {
            try swift.int8()
        }
    }
    @objc public func int16(error: NSErrorPointer) -> Int16 {
        return throwNumber(default: 0, pointer: error) {
            try swift.int16()
        }
    }
    @objc public func int32(error: NSErrorPointer) -> Int32 {
        return throwNumber(default: 0, pointer: error) {
            try swift.int32()
        }
    }
    @objc public func int64(error: NSErrorPointer) -> Int64 {
        return throwNumber(default: 0, pointer: error) {
            try swift.int64()
        }
    }
    @objc public func int(error: NSErrorPointer) -> Int {
        return throwNumber(default: 0, pointer: error) {
            try swift.int()
        }
    }
    @objc public func intCount(error: NSErrorPointer) -> Int {
        return throwNumber(default: 0, pointer: error) {
            try swift.intCount()
        }
    }
}

extension Web3Response {
    public var objc: W3Response {
        return W3Response(self)
    }
}
@objc public class W3Response: NSObject, SwiftContainer {
    public let swift: Web3Response
    public required init(_ swift: Web3Response) {
        self.swift = swift
    }
    
    @objc public var position: Int {
        get { return swift.position }
        set { swift.position = newValue }
    }
    
    @objc public subscript(key: String) -> Any? {
        return swift[key]
    }
    
    @objc public subscript(index: Int) -> Any? {
        return swift[index]
    }
    
    /// Returns next response argument as W3UInt (like self[n] as? W3UInt; n += 1)
    /// throws Web3ResponseError.notFound if there is no value at self[n]
    /// throws Web3ResponseError.wrongType if it cannot cast self[n] to W3UInt
    @objc public func uint256() throws -> W3UInt {
        return try swift.uint256().objc
    }
    
    /// Returns next response argument as W3Address (like self[n] as? W3Address; n += 1)
    /// throws Web3ResponseError.notFound if there is no value at self[n]
    /// throws Web3ResponseError.wrongType if it cannot cast self[n] to W3Address
    @objc public func address() throws -> W3Address {
        return try swift.address().objc
    }
    
    /// Returns next response argument as String (like self[n] as? String; n += 1)
    /// throws Web3ResponseError.notFound if there is no value at self[n]
    /// throws Web3ResponseError.wrongType if it cannot cast self[n] to String
    @objc public func string() throws -> String {
        return try swift.string()
    }
    
    @objc public func next() throws -> Any {
        return try swift.next()
    }
}

extension TransactionIntermediate {
    public var objc: W3TransactionIntermediate {
        return W3TransactionIntermediate(self)
    }
}

/// TransactionIntermediate is an almost-ready transaction or a smart-contract function call. It bears all the required information
/// to call the smart-contract and decode the returned information, or estimate gas required for transaction, or send a transaciton
/// to the blockchain.
@objc public class W3TransactionIntermediate: NSObject, W3OptionsInheritable, SwiftContainer {
    public var swift: TransactionIntermediate
    var _swiftOptions: Web3Options {
        get { return swift.options }
        set { swift.options = newValue }
    }
    public required init(_ swift: TransactionIntermediate) {
        self.swift = swift
        super.init()
        options = W3Options(object: self)
    }
    
    @objc public var transaction: W3EthereumTransaction {
        return swift.transaction.objc
    }
    @objc public var contract: W3Contract {
        return swift.contract.objc
    }
    @objc public var method: String {
        get { return swift.method }
        set { swift.method = newValue }
    }
    @objc public var options: W3Options!
    @objc public init(transaction: W3EthereumTransaction, web3: W3Web3, contract: W3Contract, method: String, options: W3Options) {
        swift = TransactionIntermediate(transaction: transaction.swift, web3: web3.swift, contract: contract.swift, method: method, options: options.swift)
    }
    
    /**
     *Send a prepared transaction to the blockchain. Internally checks the nonce for a sending account, assigns it, get a gas estimate and signs a transaction either locally or on the remote node.*
     
     - Parameter password: Password for a private key if transaction is signed locally
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: W3TransactionSendingResult
     - Important: This call is synchronous
     */
    @discardableResult
    @objc public func send(password: String = "BANKEXFOUNDATION", options: W3Options?, onBlock: String = "pending") throws -> W3TransactionSendingResult {
        return try swift.send(password: password, options: options?.swift, onBlock: onBlock).objc
    }
    
    /**
     *Calls a function of the smart-contract and parses the returned data to native objects.*
     
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: W3Response from node
     - Important: This call is synchronous
     
     */
    
    @discardableResult
    @objc public func call(options: W3Options?, onBlock: String = "latest") throws -> W3Response {
        return try swift.call(options: options?.swift, onBlock: onBlock).objc
    }
    
    /**
     *Estimates gas required to execute the transaction. Setting a gas limit lower than the estimate will most likely result in a failed transaction. If this call returns an error it can also indicate that transaction is invalid as itself.*
     
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: gas price
     - Important: This call is synchronous
     
     */
    @objc public func estimateGas(options: W3Options?, onBlock: String = "latest") throws -> W3UInt {
        return try swift.estimateGas(options: options?.swift, onBlock: onBlock).objc
    }
    
    /**
     *Assembles (but does not sign!) a transaction by fetching the nonce value and applying provided options.*
     
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: transaction
     - Important: This call is synchronous
     
     */
    @objc public func assemble(options: W3Options?, onBlock: String = "pending") throws -> W3EthereumTransaction {
        return try swift.assemble(options: options?.swift, onBlock: onBlock).objc
    }
    /**
     *Assembles (but does not sign!) a transaction by fetching the nonce value and applying provided options.*
     
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: Promise for ethereum transaction
     */
    @objc public func assembleAsync(options: W3Options?, onBlock: String = "pending", completion: @escaping  (W3EthereumTransaction?,Error?)->()) {
        swift.assemblePromise(options: options?.swift, onBlock: onBlock)
            .done { completion($0.objc,nil) }
            .catch { completion(nil, $0) }
    }
    
    /**
     *Send a prepared transaction to the blockchain. Internally checks the nonce for a sending account, assigns it, get a gas estimate and signs a transaction either locally or on the remote node.*
     
     - Parameter password: Password for a private key if transaction is signed locally
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: Promise for TransactionResult which contains transaction hash and other info
     */
    @objc public func sendAsync(password: String = "BANKEXFOUNDATION", options: W3Options?, onBlock: String = "pending", completion: @escaping  (W3TransactionSendingResult?,Error?)->()) {
        
        swift.sendPromise(password: password, options: options?.swift, onBlock: onBlock)
            .done { completion($0.objc,nil) }
            .catch { completion(nil, $0) }
    }
    
    /**
     *Calls a function of the smart-contract and parses the returned data to native objects.*
     
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: Promise for W3Response from node
     */
    
    @objc public func callAsync(options: W3Options?, onBlock: String = "latest", completion: @escaping  (W3Response?,Error?)->()) {
        
        swift.callPromise(options: options?.swift, onBlock: onBlock)
            .done { completion($0.objc,nil) }
            .catch { completion(nil, $0) }
    }
    
    /**
     *Estimates gas required to execute the transaction. Setting a gas limit lower than the estimate will most likely result in a failed transaction. If this call returns an error it can also indicate that transaction is invalid as itself.*
     
     - Parameter options: Web3Options to override the previously assigned gas price, gas limit and value.
     - Parameter onBlock: String field determines if nonce value and the gas estimate are based on the state of a blockchain on the latest mined block ("latest") or the expected state after all the transactions in memory pool are applied ("pending"). Using "pending" allows to send transactions one after another without waiting for inclusion of the previous one in some block.
     
     - Returns: Promise for gas price
     */
    @objc public func estimateGasAsync(options: W3Options?, onBlock: String = "latest", completion: @escaping  (W3UInt?,Error?)->()) {
        
        swift.estimateGasPromise(options: options?.swift, onBlock: onBlock)
            .done { completion($0.objc,nil) }
            .catch { completion(nil, $0) }
    }
    
    
}
