//
//  JEncodable.swift
//  Tests
//
//  Created by Dmitry on 18/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import BigInt

public protocol JEncodable {
    func jsonRpcValue(with network: NetworkProvider) -> Any
}

extension Int: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return self
    }
}
extension BigUInt: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return "0x" + String(self, radix: 16, uppercase: false)
    }
}
extension Address: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return address
    }
}
extension Bool: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return self
    }
}
extension String: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return self
    }
}
extension BlockNumber: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return promise(network: network).jsonRpcValue(with: network)
    }
}
extension Data: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return hex.withHex
    }
}
extension Promise: JEncodable where T: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return map { $0 as Any }
    }
}
extension Dictionary: JEncodable where Value: JEncodable {
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return mapValues { $0.jsonRpcValue(with: network) }
    }
}
open class JDictionary: JEncodable {
    public var dictionary = [String: JEncodable]()
    
    public init() {}
    open func at(_ key: String) -> JsonRpcDictionaryKey {
        return JsonRpcDictionaryKey(parent: self, key: key)
    }
    open func set(_ key: String, _ value: JEncodable?) -> Self {
        return self
    }
    open func set(_ key: String, _ value: JEncodable) -> Self {
        dictionary[key] = value
        return self
    }
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return dictionary.mapValues { $0.jsonRpcValue(with: network) }
    }
}
open class JArray: JEncodable {
    public var array = [JEncodable]()
    
    public init() {}
    public init(_ array: [JEncodable]) {
        guard !array.isEmpty else { return }
        self.array = array
    }
    open func nilIfEmpty() -> Self? {
        return array.isEmpty ? nil : self
    }
    open func append(_ element: JEncodable) -> Self {
        array.append(element)
        return self
    }
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return array.map { $0.jsonRpcValue(with: network) }
    }
}
public struct JsonRpcDictionaryKey {
    public var parent: JDictionary
    public var key: String
    public func set(_ value: JEncodable) {
        parent.dictionary[key] = value
    }
    // do nothing
    public func set(_ value: JEncodable?) {}
    public func dictionary(_ build: (JDictionary)->()) {
        let dictionary = JDictionary()
        build(dictionary)
        set(dictionary)
    }
}
