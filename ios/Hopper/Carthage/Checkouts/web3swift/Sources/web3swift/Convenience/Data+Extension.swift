//
//  Data+Extension.swift
//  web3swift
//
//  Created by Alexander Vlasov on 15.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
//import CryptoSwift


/// Data errors
public enum DataError: Error {
    /// Throws if data cannot be converted to string
    case hexStringCorrupted(String)
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case let .hexStringCorrupted(string):
            return "Cannot convert hex string \"\(string)\" to data"
        }
    }
}

extension Data {
    public func sha256() -> Data {
        return digest(using: .sha256)
    }
}

public extension Data {
    /// Inits with array of type
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    var bytes: [UInt8] {
        return Array(self)
    }
    
    /// Represents data as array of type
    func toArray<T>(type _: T.Type) -> [T] {
        return withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count / MemoryLayout<T>.stride))
        }
    }

    /// Constant time comparsion between two data objects
    /// - seealso: [https://codahale.com/a-lesson-in-timing-attacks/](https://codahale.com/a-lesson-in-timing-attacks/)
    func constantTimeComparisonTo(_ other: Data?) -> Bool {
        guard let rhs = other else { return false }
        guard count == rhs.count else { return false }
        var difference = UInt8(0x00)
        for i in 0 ..< count { // compare full length
            difference |= self[i] ^ rhs[i] // constant time
        }
        return difference == UInt8(0x00)
    }

    /// Replaces all data bytes with zeroes.
	///
    /// This one needs because if data deinits, it still will stay in the memory until the override.
	///
	/// webswift uses that to clear private key from memory.
    /// - Parameter data: Data to be cleared
    static func zero(_ data: inout Data) {
        let count = data.count
        data.withUnsafeMutableBytes { (dataPtr: UnsafeMutablePointer<UInt8>) in
            dataPtr.initialize(repeating: 0, count: count)
        }
    }
    
    /// - Parameter length: Desired data length
    /// - Returns: Random data
    static func random(length: Int) -> Data {
        var data = Data(repeating: 0, count: length)
        var success = false
        #if !os(Linux)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0)
        }
        success = result == errSecSuccess
        #endif
        guard !success else { return data }
        data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt32>) in
            for i in 0..<length/4+1 {
                #if canImport(Darwin)
                bytes[i] = arc4random()
                #else
                bytes[i] = UInt32(bitPattern: rand())
                #endif
            }
        }
        return data
    }
    
    /// - Returns: Hex representation of data
    var hex: String {
        var string = ""
        withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            for i in 0..<count {
                string += bytes[i].hex
            }
        }
        return string
    }
    
    /// - Parameter separateEvery: Position where separator should be inserted.
    /// Counts per byte (not per character)
    /// - Parameter separator: Separator string
    /// - Returns: Hex representation of data
    func hex(separateEvery: Int, separator: String = " ") -> String {
        var string = ""
        string.reserveCapacity(count*2+count/separateEvery*separator.count)
        var separateCount = separateEvery
        withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            for i in 0..<count {
                string += bytes[i].hex
                separateCount -= 1
                if separateCount == 0 {
                    separateCount = separateEvery
                    string += separator
                }
            }
        }
        return string
    }
    
    /// - Returns: Data if string is in hex format
    /// Format: "0x0ba98fc797cfab9864bfac988fa", "0ba98fc797cfab9864bfac988fa"
    static func fromHex(_ hex: String) -> Data? {
        let string = hex.lowercased().withoutHex
        let data = string.hex
        if data.count == 0 {
            if string == "" {
                return Data()
            } else {
                return nil
            }
        }
        return data
    }
    
    /// - Returns: String (if its utf8 convertible) or hex string
    var string: String {
        return String(data: self, encoding: .utf8) ?? hex
    }
    
    
    /// - Returns: Number bits
    /// - Important: Returns max of 8 bytes for simplicity
    func bitsInRange(_ startingBit: Int, _ length: Int) -> UInt64 {
        let bytes = self[(startingBit / 8) ..< (startingBit + length + 7) / 8]
        let padding = Data(repeating: 0, count: 8 - bytes.count)
        let padded = bytes + padding
        var uintRepresentation = UInt64(bigEndian: padded.withUnsafeBytes { $0.pointee })
        uintRepresentation <<= startingBit % 8
        uintRepresentation >>= UInt64(64 - length)
        return uintRepresentation
    }
}

extension UInt8 {
    /// - Returns: Byte as hex string (from "00" to "ff")
    public var hex: String {
        if self < 0x10 {
            return "0" + String(self, radix: 16)
        } else {
            return String(self, radix: 16)
        }
    }
}
