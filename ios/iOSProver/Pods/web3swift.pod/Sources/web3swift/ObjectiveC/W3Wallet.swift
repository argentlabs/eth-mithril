//
//  W3Wallet.swift
//  web3swift
//
//  Created by Dmitry on 10/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

/// Wallet functions
@objc public class W3Wallet: NSObject {
    public var swift: Web3Wallet {
        return web3.swift.wallet
    }
    unowned var web3: W3Web3
    @objc public init(web3: W3Web3) {
        self.web3 = web3
    }
    
    /// - Throws: Web3WalletError.attachadKeystoreNotFound
    @objc public func getAccounts() -> [W3Address] {
        return swift.getAccounts().map { $0.objc }
    }
    
    /// - Throws:
    /// Web3WalletError.attachadKeystoreNotFound
    /// Web3WalletError.noAccounts
    @objc public func getCoinbase() throws -> W3Address {
        return try swift.getCoinbase().objc
    }
    
    /// - Throws:
    /// Web3WalletError.attachadKeystoreNotFound
    /// AbstractKeystoreError
    /// Error
    @objc public func sign(transaction: W3EthereumTransaction, account: W3Address, password: String = "BANKEXFOUNDATION") throws {
        try swift.signTX(transaction: &transaction.swift, account: account.swift, password: password)
    }
    
    /// - Throws: SECP256K1Error
    @objc public func sign(personalMessageData: Data, account: W3Address, password: String = "BANKEXFOUNDATION") throws -> Data {
        return try swift.signPersonalMessage(personalMessageData, account: account.swift, password: password)
    }
}
