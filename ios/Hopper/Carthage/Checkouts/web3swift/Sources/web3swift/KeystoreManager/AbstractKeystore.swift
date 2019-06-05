//
//  AbstractKeystore.swift
//  web3swift
//
//  Created by Alexander Vlasov on 10.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

/// Keystore Protocol
public protocol AbstractKeystore {
    /// Array for addresses
    var addresses: [Address] { get }
    /// Returns true if keystore is HDKeystore compatible
    var isHDKeystore: Bool { get }
    /// Decrypts account's private key with password
    func UNSAFE_getPrivateKeyData(password: String, account: Address) throws -> Data
}

/// Keystore Errors
public enum AbstractKeystoreError: Error {
    /// Cannot get derived key using this password
    case keyDerivationError
    /// Invalid aes key or unsupported aes encryption type
    case aesError
    /// Private key doesn't match provided account
    case invalidAccountError
    /// Invalid password
    case invalidPasswordError
    /// Some other encryption errors
    case encryptionError(String)
    
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case .keyDerivationError:
            return "Cannot get derived key using this password"
        case .aesError:
            return "Invalid aes key or unsupported aes encryption type"
        case .invalidAccountError:
            return "Private key doesn't match provided account"
        case .invalidPasswordError:
            return "Invalid password"
        case let .encryptionError(string):
            return "Encryption error: \(string)"
        }
    }
}
