//
//  ContractABIv2.swift
//  web3swift
//
//  Created by Alexander Vlasov on 04.04.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Swift class that represents a solidity smart contract
public struct ContractV2: ContractProtocol {
    public var allEvents: [String] {
		return events.keys.compactMap { $0 }
    }
    
    public var allMethods: [String] {
		return methods.keys.compactMap { $0 }
    }
    
    /// Filter for contract events
    public struct EventFilter {
        /// Event name
        public var parameterName: String
        /// Event parameters
        public var parameterValues: [AnyObject]
    }
    
    public var address: Address?
    var _abi: [ABIv2.Element]
    
    /// Smart contract methods
    public var methods: [String: ABIv2.Element] {
        var toReturn = [String: ABIv2.Element]()
        for m in _abi {
            switch m {
            case let .function(function):
                guard let name = function.name else { continue }
                toReturn[name] = m
            default:
                continue
            }
        }
        return toReturn
    }
    
    /// Smart contract init arguments
    public var constructor: ABIv2.Element? {
        var toReturn: ABIv2.Element?
        for m in _abi {
            if toReturn != nil {
                break
            }
            switch m {
            case .constructor:
                toReturn = m
                break
            default:
                continue
            }
        }
        if toReturn == nil {
            let defaultConstructor = ABIv2.Element.constructor(ABIv2.Element.Constructor(inputs: [], constant: false, payable: false))
            return defaultConstructor
        }
        return toReturn
    }
    
    /// Smart contract events
    public var events: [String: ABIv2.Element.Event] {
        var toReturn = [String: ABIv2.Element.Event]()
        for m in _abi {
            switch m {
            case let .event(event):
                let name = event.name
                toReturn[name] = event
            default:
                continue
            }
        }
        return toReturn
    }

    public var options: Web3Options = .default

    /// Init with json ABI
    public init(_ abiString: String, at address: Address? = nil) throws {
        let abi = try JSONDecoder().decode([ABIv2.Record].self, from: abiString.data)
        let abiNative = try abi.map({ (record) -> ABIv2.Element in
            try record.parse()
        })
        _abi = abiNative
        self.address = address
    }
    
    /// Init with abi array
    public init(abi: [ABIv2.Element]) {
        _abi = abi
    }
    
    /// Init with abi array and address
    public init(abi: [ABIv2.Element], at: Address) {
        _abi = abi
        address = at
    }
    
