//
//  SolidityTypes.swift
//  web3swift
//
//  Created by Dmitry on 16/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

/// Abi errors
public enum AbiError: Error {
    /// Solidity types (function, tuple) are currently not supported
    case unsupportedType
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case .unsupportedType:
            return "Solidity types (function, tuple) are currently not supported"
        }
    }
}

/**
 Solidity types bridge
 Used to generate solidity function input from swift types
 
 Types:
 ```
 uint8, uint16, uint24, uint32 ... uint248, uint256
 int8, int16, int24, int32 ... int248, int256
 function, address, bool, string
 bytes
 bytes1, bytes2, bytes3 ... bytes31, bytes32
 
 array: type[]
 array: type[1...]
 tuple(type1,type2,type3...)
 example: tuple(uint256,address,tuple(address,bytes32,uint256[64]))
 ```
 */
public class SolidityType: Equatable, CustomStringConvertible {
    static let uint256 = SUInt(bits: 256)
    static let address = SAddress()
    
    
    /// SolidityType array size
    public enum ArraySize {
        /// returns number of elements in a static array
        case `static`(Int)
        /// dynamic array
        case dynamic
        /// for non array types
        case notArray
    }
    /// returns true if type is static (not not uses data pointer in abi). default: true
    public var isStatic: Bool { return true }
    /// returns true if type is array. default: false
    public var isArray: Bool { return false }
    /// returns true if type is tuple. default: false
    /// - Important: tuples are not supported at this moment
    public var isTuple: Bool { return false }
    /// returns number of elements in array if it static. default: .notArray
    public var arraySize: ArraySize { return .notArray }
    /// returns type's subtype used in array types. default: nil
    public var subtype: SolidityType? { return nil }
    /// returns type memory usage. default: 32
    public var memoryUsage: Int { return 32 }
    /// returns default data for empty value. default: Data(repeating: 0, count: memoryUsage)
    public var `default`: Data { return Data(count: memoryUsage) }
    /// - Returns string representation of solidity type
    public var description: String { return "" }
    /// returns true if type input parameters is valid: default true
    public var isValid: Bool { return true }
    /// returns true if type is supported in web3swift
    public var isSupported: Bool { return true }
    
    public static func == (lhs: SolidityType, rhs: SolidityType) -> Bool {
        return lhs.description == rhs.description
    }
    
    /// Type conversion error
    public enum Error: Swift.Error {
        /// Unknown solidity type "\(string)"
        case corrupted(String)
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case let .corrupted(string):
                return "Unknown solidity type: \"\(string)\""
            }
        }
    }
    
    /// Represents solidity uintN type
    public class SUInt: SolidityType {
        var bits: Int
        init(bits: Int) {
            self.bits = bits
            super.init()
        }
        public override var description: String { return "uint\(bits)" }
        public override var isValid: Bool {
            return (8...256).contains(bits) && (bits & 0b111 == 0)
        }
    }
    
    /// Represents solidity intN type
    public class SInt: SUInt {
        public override var description: String { return "int\(bits)" }
    }
    
    /// Represents solidity address type
    public class SAddress: SolidityType {
        public override var description: String { return "address" }
    }
    
    /// Unsupported
    public class SFunction: SolidityType {
        public override var description: String { return "function" }
        public override var isSupported: Bool { return false }
    }
    
    /// Represents solidity bool type
    public class SBool: SolidityType {
        public override var description: String { return "bool" }
    }
    
    /// Represents solidity bytes[N] type
    public class SBytes: SolidityType {
        public override var description: String { return "bytes\(count)" }
        public override var isValid: Bool { return count > 0 && count <= 32 }
        var count: Int
        init(count: Int) {
            self.count = count
            super.init()
        }
    }
    
    /// Represents solidity bool[] type
    public class SDynamicBytes: SolidityType {
        public override var description: String { return "bytes" }
        public override var memoryUsage: Int { return 0 }
        public override var isStatic: Bool { return false }
    }
    
    /// Represents solidity string type
    public class SString: SolidityType {
        public override var description: String { return "string" }
        public override var isStatic: Bool { return false }
        public override var memoryUsage: Int { return 0 }
    }
    
    /// Represents solidity type[N] type
    public class SStaticArray: SolidityType {
        public override var description: String { return "\(type)[\(count)]" }
        public override var isStatic: Bool { return type.isStatic }
        public override var isArray: Bool { return true }
        public override var subtype: SolidityType? { return type }
        public override var arraySize: ArraySize { return .static(count) }
        public override var isValid: Bool { return type.isValid }
        public override var memoryUsage: Int {
            return 32 * count
        }
        var count: Int
        var type: SolidityType
        init(count: Int, type: SolidityType) {
            self.count = count
            self.type = type
            super.init()
        }
    }
    
    /// Represents solidity type[] type
    public class SDynamicArray: SolidityType {
        public override var description: String { return "\(type)[]" }
        public override var memoryUsage: Int { return 0 }
        public override var isStatic: Bool { return type.isStatic }
        public override var isArray: Bool { return true }
        public override var subtype: SolidityType? { return type }
        public override var arraySize: ArraySize { return .dynamic }
        public override var isValid: Bool { return type.isValid }
        var type: SolidityType
        init(type: SolidityType) {
            self.type = type
            super.init()
        }
    }
    
    /**
     Unsupported. But you can still parse it using
     ```
     let type = SolidityType.scan("tuple(uint256,uint256")
     ```
     */
    public class SolidityTuple: SolidityType {
        public override var description: String { return "tuple(\(types.map { $0.description }.joined(separator: ",")))" }
        public override var isStatic: Bool { return types.allSatisfy { $0.isStatic } }
        public override var isTuple: Bool { return true }
        public override var isSupported: Bool { return false }
        public override var memoryUsage: Int {
            guard isStatic else { return 32 }
            return types.reduce(0, { $0 + $1.memoryUsage })
        }
        public override var isValid: Bool { return types.allSatisfy { $0.isValid } }
        var types: [SolidityType]
        init(types: [SolidityType]) {
            self.types = types
            super.init()
        }
    }
}

