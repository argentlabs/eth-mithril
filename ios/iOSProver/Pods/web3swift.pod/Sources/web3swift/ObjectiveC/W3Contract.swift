//
//  W3Contract.swift
//  web3swift
//
//  Created by Dmitry on 10/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension ContractV2.EventFilter {
    public var objc: W3ContractEventFilter {
        return W3ContractEventFilter(self)
    }
}
@objc public class W3ContractEventFilter: NSObject, SwiftContainer {
    public var swift: ContractV2.EventFilter
    public required init(_ swift: ContractV2.EventFilter) {
        self.swift = swift
    }
    
    @objc public var parameterName: String {
        get { return swift.parameterName }
        set { swift.parameterName = newValue }
    }
    @objc public var parameterValues: [AnyObject] {
        get { return swift.parameterValues }
        set { swift.parameterValues = newValue }
    }
}
@objc public class W3ContractParsedEvent: NSObject {
    @objc public let eventName: String?
    @objc public let eventData: [String: Any]?
    init(eventName: String?, eventData: [String: Any]?) {
        self.eventName = eventName
        self.eventData = eventData
    }
}

extension ContractProtocol {
    public var objc: W3Contract {
        return W3Contract(self as! ContractV2)
    }
}

@objc public class W3Contract: NSObject, W3OptionsInheritable, SwiftContainer {
    public var swift: ContractV2
    var _swiftOptions: Web3Options {
        get { return swift.options }
        set { swift.options = newValue }
    }
    public required init(_ swift: ContractV2) {
        self.swift = swift
        super.init()
        options = W3Options(object: self)
    }
    
    @objc public var allEvents: [String] {
        return swift.allEvents
    }
    
    @objc public var allMethods: [String] {
        return swift.allMethods
    }
    
    @objc public var address: W3Address? {
        get { return swift.address?.objc }
        set { swift.address = newValue?.swift }
    }
    
    @objc public var options: W3Options!
    
    @objc public init(_ abiString: String, at address: W3Address? = nil) throws {
        swift = try ContractV2(abiString, at: address?.swift)
    }
    
    @objc public func deploy(bytecode: Data, parameters: [Any], extraData: Data?, options: W3Options?) throws -> W3EthereumTransaction {
        let extraData = extraData ?? Data()
        return try swift.deploy(bytecode: bytecode, parameters: parameters.swift, extraData: extraData, options: options?.swift).objc
    }
    
    @objc public func method(_ method: String, parameters: [Any], extraData: Data?, options: W3Options?) throws -> W3EthereumTransaction {
        let extraData = extraData ?? Data()
        return try swift.method(method, parameters: parameters.swift, extraData: extraData, options: options?.swift).objc
    }
    
    @objc public func parseEvent(_ eventLog: W3EventLog) -> W3ContractParsedEvent {
        let (name,data) = swift.parseEvent(eventLog.swift)
        return W3ContractParsedEvent(eventName: name, eventData: data)
    }
    
    @objc public func testBloomForEventPrecence(eventName: String, bloom: W3EthereumBloomFilter) -> Bool {
        return swift.testBloomForEventPrecence(eventName: eventName, bloom: bloom.swift) ?? false
    }
    
    @objc public func decodeReturnData(_ method: String, data: Data) -> [String: Any]? {
        return swift.decodeReturnData(method, data: data)
    }
    
    @objc public func decodeInputData(_ method: String, data: Data) -> [String: Any]? {
        return swift.decodeInputData(method, data: data)
    }
    
    @objc public func decodeInputData(_ data: Data) -> [String: Any]? {
        return swift.decodeInputData(data)
    }
}
