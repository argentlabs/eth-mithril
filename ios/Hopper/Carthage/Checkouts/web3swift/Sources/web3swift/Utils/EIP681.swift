//
//  EthURL.swift
//  web3swift
//
//  Created by Dmitry on 02/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Typealias for url standard
public typealias EIP681 = EthURL

/**
 Represents [EIP681](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-681.md) url
 
 Syntax:
 ```
 request                 = erc831_part target_address [ "@" chain_id ] [ "/" function_name ] [ "?" parameters ]
 erc831_part             = schema and optional prefix as defined in #831 - typically "ethereum" ":" [ "pay-" ] in this case
 target_address          = ethereum_address
 chain_id                = 1*DIGIT
 function_name           = STRING
 ethereum_address        = ( "0x" 40*40HEXDIG ) / ENS_NAME
 parameters              = parameter *( "&" parameter )
 parameter               = key "=" value
 key                     = "value" / "gas" / "gasLimit" / "gasPrice" / TYPE
 value                   = number / ethereum_address / STRING
 number                  = [ "-" / "+" ] *DIGIT [ "." 1*DIGIT ] [ ( "e" / "E" ) [ 1*DIGIT ] [ "+" UNIT ]
 ```
 
 Example urls:
 ```
 ethereum:0xfb6916095ca1df60bb79Ce92ce3ea74c37c5d359?value=2.014e18
 
 ethereum:0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7/transfer?address=0x8e23ee67d1332ad560396262c48ffbb01f93d052&uint256=1
 ```
 */
public class EthURL {
    /// Errors
    public enum Error: Swift.Error {
        /// URL has invalid scheme. Ethereum url should start with ethereum:
        case wrongScheme
        /// Invalid ethereum address
        case addressCorrupted
        /// Invalid ethereum host
        case hostCorrupted
        /// Invalid ethereum user
        case userCorrupted
        /// Provided url is not url convertible
        case notURL
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case .wrongScheme:
                return "URL has invalid scheme. Ethereum url should start with ethereum:"
            case .addressCorrupted:
                return "Invalid ethereum address"
            case .hostCorrupted:
                return "Invalid ethereum host"
            case .userCorrupted:
                return "Invalid ethereum user"
            case .notURL:
                return "Provided url is not url convertible"
            }
        }
    }
    
    /// Is pay transaction
    public var isPay: Bool
    /// Contract / recipient address
    public var targetAddress: String
    /// Chain id
    public var chainId: BigInt?
    /// Function name
    public var functionName: String?
    /// Function arguments
    public var parameters = [String: String]()
    /// String representation of url
    public var string: String {
        var string = "ethereum:"
        if isPay {
            string += "pay-"
        }
        string += targetAddress
        if let chainId = chainId {
            string += "@" + chainId.description
        }
        if let name = functionName {
            string += "/" + name
        }
        if !parameters.isEmpty {
            string += "?" + parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        }
        return string
    }
    
    /// Url representation
    public var url: URL {
        return URL(string: string)!
    }
    
    /// Init with target address
    public init(address: String) {
        isPay = false
        targetAddress = address
    }
    
    /// Init with url string
    public init(string: String) throws {
        let prefix = "ethereum:"
        guard string.hasPrefix(prefix) else { throw Error.wrongScheme }
        var string = string
        if !string[prefix.endIndex...].hasPrefix("//") {
            string.insert(contentsOf: "//", at: prefix.endIndex)
        }

        guard let url = URLComponents(string: string) else { throw Error.notURL }
        var address: String
        if let user = url.user {
            address = user
            guard let host = url.host else { throw Error.userCorrupted }
            chainId = BigInt(host, radix: 16)
        } else {
            guard let host = url.host else { throw Error.hostCorrupted }
            address = host
        }
        let payPrefix = "pay-"
        if address.hasPrefix(payPrefix) {
            isPay = true
            address = String(address[payPrefix.endIndex...])
        } else {
            isPay = false
        }
        if address.hasPrefix("0x") {
            guard address.count == 42 else { throw Error.addressCorrupted }
            targetAddress = address
        } else {
            targetAddress = address
        }

        functionName = url.path
        url.queryItems?.forEach {
            guard let value = $0.value else { return }
            parameters[$0.name] = value
        }
    }
}
