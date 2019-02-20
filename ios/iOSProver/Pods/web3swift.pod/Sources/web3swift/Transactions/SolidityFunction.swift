//
//  SolidityFunction.swift
//  web3swift
//
//  Created by Dmitry on 12/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit

/// Protocol thats allows to convert types to solidity data
public protocol SolidityDataRepresentable {
    /// - Returns: Solidity compatible data
    var solidityData: Data { get }
    /// - Returns:
    /// `true`: one element equals one byte.
    /// `false`: one element equals 32 bytes.
    /// default: false
    var isSolidityBinaryType: Bool { get }
}
public extension SolidityDataRepresentable {
    var isSolidityBinaryType: Bool { return false }
}

extension BinaryInteger {
    /// - Returns: Solidity compatible data
    public var solidityData: Data { return BigInt(self).abiEncode(bits: 256) }
}
extension Int: SolidityDataRepresentable {}
extension Int8: SolidityDataRepresentable {}
extension Int16: SolidityDataRepresentable {}
extension Int32: SolidityDataRepresentable {}
extension Int64: SolidityDataRepresentable {}
extension BigInt: SolidityDataRepresentable {}
extension UInt: SolidityDataRepresentable {}
extension UInt8: SolidityDataRepresentable {}
extension UInt16: SolidityDataRepresentable {}
extension UInt32: SolidityDataRepresentable {}
extension UInt64: SolidityDataRepresentable {}
extension BigUInt: SolidityDataRepresentable {}
extension Address: SolidityDataRepresentable {
    public var solidityData: Data { return addressData.setLengthLeft(32)! }
}
extension Data: SolidityDataRepresentable {
    public var solidityData: Data { return self }
    public var isSolidityBinaryType: Bool { return true }
}
extension String: SolidityDataRepresentable {
    public var solidityData: Data { return data }
    public var isSolidityBinaryType: Bool { return true }
}
extension Array: SolidityDataRepresentable where Element == SolidityDataRepresentable {
    public var solidityData: Data {
        var data = Data(capacity: 32 * count)
        for element in self {
            data.append(element.solidityData)
        }
        return data
    }
    func data(function: String) -> Data {
        var data = Data(capacity: count * 32 + 4)
        data.append(function.keccak256()[0..<4])
        for element in self {
            data.append(element.solidityData)
        }
        return data
    }
}

extension Address {
    /// Prepares transaction to send. Estimates gas usage, nonce and gas price.
    ///
    /// - Parameters:
    ///   - function: Smart contract function
    ///   - arguments: Function arguments
    ///   - web3: Node address. default: .default
    ///   - options: Transaction options. default: nil
    ///   - onBlock: Future transaction block. default: "pending"
    /// - Returns: Promise for the assembled transaction
    public func assemble(_ function: String, _ arguments: [Any], web3: Web3 = .default, options: Web3Options? = nil, onBlock: String = "pending") -> Promise<EthereumTransaction> {
        let options = web3.options.merge(with: options)
        
        let function = try! SolidityFunction(function: function)
        let data = function.encode(arguments as! [SolidityDataRepresentable])
        var assembledTransaction = EthereumTransaction(to: self, data: data, options: options)
        let queue = web3.requestDispatcher.queue
        let returnPromise = Promise<EthereumTransaction> { seal in
            guard let from = options.from else {
                seal.reject(Web3Error.inputError("No 'from' field provided"))
                return
            }
            var optionsForGasEstimation = Web3Options()
            optionsForGasEstimation.from = options.from
            optionsForGasEstimation.to = options.to
            optionsForGasEstimation.value = options.value
            let nonce = web3.eth.getTransactionCountPromise(address: from, onBlock: onBlock)
            let gasEstimate = web3.eth.estimateGasPromise(assembledTransaction, options: optionsForGasEstimation, onBlock: onBlock)
            let gasPrice = web3.eth.getGasPricePromise()
            nonce.catch(on: queue) { error in
                seal.reject(Web3Error.processingError("Failed to fetch nonce"))
            }
            gasEstimate.catch(on: queue) { error in
                seal.reject(Web3Error.processingError("Failed to fetch gas estimate"))
            }
            gasPrice.catch(on: queue) { error in
                seal.reject(Web3Error.processingError("Failed to fetch gas price"))
            }
            
            _ = when(fulfilled: nonce,gasEstimate,gasPrice).done(on: queue) { _ in
                let estimate = Web3Options.smartMergeGasLimit(originalOptions: options, extraOptions: options, gasEstimate: gasEstimate.value!)
                assembledTransaction.nonce = nonce.value!
                assembledTransaction.gasLimit = estimate
                let finalGasPrice = Web3Options.smartMergeGasPrice(originalOptions: options, extraOptions: options, priceEstimate: gasPrice.value!)
                assembledTransaction.gasPrice = finalGasPrice
                seal.fulfill(assembledTransaction)
            }
        }
        return returnPromise
    }
    
