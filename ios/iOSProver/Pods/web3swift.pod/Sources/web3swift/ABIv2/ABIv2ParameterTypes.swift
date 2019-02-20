//
//  ABIv2ParameterTypes.swift
//  web3swift
//
//  Created by Alexander Vlasov on 02.04.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation



extension ABIv2.Element {
    /// Specifies the type that parameters in a contract have.
    public enum ParameterType: ABIv2ElementPropertiesProtocol {
        /// uintN type
        case uint(bits: UInt64)
        /// intN type
        case int(bits: UInt64)
        /// address type
        case address
        /// function type
        case function
        /// bool type
        case bool
        /// bytesN type
        case bytes(length: UInt64)
        /// array[N] or array[] type
        indirect case array(type: ParameterType, length: UInt64)
        /// bytes type
        case dynamicBytes
        /// string type
        case string
        /// tuple type
        indirect case tuple(types: [ParameterType])

        var isStatic: Bool {
            switch self {
            case .string:
                return false
            case .dynamicBytes:
                return false
            case let .array(type: type, length: length):
                return length > 0 && type.isStatic
            case let .tuple(types: types):
                return types.allSatisfy { $0.isStatic }
            case .bytes(length: _):
                return true
            default:
                return true
            }
        }

        var isArray: Bool {
            switch self {
            case .array:
                return true
            default:
                return false
            }
        }

        var isTuple: Bool {
            switch self {
            case .tuple:
                return true
            default:
                return false
            }
        }

        var subtype: ABIv2.Element.ParameterType? {
            switch self {
            case .array(type: let type, length: _):
                return type
            default:
                return nil
            }
        }

        var memoryUsage: UInt64 {
            switch self {
            case let .array(_, length: length):
                if length == 0 {
                    return 32
                }
                if self.isStatic {
                    return 32 * length
                }
                return 32
            case let .tuple(types: types):
                if !self.isStatic {
                    return 32
                }
                var sum: UInt64 = 0
                for t in types {
                    sum = sum + t.memoryUsage
                }
                return sum
            default:
                return 32
            }
        }

        var emptyValue: Any {
            switch self {
            case .uint:
                return BigUInt(0)
            case .int:
                return BigUInt(0)
            case .address:
                return Address("0x0000000000000000000000000000000000000000")
            case .function:
                return Data(repeating: 0x00, count: 24)
            case .bool:
                return false
            case let .bytes(length: length):
                return Data(repeating: 0x00, count: Int(length))
            case let .array(type: type, length: length):
                let emptyValueOfType = type.emptyValue
                return Array(repeating: emptyValueOfType, count: Int(length))
            case .dynamicBytes:
                return Data()
            case .string:
                return ""
            case .tuple(types: _):
                return [Any]()
            }
        }

        var arraySize: ABIv2.Element.ArraySize {
            switch self {
            case .array(type: _, length: let length):
                if length == 0 {
                    return ArraySize.dynamicSize
                } else {
                    return ArraySize.staticSize(length)
                }
            default:
                return ArraySize.notArray
            }
        }
    }
}

extension ABIv2.Element.ParameterType: Equatable {
    public static func == (lhs: ABIv2.Element.ParameterType, rhs: ABIv2.Element.ParameterType) -> Bool {
        switch (lhs, rhs) {
        case let (.uint(length1), .uint(length2)):
            return length1 == length2
        case let (.int(length1), .int(length2)):
            return length1 == length2
        case (.address, .address):
            return true
        case (.bool, .bool):
            return true
        case let (.bytes(length1), .bytes(length2)):
            return length1 == length2
        case (.function, .function):
            return true
        case let (.array(type1, length1), .array(type2, length2)):
            return type1 == type2 && length1 == length2
        case (.dynamicBytes, .dynamicBytes):
            return true
        case (.string, .string):
            return true
        default:
            return false
        }
    }
}

extension ABIv2.Element.Function {
    /// String representation of solidity function for hashing
    public var signature: String {
        return "\(name ?? "")(\(inputs.map { $0.type.abiRepresentation }.joined(separator: ",")))"
    }

    /// Function hash in hex
    public var methodString: String {
        return signature.keccak256().hex
    }
    
    /// Function hash
    public var methodEncoding: Data {
        return signature.data(using: .ascii)!.keccak256()[0..<4]
    }
}

// MARK: - Event topic

extension ABIv2.Element.Event {
    /// String representation of solidity event for hashing
    public var signature: String {
        return "\(name)(\(inputs.map { $0.type.abiRepresentation }.joined(separator: ",")))"
    }
    
    /// Event hash
    public var topic: Data {
        return signature.data(using: .ascii)!.keccak256()
    }
}

extension ABIv2.Element.ParameterType: ABIv2Encoding {
    /// Solidity type representation
    public var abiRepresentation: String {
        switch self {
        case let .uint(bits):
            return "uint\(bits)"
        case let .int(bits):
            return "int\(bits)"
        case .address:
            return "address"
        case .bool:
            return "bool"
        case let .bytes(length):
            return "bytes\(length)"
        case .dynamicBytes:
            return "bytes"
        case .function:
            return "function"
        case let .array(type: type, length: length):
            if length == 0 {
                return "\(type.abiRepresentation)[]"
            }
            return "\(type.abiRepresentation)[\(length)]"
        case let .tuple(types: types):
            let typesRepresentation = types.map { $0.abiRepresentation }
            let typesJoined = typesRepresentation.joined(separator: ",")
            return "tuple(\(typesJoined))"
        case .string:
            return "string"
        }
    }
}

extension ABIv2.Element.ParameterType: ABIv2Validation {
    /// Returns true if type is valid (or false for types like uint257)
    public var isValid: Bool {
        switch self {
        case let .uint(bits), let .int(bits):
            return bits > 0 && bits <= 256 && bits % 8 == 0
        case let .bytes(length):
            return length > 0 && length <= 32
        case .array(type: let type, _):
            return type.isValid
        case let .tuple(types: types):
            for t in types {
                if !t.isValid {
                    return false
                }
            }
            return true
        default:
            return true
        }
    }
}
