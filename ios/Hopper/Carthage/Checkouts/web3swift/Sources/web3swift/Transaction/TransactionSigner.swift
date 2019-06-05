//
//  TransactionSigner.swift
//  web3swift-iOS
//
//  Created by Alexander Vlasov on 26.02.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Transaction signer errors
public enum TransactionSignerError: Error {
    /// Cannot sign
    case signatureError(String)
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case let .signatureError(error):
            return "Cannot sign transaction: \(error)"
        }
    }
}

/// Ethereum signing functions
public struct Web3Signer {
    /**
     Signs transaction. Uses ERP155Signer if you specified chainID otherwise it uses FallbackSigner
     - Parameter transaction: Transaction to sign
     - Parameter keystore: Keystore that stores account private key
     - Parameter account: Account that signs message
     - Parameter password: Password to decrypt private key
     - Parameter useExtraEntropy: Add random data to signed message. default: false
     - Throws: Web3UtilsError.cannotConvertDataToAscii, SECP256K1Error, AbstractKeystoreError
     */
    public static func signTX(transaction: inout EthereumTransaction, keystore: AbstractKeystore, account: Address, password: String, useExtraEntropy: Bool = false) throws {
        var privateKey = try keystore.UNSAFE_getPrivateKeyData(password: password, account: account)
        defer { Data.zero(&privateKey) }
        if transaction.chainID != nil {
            try EIP155Signer.sign(transaction: &transaction, privateKey: privateKey, useExtraEntropy: useExtraEntropy)
        } else {
            try FallbackSigner.sign(transaction: &transaction, privateKey: privateKey, useExtraEntropy: useExtraEntropy)
        }
    }

    /**
     Signs transaction
     - Parameter intermediate: Transaction to sign
     - Parameter keystore: Keystore that stores account private key
     - Parameter account: Account that signs message
     - Parameter password: Password to decrypt private key
     - Parameter useExtraEntropy: Add random data to signed message. default: false
     - Throws: Web3UtilsError.cannotConvertDataToAscii, SECP256K1Error, AbstractKeystoreError
     */
    public static func signIntermediate(intermediate: inout TransactionIntermediate, keystore: AbstractKeystore, account: Address, password: String, useExtraEntropy: Bool = false) throws {
        var tx = intermediate.transaction
        try Web3Signer.signTX(transaction: &tx, keystore: keystore, account: account, password: password, useExtraEntropy: useExtraEntropy)
        intermediate.transaction = tx
    }

    /**
     Signs personal message
     - Parameter personalMessage: Message data
     - Parameter keystore: Keystore that stores account private key
     - Parameter account: Account that signs message
     - Parameter password: Password to decrypt private key
     - Parameter useExtraEntropy: Add random data to signed message. default: false
     - Throws: Web3UtilsError.cannotConvertDataToAscii, SECP256K1Error, AbstractKeystoreError
     */
    public static func signPersonalMessage(_ personalMessage: Data, keystore: AbstractKeystore, account: Address, password: String, useExtraEntropy: Bool = false) throws -> Data {
        var privateKey = try keystore.UNSAFE_getPrivateKeyData(password: password, account: account)
        defer { Data.zero(&privateKey) }
        let hash = try Web3Utils.hashPersonalMessage(personalMessage)
        var signature = try SECP256K1.signForRecovery(hash: hash, privateKey: privateKey, useExtraEntropy: useExtraEntropy).serializedSignature
        if signature[64] < 27 {
            signature[64] += 27
        }
        return signature
    }
    
    /// EIP155Signer
    public struct EIP155Signer {
        /**
         Sign transaction using EIP155Signer
         - Parameter transaction: Transaction to sign
         - Parameter privateKey: Private key that signs the transaction
         - Parameter useExtraEntropy: Add random data to signed message. default: false
         - Throws: Web3UtilsError.cannotConvertDataToAscii, SECP256K1Error, AbstractKeystoreError
         */
        public static func sign(transaction: inout EthereumTransaction, privateKey: Data, useExtraEntropy: Bool = false) throws {
            for _ in 0 ..< 1024 {
                do {
                    try attemptSignature(transaction: &transaction, privateKey: privateKey, useExtraEntropy: useExtraEntropy)
                    return
                } catch {}
            }
            throw AbstractKeystoreError.invalidAccountError
        }
        
