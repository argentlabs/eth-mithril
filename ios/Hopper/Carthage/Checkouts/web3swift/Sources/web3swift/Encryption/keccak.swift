//
//  File.swift
//  web3swift
//
//  Created by Dmitry on 05/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import keccak

extension Data {
    var pointer: UnsafePointer<UInt8>! { return withUnsafeBytes { $0 } }
    mutating func mutablePointer() -> UnsafeMutablePointer<UInt8>! {
        return withUnsafeMutableBytes { $0 }
    }
    
    /// - Returns: kaccak256 hash of data
    public func keccak256() -> Data {
        var data = Data(count: 32)
        keccak_256(data.mutablePointer(), 32, pointer, count)
        return data
    }
}