// MARK:- String to SolidityType
extension SolidityType {
    private static var knownTypes: [String: SolidityType] = [
        "function": SFunction(),
        "address": SAddress(),
        "string": SString(),
        "bool": SBool(),
        "uint": SUInt(bits: 256),
        "int": SInt(bits: 256)
    ]
    private static func scan(tuple string: String, from index: Int) throws -> SolidityType {
        guard string.last! == ")" else { throw Error.corrupted(string) }
        guard string[..<index] == "tuple" else { throw Error.corrupted(string) }
        let string = string[index+1..<string.count-1]
        let array = try string.split(separator: ",").map { try scan(type: String($0)) }
        return SolidityTuple(types: array)
    }
    private static func scan(arraySize string: String, from index: Int) throws -> SolidityType {
        guard string.last! == "]" else { throw Error.corrupted(string) }
        let prefix = string[..<index]
        guard let type = knownTypes[String(prefix)] else { throw Error.corrupted(string) }
        // type.isValid == true
        let string = string[index+1..<string.count-1]
        if string.isEmpty {
            return SDynamicArray(type: type)
        } else {
            guard let count = Int(string) else { throw Error.corrupted(string) }
            guard count > 0 else { throw Error.corrupted(string) }
            return SStaticArray(count: count, type: type)
        }
    }
    private static func scan(bytesArray string: String, from index: Int) throws -> SolidityType {
        guard let count = Int(string[index...]) else { throw Error.corrupted(string) }
        let type = SBytes(count: count)
        guard type.isValid else { throw Error.corrupted(string) }
        return type
    }
    private static func scan(number string: String, from index: Int) throws -> SolidityType {
        let prefix = string[..<index]
        let isSigned: Bool
        switch prefix {
        case "uint":
            isSigned = false
        case "int":
            isSigned = true
        default: throw Error.corrupted(string)
        }
        let i = index+1
        for (index2,character) in string[i...].enumerated() {
            switch character {
            case "[":
                guard let number = Int(string[index...index+index2]) else { throw Error.corrupted(string) }
                let type = isSigned ? SInt(bits: number) : SUInt(bits: number)
                guard type.isValid else { throw Error.corrupted(string) }
                guard string.last! == "]" else { throw Error.corrupted(string) }
                // type.isValid == true
                let string = string[index+index2+2..<string.count-1]
                if string.isEmpty {
                    return SDynamicArray(type: type)
                } else {
                    guard let count = Int(string) else { throw Error.corrupted(string) }
                    guard count > 0 else { throw Error.corrupted(string) }
                    let array = SStaticArray(count: count, type: type)
                    guard array.isValid else { throw Error.corrupted(string) }
                    return array
                }
            case "0"..."9":
                guard index2 < 3 else { throw Error.corrupted(string) }
                continue
            default: throw Error.corrupted(string)
            }
        }
        guard let number = Int(string[index...]) else { throw Error.corrupted(string) }
        let type = isSigned ? SInt(bits: number) : SUInt(bits: number)
        guard type.isValid else { throw Error.corrupted(string) }
        return type
    }
    /**
     converts single solidity type to native type:
     SolidityFunction uses this method to parse the whole function to name and input types
     example:
     ```
     let type = try! SolidityType.parse("uint256")
     print(type) // prints uint256
     print(type is SolidityType.SUInt) // prints true
     print((type as! SolidityType.SUInt).bits) // prints 256
     ```
     */
    public static func scan(type string: String) throws -> SolidityType {
        for (index,character) in string.enumerated() {
            switch character {
            case "(":
                return try scan(tuple: string, from: index)
            case "[":
                return try scan(arraySize: string, from: index)
            case "0"..."9":
                let prefix = string[..<index]
                if prefix == "bytes" {
                    return try scan(bytesArray: string, from: index)
                } else {
                    return try scan(number: string, from: index)
                }
            default: continue
            }
        }
        if string == "bytes" {
            return SDynamicBytes()
        } else if let type = knownTypes[String(string)] {
            return type
        } else {
            throw Error.corrupted(string)
        }
    }
}


