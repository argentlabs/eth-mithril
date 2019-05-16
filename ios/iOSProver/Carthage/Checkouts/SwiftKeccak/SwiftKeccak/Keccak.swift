//
//  Keccak.swift
//  SwiftKeccak
//
//  Created by Pelle Steffen Braendgaard on 7/22/17.
//  Copyright © 2017 Consensys AG. All rights reserved.
//

import Foundation
import keccaktiny
import sha3tiny

public func keccak256(_ data: Data) -> Data {
    let nsData = data as NSData
    let input = nsData.bytes.bindMemory(to: UInt8.self, capacity: data.count)
    let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
    keccak_256(result, 32, input, data.count)
    return Data(bytes: result, count: 32)
}

public func keccak256(_ string: String) -> Data {
    return keccak256(string.data(using: String.Encoding.utf8)!)
}

public func sha3Final256(_ data: Data) -> Data {
    let nsData = data as NSData
    let input = nsData.bytes.bindMemory(to: UInt8.self, capacity: data.count)
    let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
    sha3_256(result, 32, input, data.count)
    return Data(bytes: result, count: 32)
}

public func sha3Final256(_ string: String) -> Data {
    return sha3Final256(string.data(using: String.Encoding.utf8)!)
}

public extension Data {
    func keccak() -> Data {
        return keccak256(self)
    }

    func sha3Final() -> Data {
        return sha3Final256(self)
    }

}

public extension String {
    func keccak() -> Data {
        return keccak256(self)
    }
    func sha3Final() -> Data {
        return sha3Final256(self)
    }
}
