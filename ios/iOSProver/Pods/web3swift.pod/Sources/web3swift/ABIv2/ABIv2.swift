//
//  ABIv2.swift
//  web3swift
//
//  Created by Alexander Vlasov on 02.04.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

/// Element type protocol
protocol ABIv2ElementPropertiesProtocol {
    /// Returns true if array is has fixed length
    var isStatic: Bool { get }
    /// Returns true if type is array
    var isArray: Bool { get }
    /// Returns true if type is tuple
    var isTuple: Bool { get }
    /// Returns array size if type
    var arraySize: ABIv2.Element.ArraySize { get }
    /// Returns subtype of array
    var subtype: ABIv2.Element.ParameterType? { get }
    /// Returns memory usage of type
    var memoryUsage: UInt64 { get }
    /// Returns default empty value for type
    var emptyValue: Any { get }
}

protocol ABIv2Encoding {
    var abiRepresentation: String { get }
}

protocol ABIv2Validation {
    var isValid: Bool { get }
}

/// Parses smart contract json abi to work with smart contract's functions
public struct ABIv2 {}
