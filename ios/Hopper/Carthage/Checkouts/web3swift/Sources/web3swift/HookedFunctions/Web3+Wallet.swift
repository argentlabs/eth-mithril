//
import BigInt
//  Web3+HookedWallet.swift
//  web3swift
//
//  Created by Alexander Vlasov on 07.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//
import Foundation

/// Web3Wallet errors
public enum Web3WalletError: Error {
    /// Wallet doesn't have any accounts
    case noAccounts
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case .noAccounts:
            return "Wallet doesn't have any accounts"
        }
    }
}

/// Wallet functions
public class Web3Wallet {
    /// Provider for some functions
    var provider: Web3Provider
    unowned var web3: Web3
    
    /// Init with provider and web3 instance
    public init(provider prov: Web3Provider, web3 web3instance: Web3) {
        provider = prov
        web3 = web3instance
    }
    
    /// - Returns: All accounts in your keystoreManager
    public func getAccounts() -> [Address] {
        return web3.provider.attachedKeystoreManager.addresses
    }
    
    /// - Returns: Returns first account in your keystoreManager
    /// - Throws:
    /// Web3WalletError.noAccounts
    public func getCoinbase() throws -> Address {
        guard let account = getAccounts().first else { throw Web3WalletError.noAccounts }
        return account
    }

    /// Signs transaction with account
    /// - Parameter transaction: Transaction to sign
    /// - Parameter account: Address that signs message
    /// - Parameter password: Password to decrypt account's private key
    /// - Throws:
    /// AbstractKeystoreError
    /// Error
    public func signTX(transaction: inout EthereumTransaction, account: Address, password: String = "BANKEXFOUNDATION") throws {
        let keystoreManager = self.web3.provider.attachedKeystoreManager
        try Web3Signer.signTX(transaction: &transaction, keystore: keystoreManager, account: account, password: password)
    }

    
    /// Signs personalMessage with account
    /// - Parameter personalMessage: Message to sign
    /// - Parameter account: Address that signs message
    /// - Parameter password: Password to decrypt account's private key
    /// - Returns: Signed message
    /// - Throws: SECP256K1Error
    /// DataError.hexStringCorrupted(String)
    public func signPersonalMessage(_ personalMessage: String, account: Address, password: String = "BANKEXFOUNDATION") throws -> Data {
        let data = try personalMessage.dataFromHex()
        return try signPersonalMessage(data, account: account, password: password)
    }
    
    /// Signs personalMessage with account
    /// - Parameter personalMessage: Message to sign
    /// - Parameter account: Address that signs message
    /// - Parameter password: Password to decrypt account's private key
    /// - Returns: Signed message
    /// - Throws: SECP256K1Error
    public func signPersonalMessage(_ personalMessage: Data, account: Address, password: String = "BANKEXFOUNDATION") throws -> Data {
        let keystoreManager = self.web3.provider.attachedKeystoreManager
        return try Web3Signer.signPersonalMessage(personalMessage, keystore: keystoreManager, account: account, password: password)
    }
}
