//
//  Address.swift
//  web3swift
//
//  Created by Alexander Vlasov on 07.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Address error
public enum AddressError: Error {
    /// Provided address is not valid (\(string))
    case invalidAddress(String)
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case let .invalidAddress(string):
            return "Provided address is not valid (\(string))"
        }
    }
}

/**
 Address class (20 byte data) used for most library
 
 To init address you can do this:
 ```
 let addressString = "0x45245bc59219eeaaf6cd3f382e078a461ff9de7b"
 let address1 = Address(addressString)
 let address2 = Address("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
 ```
 
 If user enters the address you need to check if address is in valid format. To do that use:
 ```
 let inputString = "0x45245bc59219eeaaf6cd3f382e078a461ff9de7b"
 guard inputString.isValid else { return }
 // or
 let address = Address("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
 guard address.isValid else { return }
 // or
 try address.check() // will throw AddressError.invalidAddress if its invalid
 ```
 
 Also Address is confirmed to ExpressibleByStringLiteral so you can do this
 ```
 let address: Address = "0x45245bc59219eeaaf6cd3f382e078a461ff9de7b"
 ```
 
 This is very usabe for test cases like if you want to test function (like read ERC20 balance)
 you can just run
 ```
 let balance = try ERC20("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b").balance(of: "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
 print(balance)
 
 ```
 */
public struct Address {
    /// Address type
    public enum AddressType {
        /// Any ethereum address
        case normal
        /// Address for contract deployment
        case contractDeployment
    }

    /// Checks if address size is 20 bytes long.
    /// Always returns true for contractDeployment address
    public var isValid: Bool {
        switch type {
        case .normal:
            return addressData.count == 20
        case .contractDeployment:
            return true
        }
    }
    
    var _address: String
    /// Address type
    public var type: AddressType = .normal
    
    /// Binary representation of address
    public var addressData: Data {
        switch type {
        case .normal:
            return Data.fromHex(_address) ?? Data()
        case .contractDeployment:
            return Data()
        }
    }

    /// Address string converted to checksum
    /// returns 0x for contractDeployment address
    public var address: String {
        switch type {
        case .normal:
            return Address.toChecksumAddress(_address)!
        case .contractDeployment:
            return "0x"
        }
    }
    
    /// Converts address to checksum address
    public static func toChecksumAddress(_ addr: String) -> String? {
        let address = addr.lowercased().withoutHex
        guard let hash = address.data(using: .ascii)?.keccak256().hex else { return nil }
        var ret = "0x"

        for (i, char) in address.enumerated() {
            let startIdx = hash.index(hash.startIndex, offsetBy: i)
            let endIdx = hash.index(hash.startIndex, offsetBy: i + 1)
            let hashChar = String(hash[startIdx ..< endIdx])
            let c = String(char)
            guard let int = Int(hashChar, radix: 16) else { return nil }
            if int >= 8 {
                ret += c.uppercased()
            } else {
                ret += c
            }
        }
        return ret
    }
    
    /// Init with addressString and type
    /// - Parameter addressString: Hex string of address
    /// - Parameter type: Address type. default: .normal
    /// Automatically adds 0x prefix if its not found
    public init(_ addressString: String, type: AddressType = .normal) {
        switch type {
        case .normal:
            // check for checksum
            _address = addressString.withHex
            self.type = .normal
        case .contractDeployment:
            _address = "0x"
            self.type = .contractDeployment
        }
    }

    /// - Parameter addressData: Address data
    /// - Parameter type: Address type. default: .normal
    /// - Important: addressData is not the utf8 format of hex string
    public init(_ addressData: Data, type: AddressType = .normal) {
        _address = addressData.hex.withHex
        self.type = type
    }
    
    /// checks if address is valid
    /// - Throws: AddressError.invalidAddress if its not valid
    public func check() throws {
        guard isValid else { throw AddressError.invalidAddress(_address) }
    }
    
    /// - Returns: "0x" address
    public static var contractDeployment: Address {
        return Address("0x", type: .contractDeployment)
    }
    
    //    public static func fromIBAN(_ iban: String) -> Address {
    //
    //    }
}

extension Address: Equatable {
    /// Compares address checksum representation. So there won't be a conflict with string casing
    public static func == (lhs: Address, rhs: Address) -> Bool {
        return lhs.address == rhs.address && lhs.type == rhs.type
    }
}

extension Address: Hashable {
    public var hashValue: Int {
        return address.hashValue
    }
}

extension Address: CustomStringConvertible {
    /// - Returns: Address hex string formatted to checksum
    public var description: String {
        return address
    }
}

extension Address: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

public extension String {
    /// - Returns: true if string is contract address
    var isContractAddress: Bool {
        return hex.count > 0
    }

    /// - Returns: true is address is 20 bytes long
    var isAddress: Bool {
        return hex.count == 20
    }
    
    /// - Returns: Contract deployment address.
    var contractAddress: Address {
        return Address(self, type: .contractDeployment)
    }
}