    /// Sends transaction to call mutable smart contract function.
    /// - Important: Set the sender in Web3Options.from
    ///
    /// - Parameters:
    ///   - function: Smart contract function
    ///   - arguments: Function arguments
    ///   - password: Password do decrypt your private key
    ///   - web3: Node address. default: .default
    ///   - options: Web3Options. default: nil
    ///   - onBlock: Gas estimation block. default: "pending"
    /// - Returns: Promise for sent transaction and its hash
    public func send(_ function: String, _ arguments: Any..., password: String = "BANKEXFOUNDATION", web3: Web3 = .default, options: Web3Options? = nil, onBlock: String = "pending") -> Promise<TransactionSendingResult> {
        return send(function, arguments, password: password, web3: web3, options: options, onBlock: onBlock)
    }
    
    /// Sends transaction to call mutable smart contract function.
    /// - Important: Set the sender in Web3Options.from
    ///
    /// - Parameters:
    ///   - function: Smart contract function
    ///   - arguments: Function arguments
    ///   - password: Password do decrypt your private key
    ///   - web3: Node address. default: .default
    ///   - options: Web3Options. default: nil
    ///   - onBlock: Gas estimation block. default: "pending"
    /// - Returns: Promise for sent transaction and its hash
    public func send(_ function: String, _ arguments: [Any], password: String = "BANKEXFOUNDATION", web3: Web3 = .default, options: Web3Options? = nil, onBlock: String = "pending") -> Promise<TransactionSendingResult> {
        let options = web3.options.merge(with: options)
        let queue = web3.requestDispatcher.queue
        return assemble(function, arguments, web3: web3, options: options, onBlock: onBlock).then(on: queue) { transaction throws -> Promise<TransactionSendingResult> in
            var cleanedOptions = Web3Options()
            cleanedOptions.from = options.from
            cleanedOptions.to = options.to
            return web3.eth.sendTransactionPromise(transaction, options: cleanedOptions, password: password)
        }
    }
    
    
    /// Call a smart contract function.
    ///
    /// - Parameters:
    ///   - function: Function to call
    ///   - arguments: Function arguments
    ///   - web3: Node address. default: .default
    ///   - options: Web3Options. default: nil
    ///   - onBlock: Call block. default: "latest"
    /// - Returns: Promise for function result
    public func call(_ function: String, _ arguments: Any..., web3: Web3 = .default, options: Web3Options? = nil, onBlock: String = "latest") -> Promise<SolidityDataReader> {
        return call(function, arguments, web3: web3, options: options, onBlock: onBlock)
    }
    
    /// Call a smart contract function.
    ///
    /// - Parameters:
    ///   - function: Function to call
    ///   - arguments: Function arguments
    ///   - web3: Node address. default: .default
    ///   - options: Web3Options. default: nil
    ///   - onBlock: Call block. default: "latest"
    /// - Returns: Promise for function result
    public func call(_ function: String, _ arguments: [Any], web3: Web3 = .default, options: Web3Options? = nil, onBlock: String = "latest") -> Promise<SolidityDataReader> {
        let options = web3.options.merge(with: options)
        let function = try! SolidityFunction(function: function)
        let data = function.encode(arguments as! [SolidityDataRepresentable])
        let assembledTransaction = EthereumTransaction(to: self, data: data, options: options)
        let queue = web3.requestDispatcher.queue
        return Promise<SolidityDataReader> { seal in
            var optionsForCall = Web3Options()
            optionsForCall.from = options.from
            optionsForCall.to = options.to
            optionsForCall.value = options.value
            web3.eth.callPromise(assembledTransaction, options: optionsForCall, onBlock: onBlock)
                .done(on: queue) { seal.fulfill(SolidityDataReader($0)) }
                .catch(on: queue, seal.reject)
        }
    }
    
    
    /// Estimates gas price for transaction
    ///
    /// - Parameters:
    ///   - function: Smart contract function
    ///   - arguments: Function arguments
    ///   - web3: Node address. default: .default
    ///   - options: Web3Options. default: nil
    ///   - onBlock: Gas estimation block. default: "latest"
    /// - Returns: Promise for estimated gas
    public func estimateGas(_ function: String, _ arguments: Any..., web3: Web3 = .default, options: Web3Options? = nil, onBlock: String = "latest") -> Promise<BigUInt> {
        return estimateGas(function, arguments, web3: web3, options: options, onBlock: onBlock)
    }
    
    /// Estimates gas price for transaction
    ///
    /// - Parameters:
    ///   - function: Smart contract function
    ///   - arguments: Function arguments
    ///   - web3: Node address. default: .default
    ///   - options: Web3Options. default: nil
    ///   - onBlock: Gas estimation block. default: "latest"
    /// - Returns: Promise for estimated gas
    public func estimateGas(_ function: String, _ arguments: [Any], web3: Web3 = .default, options: Web3Options? = nil, onBlock: String = "latest") -> Promise<BigUInt> {
        let options = web3.options.merge(with: options)
        let function = try! SolidityFunction(function: function)
        let data = function.encode(arguments as! [SolidityDataRepresentable])
        let assembledTransaction = EthereumTransaction(to: self, data: data, options: options)
        let queue = web3.requestDispatcher.queue
        return Promise<BigUInt> { seal in
            var optionsForGasEstimation = Web3Options()
            optionsForGasEstimation.from = options.from
            optionsForGasEstimation.to = options.to
            optionsForGasEstimation.value = options.value
            web3.eth.estimateGasPromise(assembledTransaction, options: optionsForGasEstimation, onBlock: onBlock)
                .done(on: queue, seal.fulfill)
                .catch(on: queue, seal.reject)
        }
    }
}
