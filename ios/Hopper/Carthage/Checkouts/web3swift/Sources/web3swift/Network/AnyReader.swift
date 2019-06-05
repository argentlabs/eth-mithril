//
//  DictionaryReader.swift
//  web3swift-iOS
//
//  Created by Dmitry on 28/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

extension BigUInt {
    private typealias Error = AnyReader.Error
    init(dictionary value: Any) throws {
        if let string = value as? String {
            if string.isHex {
                guard let number = BigUInt(string.withoutHex, radix: 16) else { throw Error.unconvertible(value: string, expected: "BigInt") }
                self = number
            } else {
                guard let number = BigUInt(string) else { throw Error.unconvertible(value: string, expected: "BigInt") }
                self = number
            }
        } else if let value = value as? Int {
            self = BigUInt(value)
        } else {
            throw Error.unconvertible(value: value, expected: "BigInt")
        }
    }
}

/**
 Dictionary Reader
 
 Used for easy dictionary parsing
 */
public class AnyReader {
    /// Errors
    public enum Error: Swift.Error {
        /// Throws if key cannot be found in a dictionary
        case notFound(key: String, dictionary: [String: Any])
        /// Throws if key cannot be found in a dictionary
        case elementNotFound(index: Int, array: [Any])
        /// Throws if value cannot be converted to desired type
        case unconvertible(value: Any, expected: String)
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case let .notFound(key, dictionary):
                return "Cannot find object at key \(key) in \(dictionary)"
            case let .elementNotFound(index, array):
                return "Cannot find element at index \(index) in \(array)"
            case let .unconvertible(value, expected):
                return "Cannot convert \(value) to \(expected)"
            }
        }
    }
    /// Raw value
    public var raw: Any
    /// Init with any value
    public init(_ data: Any) {
        self.raw = data
    }
    /// Init with any value
    public init(json data: Data) throws {
        self.raw = try JSONSerialization.jsonObject(with: data, options: [])
    }
    
    func unconvertible(to expected: String) -> Error {
        return Error.unconvertible(value: raw, expected: expected)
    }
    
    /// Tries to represent raw as dictionary and gets value at key from it
    /// - Parameter key: Dictionary key
    /// - Returns: DictionaryReader with found value
    /// - Throws: DictionaryReader.Error(if unconvertible to [String: Any] or if key not found in dictionary)
    public func at(_ key: String) throws -> AnyReader {
        guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
        guard let value = data[key] else { throw Error.notFound(key: key, dictionary: data) }
        return AnyReader(value)
    }
    
    /// Tries to represent raw as dictionary and gets value at key from it
    /// - Parameter key: Dictionary key
    /// - Returns: DictionaryReader with found value or nil if not found
    /// - Throws: DictionaryReader.Error(if unconvertible to [String: Any] or if key not found in dictionary)
    public func optional(_ key: String) throws -> AnyReader? {
        guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
        guard let value = data[key] else { throw Error.notFound(key: key, dictionary: data) }
        return AnyReader(value)
    }
    
    /// Tries to represent raw as dictionary and calls forEach on it.
    /// Same as [String: Any]().map { key, value in ... }
    /// - Parameter block: callback for every key and value of dictionary
    /// - Throws: DictionaryReader.Error(if unconvertible to [String: Any])
    public func dictionary(body: (AnyReader, AnyReader) throws -> ()) throws {
        guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
        try data.forEach {
            try body(AnyReader($0), AnyReader($1))
        }
    }
    
    /// Tries to represent raw as array and calls forEach on it.
    /// Same as [Any]().forEach { value in ... }
    /// - Parameter body: Callback for every value in array
    /// - Throws: DictionaryReader.Error(if unconvertible to [Any])
    public func array(_ body: (AnyReader) throws -> ()) throws {
        guard let data = raw as? [Any] else { throw unconvertible(to: "[Any]") }
        try data.forEach {
            try body(AnyReader($0))
        }
    }
    
    /// Tries to represent raw as array.
    /// - Throws: DictionaryReader.Error(if unconvertible to [Any])
    public func array() throws -> [AnyReader] {
        guard let data = raw as? [Any] else { throw unconvertible(to: "[Any]") }
        return data.map(AnyReader.init)
    }
    
    /// Tries to represent raw as array and converts it to Array<T>
    /// - Throws: DictionaryReader.Error(if unconvertible to [Any])
    public func array<T>(_ mapped: (AnyReader) throws -> (T)) throws -> [T] {
        guard let data = raw as? [Any] else { throw unconvertible(to: "[Any]") }
        return try data.map { try mapped(AnyReader($0)) }
    }

    /// Tries to represent raw as string then string as address
    /// - Returns: Address
    /// - Throws: DictionaryReader.Error.unconvertible
    public func address() throws -> Address {
        let string = try self.string()
        guard string.count >= 42 else { throw unconvertible(to: "Address") }
        guard string != "0x" && string != "0x0" else { return .contractDeployment }
        let address = Address(String(string[..<42]))
        // already checked for size. so don't need to check again for address.isValid
        // guard address.isValid else { throw Error.unconvertible }
        return address
    }
    
    /// Tries to represent raw as string
    /// - Returns: String
    /// - Throws: DictionaryReader.Error.unconvertible
    @discardableResult
    public func string() throws -> String {
        if let value = raw as? String {
            return value
        } else if let value = raw as? Int {
            return value.description
        } else {
            throw unconvertible(to: "String")
        }
    }
    
    /// Tries to represent raw as string
    /// - Returns: String
    /// - Throws: DictionaryReader.Error.unconvertible
    @discardableResult
    public func bool() throws -> Bool {
        if let value = raw as? Bool {
            return value
        } else if let value = raw as? Int {
            return value != 0
        } else if let value = raw as? String {
            switch value {
            case "true":
                return true
            case "false":
                return false
            default:
                throw unconvertible(to: "Bool")
            }
        } else {
            throw unconvertible(to: "Bool")
        }
    }
    
    /// Tries to represent raw as data or as hex string then as data
    /// - Throws: DictionaryReader.Error.unconvertible
    @discardableResult
    public func data() throws -> Data {
        if let value = raw as? Data {
            return value
        } else {
            return try string().hex
        }
    }
    
    /// Tries to represent raw as BigUInt.
    ///
    /// Can convert:
    /// - "0x12312312"
    /// - 0x123123
    /// - "123123123"
    /// - Throws: DictionaryReader.Error.unconvertible
    @discardableResult
    public func uint256() throws -> BigUInt {
        if let value = raw as? String {
            if value.isHex {
                guard let value = BigUInt(value.withoutHex, radix: 16) else { throw unconvertible(to: "BigUInt") }
                return value
            } else {
                guard let value = BigUInt(value) else { throw unconvertible(to: "BigUInt") }
                return value
            }
        } else if let value = raw as? Int {
            return BigUInt(value)
        } else {
            throw unconvertible(to: "BigUInt")
        }
    }
    
    /// Tries to represent raw as Int.
    ///
    /// Can convert:
    /// - "0x12312312"
    /// - 0x123123
    /// - "123123123"
    /// - Throws: DictionaryReader.Error.unconvertible
    @discardableResult
    public func int() throws -> Int {
        if let value = raw as? Int {
            return value
        } else if let value = raw as? String {
            if value.isHex {
                guard let value = Int(value.withoutHex, radix: 16) else { throw unconvertible(to: "Int") }
                return value
            } else {
                guard let value = Int(value) else { throw unconvertible(to: "Int") }
                return value
            }
        } else {
            throw unconvertible(to: "Int")
        }
    }
    
    
    /// Tries to represent raw as Int.
    ///
    /// Can convert:
    /// - "0x12312312"
    /// - 0x123123
    /// - "123123123"
    /// - Throws: DictionaryReader.Error.unconvertible
    @discardableResult
    public func uint64() throws -> UInt64 {
        if let value = raw as? Int {
            return UInt64(value)
        } else if let value = raw as? String {
            if value.isHex {
                guard let value = UInt64(value.withoutHex, radix: 16) else { throw unconvertible(to: "UInt64") }
                return value
            } else {
                guard let value = UInt64(value) else { throw unconvertible(to: "UInt64") }
                return value
            }
        } else {
            throw unconvertible(to: "Int")
        }
    }
    
    func isNull() -> Bool {
        return raw is NSNull
    }
    
    func contains(_ key: String) -> Bool {
        return (try? at(key)) != nil
    }
    
    func json() throws -> Data {
        return try JSONSerialization.data(withJSONObject: raw, options: .prettyPrinted)
    }
}

