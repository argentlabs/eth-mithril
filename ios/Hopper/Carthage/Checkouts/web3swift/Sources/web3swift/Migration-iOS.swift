//
//  Migration-iOS.swift
//  web3swift
//
//  Created by Dmitry on 22/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

#if canImport(CIImage)
import Foundation
import CIImage

extension Web3 {
    @available (*, deprecated: 2.1, message: "Use EIP67Code, not Web3.EIP67Code")
    public typealias EIP67Code = web3swift.EIP67Code
    @available (*, deprecated: 2.1, message: "Use EIP67Code")
    public typealias EIP67CodeGenerator = web3swift.EIP67CodeGenerator
    @available (*, deprecated: 2.1, message: "Use EIP67Code")
    public typealias EIP67CodeParser = web3swift.EIP67CodeParser
}
public struct EIP67CodeGenerator {
    @available (*, deprecated: 2.1, message: "Use EIP67Code.toImage(scale:)")
    public static func createImage(from: EIP67Code, scale: Double = 1.0) -> CIImage {
        return from.toImage(scale: scale)
    }
}
public struct EIP67CodeParser {
    @available(*, deprecated: 2.1, message: "Use EIP67Code.init(string:)")
    public static func parse(_ data: Data) -> EIP67Code? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        return parse(string)
    }
    @available(*, deprecated: 2.1, message: "Use EIP67Code.init(string:)")
    public static func parse(_ string: String) -> EIP67Code? {
        return EIP67Code(string: string)
    }
}

extension EIP67Code {
    @available (*, deprecated: 2.0, message: "Use init with address")
    public init(address: String) {
        self.init(address: Address(address))
    }
}
#endif
