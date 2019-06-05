//
//  PlainKeystore.swift
//  web3swift
//
//  Created by Alexander Vlasov on 06.04.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

/// Keystore that contains private key
public class PlainKeystore: AbstractKeystore {
    private var privateKey: Data
    
    /// Always returns array with one address
    public var addresses: [Address]

    /// Default: false
    public var isHDKeystore: Bool = false

    /// Returns keystore private key.
    /// - Parameter password: We already have unencrypted private. So password doing nothing here
    /// - Parameter address: We have only one address. So account will be ignored too
    public func UNSAFE_getPrivateKeyData(password _: String = "", account _: Address) throws -> Data {
        return privateKey
    }
    
    /// Init with private key hex string
    public convenience init(privateKey: String) throws {
        try self.init(privateKey: privateKey.dataFromHex())
    }
    
    /// Init with private key data
    public init(privateKey: Data) throws {
        try SECP256K1.verifyPrivateKey(privateKey: privateKey)

        let publicKey = try Web3Utils.privateToPublic(privateKey, compressed: false)
        let address = try Web3Utils.publicToAddress(publicKey)
        addresses = [address]
        self.privateKey = privateKey
    }
}