        /// EIP155Signer errors
        public enum Error: Swift.Error {
            /// Chain id not found. Please provide chain id to sign transaction
            case chainIdNotFound
            /// Cannot get hash from transaction for signing
            case hashNotFound
            /// Invalid private key
            case recoveredPublicKeyCorrupted
            /// Printable / user displayable description
            public var localizedDescription: String {
                switch self {
                case .chainIdNotFound:
                    return "Chain id not found. Please provide chain id to sign transaction"
                case .hashNotFound:
                    return "Cannot get hash from transaction for signing"
                case .recoveredPublicKeyCorrupted:
                    return "Invalid private key"
                }
            }
        }

        private static func attemptSignature(transaction: inout EthereumTransaction, privateKey: Data, useExtraEntropy: Bool = false) throws {
            guard let chainID = transaction.chainID else { throw Error.chainIdNotFound }
            guard let hash = transaction.hashForSignature(chainID: chainID) else { throw Error.hashNotFound }
            let signature = try SECP256K1.signForRecovery(hash: hash, privateKey: privateKey, useExtraEntropy: useExtraEntropy)
            let unmarshalledSignature = try SECP256K1.unmarshalSignature(signatureData: signature.serializedSignature)
            let originalPublicKey = try SECP256K1.privateToPublic(privateKey: privateKey)
            transaction.v = BigUInt(unmarshalledSignature.v) + 35 + chainID.rawValue + chainID.rawValue
            transaction.r = BigUInt(Data(unmarshalledSignature.r))
            transaction.s = BigUInt(Data(unmarshalledSignature.s))
            let recoveredPublicKey = transaction.recoverPublicKey()
            guard originalPublicKey.constantTimeComparisonTo(recoveredPublicKey) else { throw Error.recoveredPublicKeyCorrupted }
        }
    }
    
    /// Fallback signer
    public struct FallbackSigner {
        /**
         Sign transaction using FallbackSigner
         - Parameter transaction: Transaction to sign
         - Parameter privateKey: Private key that signs the transaction
         - Parameter useExtraEntropy: Add random data to signed message. default: false
         - Throws: Web3UtilsError.cannotConvertDataToAscii, SECP256K1Error, AbstractKeystoreError
         */
        public static func sign(transaction: inout EthereumTransaction, privateKey: Data, useExtraEntropy _: Bool = false) throws {
            for _ in 0 ..< 1024 {
                do {
                    try attemptSignature(transaction: &transaction, privateKey: privateKey)
                    return
                } catch {}
            }
            throw AbstractKeystoreError.invalidAccountError
        }
        
        /// Fallback signer errors
        public enum Error: Swift.Error {
            /// Cannot get hash from transaction for signing
            case hashNotFound
            /// Invalid private key
            case recoveredPublicKeyCorrupted
            /// Printable / user displayable description
            public var localizedDescription: String {
                switch self {
                case .hashNotFound:
                    return "Cannot get hash from transaction for signing"
                case .recoveredPublicKeyCorrupted:
                    return "Invalid private key"
                }
            }
        }
        
        private static func attemptSignature(transaction: inout EthereumTransaction, privateKey: Data, useExtraEntropy: Bool = false) throws {
            guard let hash = transaction.hashForSignature(chainID: nil) else { throw Error.hashNotFound }
            let signature = try SECP256K1.signForRecovery(hash: hash, privateKey: privateKey, useExtraEntropy: useExtraEntropy)
            let unmarshalledSignature = try SECP256K1.unmarshalSignature(signatureData: signature.serializedSignature)
            let originalPublicKey = try SECP256K1.privateToPublic(privateKey: privateKey)
            transaction.chainID = nil
            transaction.v = BigUInt(unmarshalledSignature.v) + BigUInt(27)
            transaction.r = BigUInt(Data(unmarshalledSignature.r))
            transaction.s = BigUInt(Data(unmarshalledSignature.s))
            let recoveredPublicKey = transaction.recoverPublicKey()
            guard originalPublicKey.constantTimeComparisonTo(recoveredPublicKey) else { throw Error.recoveredPublicKeyCorrupted }
        }
    }
}