    /// Method errors
    public enum MethodError: Error {
        /// Provide contract address to send transcation
        case noAddress
        /// You have to set the gas limit
        case noGasLimit
        /// You have to set the gas price
        case noGasPrice
        /// Provide constructor to deploy smart contract
        case noConstructor
        /// Smart contract method not found
        case notFound
        /// Cannot encode data with given parameters
        case cannotEncodeDataWithGivenParameters
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case .noAddress:
                return "Provide contract address to send transcation"
            case .noGasLimit:
                return "You have to set the gas limit"
            case .noGasPrice:
                return "You have to set the gas price"
            case .noConstructor:
                return "Provide constructor to deploy smart contract"
            case .notFound:
                return "Smart contract method not found"
            case .cannotEncodeDataWithGivenParameters:
                return "Cannot encode data with given parameters"
            }
        }
    }

    /// Deploy smart contract with provided bytecode
    ///
    /// - Parameters:
    ///   - bytecode: Smart contract bytecode
    ///   - args: Init arguments
    ///   - extraData: Extra data
    ///   - options: Transaction options
    /// - Returns: Transaction and its hash
    public func deploy(bytecode: Data, args: Any..., extraData: Data = Data(), options: Web3Options?) throws -> EthereumTransaction {
        return try deploy(bytecode: bytecode, parameters: args, extraData: extraData, options: options)
    }

    /// Deploy smart contract with provided bytecode
    ///
    /// - Parameters:
    ///   - bytecode: Smart contract bytecode
    ///   - args: Init arguments
    ///   - extraData: Extra data
    ///   - options: Transaction options
    /// - Returns: Transaction and its hash
    public func deploy(bytecode: Data, parameters: [Any], extraData: Data = Data(), options: Web3Options?) throws -> EthereumTransaction {
        let to: Address = .contractDeployment
        let options = self.options.merge(with: options)
        guard let gasLimit = options.gasLimit else { throw MethodError.noGasLimit }
        guard let gasPrice = options.gasPrice else { throw MethodError.noGasPrice }
        let value = options.value ?? 0

        guard let constructor = self.constructor else { throw MethodError.noConstructor }
        guard let encodedData = constructor.encodeParameters(parameters as [AnyObject]) else { throw MethodError.cannotEncodeDataWithGivenParameters }
        var fullData = bytecode
        if encodedData != Data() {
            fullData.append(encodedData)
        } else if extraData != Data() {
            fullData.append(extraData)
        }
        return EthereumTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: fullData)
    }

    /// Returns smart contract method with provided name
    ///
    /// - Parameters:
    ///   - bytecode: Smart contract bytecode
    ///   - args: Init arguments
    ///   - extraData: Extra data
    ///   - options: Transaction options
    /// - Returns: Transaction
    public func method(_ name: String, args: Any..., extraData: Data = Data(), options: Web3Options?) throws -> EthereumTransaction {
        return try method(name, parameters: args, extraData: extraData, options: options)
    }
    
    /// Returns smart contract method with provided name
    ///
    /// - Parameters:
    ///   - bytecode: Smart contract bytecode
    ///   - args: Init arguments
    ///   - extraData: Extra data
    ///   - options: Transaction options
    /// - Returns: Transaction
    public func method(_ name: String, parameters: [Any], extraData: Data = Data(), options: Web3Options?) throws -> EthereumTransaction {
        var to: Address
        let options = self.options.merge(with: options)
        if let address = address {
            to = address
        } else if let address = options.to, address.isValid {
            to = address
        } else {
            throw MethodError.noAddress
        }
        guard let gasLimit = options.gasLimit else { throw MethodError.noGasLimit }
        guard let gasPrice = options.gasPrice else { throw MethodError.noGasPrice }
        let value = options.value ?? 0

        if name == "fallback" {
            return EthereumTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: extraData)
        } else {
            guard let abiMethod = methods[name] else { throw MethodError.notFound }
            guard let encodedData = abiMethod.encodeParameters(parameters as [AnyObject]) else { throw MethodError.cannotEncodeDataWithGivenParameters }
            return EthereumTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: encodedData)
        }
    }

    
    /// Parses smart contract event
    ///
    /// - Parameter eventLog: encoded event
    /// - Returns: Event name and its data
    public func parseEvent(_ eventLog: EventLog) -> (eventName: String?, eventData: [String: Any]?) {
        for (eName, ev) in events {
            if !ev.anonymous {
                if eventLog.topics[0] != ev.topic {
                    continue
                } else {
                    let parsed = ev.decodeReturnedLogs(eventLog)
                    if parsed != nil {
                        return (eName, parsed!)
                    }
                }
            } else {
                let parsed = ev.decodeReturnedLogs(eventLog)
                if parsed != nil {
                    return (eName, parsed!)
                }
            }
        }
        return (nil, nil)
    }
    
    /// Returns nil if there is no event with that name.
    public func testBloomForEventPrecence(eventName: String, bloom: EthereumBloomFilter) -> Bool? {
        guard let event = events[eventName] else { return nil }
        guard !event.anonymous else { return true }
        let eventOfSuchTypeIsPresent = bloom.test(topic: event.topic)
        return eventOfSuchTypeIsPresent
    }
    
    public func decodeReturnData(_ method: String, data: Data) -> [String: Any]? {
        guard method != "fallback" else { return [:] }
        guard let function = methods[method] else { return nil }
        guard case .function = function else { return nil }
        return function.decodeReturnData(data)
    }

    public func decodeInputData(_ method: String, data: Data) -> [String: Any]? {
        guard method != "fallback" else { return nil }
        guard let function = methods[method] else { return nil }
        switch function {
        case .function:
            return function.decodeInputData(data)
        case .constructor:
            return function.decodeInputData(data)
        default:
            return nil
        }
    }

    public func decodeInputData(_ data: Data) -> [String: Any]? {
        guard data.count % 32 == 4 else { return nil }
        let methodSignature = data[0 ..< 4]
        let foundFunction = _abi.filter { (m) -> Bool in
            switch m {
            case let .function(function):
                return function.methodEncoding == methodSignature
            default:
                return false
            }
        }
        guard foundFunction.count == 1 else {
            return nil
        }
        let function = foundFunction[0]
        return function.decodeInputData(Data(data[4 ..< data.count]))
    }
}