extension AnyReader: CustomStringConvertible {
    public var description: String {
        return "\(raw)"
    }
}

extension Dictionary where Key == String, Value == Any {
    func notFound(at key: String) -> Error {
        return AnyReader.Error.notFound(key: key, dictionary: self)
    }
    var json: Data {
        return try! JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
    var jsonDescription: String {
        return json.string
    }
    /// - Parameter key: Dictionary key
    /// - Returns: DictionaryReader with found value
    /// - Throws: DictionaryReader.Error(if key not found in dictionary)
    public func at(_ key: String) throws -> AnyReader {
        guard let value = self[key] else { throw notFound(at: key) }
        return AnyReader(value)
    }
}

extension Array where Element == AnyReader {
    func notFound(at index: Int) -> Error {
        return AnyReader.Error.elementNotFound(index: index, array: self)
    }
    func at(_ index: Int) throws -> AnyReader {
        guard index >= 0 && index < count else { throw notFound(at: index) }
        return self[index]
    }
}

/// Some chains
enum ParsingError: Error {
    case stringPrefix(string: String, shouldHavePrefix: String)
    case stringEquals(string: String, shouldEqual: String)
}
extension String {
    @discardableResult
    func starts(with prefix: String) throws -> String {
        guard hasPrefix(prefix) else {
            throw ParsingError.stringPrefix(string: self, shouldHavePrefix: prefix)
        }
        return self
    }
    @discardableResult
    func equals(_ string: String) throws -> String {
        guard self == string else {
            throw ParsingError.stringEquals(string: self, shouldEqual: string)
        }
        return self
    }
}
