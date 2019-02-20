//
//  scrypt.swift
//  web3swift
//
//  Created by Dmitry on 05/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import scrypt

public func scrypt(password: String, salt: Data, length: Int, N: Int, R: Int, P: Int) -> Data? {
    let password = password.data
    var derivedKey = Data(count: length)
    let status = crypto_scrypt(password.pointer, password.count, salt.pointer, salt.count, UInt64(N), UInt32(R), UInt32(P), derivedKey.mutablePointer(), derivedKey.count)
    guard status == 0 else { return nil }
    return derivedKey
}