/**
 Solidity function to native type parser.
 
 • Mainthread-friendly
 
Converts:
 ```
 "balanceOf(address)"
 "transfer(address,address,uint256)"
 "transfer(address, address, uint256)"
 "transfer(address, address, uint256)"
 "transfer (address, address, uint)"
 "  transfer  (  address  ,  address  ,  uint256  )  "
 ```
To:
 ```
 function.name: String
 function.types: [SolidityType]
 ```
 
 
 Automatically converts uint to uint256.
 So it will return the same hash for
 ```
 "transfer(address,address,uint256)"
 ```
 and
 ```
 "transfer(address,address,uint)"
 ```

 
Performance:
 ```
  // ~184k operations per second
 var function = try! SolidityFunction("transfer(uint256,address)")
 
 // ~100k operations per second
 function = try! SolidityFunction("transfer(uint256,address,address,bytes32,uint256[32])")
 ```
 */

public class SolidityFunction: CustomStringConvertible {
    /// Errors
    public enum Error: Swift.Error {
        /// Throws if function is in invalid format
        case invalidFormat(String)
        /// Throws if function name is empty
        case emptyFunctionName(String)
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case let .invalidFormat(function):
                return "Invalid format for function \"\(function)\". Should be in format: \"functionName(type,type,type)\""
            case let .emptyFunctionName(function):
                return "Invalid format for function \"\(function)\". Cannot find its name"
            }
        }
    }
    /// Function name
    public let name: String
    /// Array of function arguments
    public let types: [SolidityType]
    /// Formatted function
    public let function: String
    /// Function hash (function.keccak256()[0..<4])
    public lazy var hash: Data = self.function.keccak256()[0..<4]
    /// init with function name
    public init(function: String) throws {
        let replaced = function.replacingOccurrences(of: " ", with: "")
        guard let index = replaced.index(of: "(") else { throw Error.invalidFormat(function) }
        name = String(replaced[..<index])
        guard name.count > 0 else { throw Error.emptyFunctionName(function) }
        guard replaced.hasSuffix(")") else { throw Error.invalidFormat(function) }
        let arguments = replaced[replaced.index(after: index)..<replaced.index(before: replaced.endIndex)]
        self.types = try arguments.split(separator: ",").map { try SolidityType.scan(type: String($0)) }
        self.function = "\(name)(\(types.map { $0.description }.joined(separator: ",")))"
    }
    /// Encodes arguments to data
    public func encode(_ arguments: SolidityDataRepresentable...) -> Data {
        return encode(arguments)
    }
    /// Encodes arguments to data
    public func encode(_ arguments: [SolidityDataRepresentable]) -> Data {
        let data = SolidityDataWriter()
        data.write(header: hash)
        for i in 0..<types.count {
            let type = types[i]
            if i < arguments.count {
                data.write(value: arguments[i], type: type)
            } else {
                data.write(type: type)
            }
        }
        return data.done()
    }
    /// Description in format: "\(name)(\(types.map{ $0.description }.joined(separator: ",")))"
    public var description: String {
        return "\(name)(\(types.map{ $0.description }.joined(separator: ",")))"
    }
}
