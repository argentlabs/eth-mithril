//
//  Web3+BrowserFunctions.swift
//  web3swift-iOS
//
//  Created by Alexander Vlasov on 26.02.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Browser functions
public class Web3BrowserFunctions: Web3OptionsInheritable {
    /// Provider for some functions
    var provider: Web3Provider
    unowned var web3: Web3
    
    /// Default options for transactions
    public var options: Web3Options {
        return web3.options
    }
    
    /// Init with provider and web3
    public init(provider prov: Web3Provider, web3 web3instance: Web3) {
        provider = prov
        web3 = web3instance
    }
    
    /// Get a list of Ethereum accounts that a node knows about.
    /// If one has attached a Keystore Manager to the web3 object it returns accounts known to the keystore.
    /// - Important: This function is synchronous!
    /// - Returns: Array of addresses in the node
    public func getAccounts() -> [String]? {
        do {
            return try web3.eth.getAccounts().compactMap { $0.address }
        } catch {
            return nil
        }
    }
    
    /// - Returns: First account from node
    public func getCoinbase() -> String? {
        guard let addresses = self.getAccounts() else { return nil }
        guard addresses.count > 0 else { return nil }
        return addresses[0]
    }

    /**
     Signs personal message
     - Parameter personalMessage: Message to sign
     - Parameter account: Account that signs message
     - Parameter password: Password to decrypt private key
     */
    public func personalSign(_ personalMessage: String, account: String, password: String = "BANKEXFOUNDATION") -> String? {
        return sign(personalMessage, account: account, password: password)
    }

    /**
     Signs personal message
     - Parameter personalMessage: Message to sign
     - Parameter account: Account that signs message
     - Parameter password: Password to decrypt private key
     */
    public func sign(_ personalMessage: String, account: String, password: String = "BANKEXFOUNDATION") -> String? {
        guard let data = Data.fromHex(personalMessage) else { return nil }
        return sign(data, account: account, password: password)
    }

    /**
     Signs personal message
     - Parameter personalMessage: Message to sign
     - Parameter account: Account that signs message
     - Parameter password: Password to decrypt private key
     */
    public func sign(_ personalMessage: Data, account: String, password: String = "BANKEXFOUNDATION") -> String? {
        let keystoreManager = self.web3.provider.attachedKeystoreManager
        guard let signature = try? Web3Signer.signPersonalMessage(personalMessage, keystore: keystoreManager, account: Address(account), password: password) else { return nil }
        return signature.hex.withHex
    }
    
    /**
     Recovers address that signed personal message
     - Parameter personalMessage: Signed message
     - Parameter signature: Signature
     - Returns: Signer address
     */
    public func personalECRecover(_ personalMessage: String, signature: String) throws -> String {
        return try personalECRecover(personalMessage.dataFromHex(), signature: signature.dataFromHex())
    }

    /**
     Recovers address that signed personal message
     - Parameter personalMessage: Signed message
     - Parameter signature: Signature
     - Returns: Signer address
     */
    public func personalECRecover(_ personalMessage: Data, signature: Data) throws -> String {
        try signature.checkSignatureSize()
        let rData = signature[0 ..< 32].bytes
        let sData = signature[32 ..< 64].bytes
        let vData = signature[64]
        let signatureData = try SECP256K1.marshalSignature(v: vData, r: rData, s: sData)
        var hash: Data
        if personalMessage.count == 32 {
            print("Most likely it's hash already, allow for now")
            hash = personalMessage
        } else {
            hash = try Web3Utils.hashPersonalMessage(personalMessage)
        }
        let publicKey = try SECP256K1.recoverPublicKey(hash: hash, signature: signatureData)
        return try Web3Utils.publicToAddressString(publicKey)
    }

    /**
     Sends transaction to the blockchain
     - Parameter json: Transaction to send
     - Parameter password: Password to decrypt sender's private key
     - Returns: Transaction hash
     */
    public func sendTransaction(_ json: [String: Any], password: String = "BANKEXFOUNDATION") throws -> String {
        let transaction = try EthereumTransaction(json)
        let options = try Web3Options(json)
        return try sendTransaction(transaction, options: options, password: password)
    }

    /**
     Sends transaction to the blockchain
     - Parameter transaction: Transaction to send
     - Parameter password: Password to decrypt sender's private key
     - Returns: Transaction hash
     */
    public func sendTransaction(_ transaction: EthereumTransaction, options: Web3Options, password: String = "BANKEXFOUNDATION") throws -> String {
        return try web3.eth.sendTransaction(transaction, options: options, password: password).hash
    }
    
    /**
     Estimates gas that can be used for this transaction
     - Parameter json: Transaction to send
     - Returns: Gas limit
     */
    public func estimateGas(_ json: [String: Any]) throws -> BigUInt {
        let transaction = try EthereumTransaction(json)
        let options = try Web3Options(json)
        return try estimateGas(transaction, options: options)
    }

    /**
     Estimates gas that can be used for this transaction
     - Parameter transaction: Transaction to send
     - Parameter options: Options that will be send with the transaction
     - Returns: Gas limit
     */
    public func estimateGas(_ transaction: EthereumTransaction, options: Web3Options) throws -> BigUInt {
        return try web3.eth.estimateGas(transaction, options: options)
    }

    /**
     Prepares transaction to send.
     Converts json to transaction and options.
     Gets gas price and estimates gas for this transaction from node
     - Parameter json: Transaction to send
     - Returns: Transaction and its options
     */
    public func prepareTxForApproval(_ json: [String: Any]) throws -> (transaction: EthereumTransaction, options: Web3Options) {
        let transaction = try EthereumTransaction(json)
        let options = try Web3Options(json)
        return try prepareTxForApproval(transaction, options: options)
    }
    
    /// Transaction Errors
    public enum TransactionError: Error {
        /// You have to set transaction sender in options.from
        case optionsFromNotFound
        /// Cannot find private key for address \(address)
        case privateKeyNotFound(forAddress: Address)
        /// Cannot encode transaction
        case cannotEncodeTransaction
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case .optionsFromNotFound:
                return "You have to set transaction sender in options.from"
            case let .privateKeyNotFound(forAddress: address):
                return "Cannot find private key for address \(address) in the keystore manager"
            case .cannotEncodeTransaction:
                return "Cannot encode transaction"
            }
        }
    }

    /**
     Prepares transaction to send.
     Gets gas price and estimates gas for this transaction from node
     - Important: You must set sender in `options.from`
     - Parameter transaction: Transaction to send
     - Returns: Transaction and its options
     - Throws: TransactionError.optionsFromNotFound
     */
    public func prepareTxForApproval(_ transaction: EthereumTransaction, options opts: Web3Options) throws -> (transaction: EthereumTransaction, options: Web3Options) {
        var transaction = transaction
        var options = opts
        guard options.from != nil else { throw TransactionError.optionsFromNotFound }
        let gasPrice = try web3.eth.getGasPrice()
        transaction.gasPrice = gasPrice
        options.gasPrice = gasPrice
        let gasLimit = try estimateGas(transaction, options: options)
        transaction.gasLimit = gasLimit
        options.gasLimit = gasLimit
        return (transaction, options)
    }
    
    /**
     Signs transaction
     - Important: You must set sender in `options.from`
     - Parameter personalMessage: Transaction to sign
     - Parameter password: Password to decrypt private key
     */
    public func signTransaction(_ json: [String: Any], password: String = "BANKEXFOUNDATION") throws -> String {
        let transaction = try EthereumTransaction(json)
        let options = try Web3Options(json)
        return try signTransaction(transaction, options: options, password: password)
    }
    
    /**
     Signs transaction
     - Important: You must set sender in `options.from`
     - Parameter personalMessage: Transaction to sign
     - Parameter password: Password to decrypt private key
     */
    public func signTransaction(_ trans: EthereumTransaction, options: Web3Options, password: String = "BANKEXFOUNDATION") throws -> String {
        var transaction = trans
        guard let from = options.from else { throw TransactionError.optionsFromNotFound }
        let keystoreManager = self.web3.provider.attachedKeystoreManager
        let gasPrice = try web3.eth.getGasPrice()
        transaction.gasPrice = gasPrice
        let gasLimit = try estimateGas(transaction, options: options)
        transaction.gasLimit = gasLimit

        transaction.nonce = try web3.eth.getTransactionCount(address: from, onBlock: "pending")

        if web3.provider.network != nil {
            transaction.chainID = web3.provider.network
        }

        guard let keystore = keystoreManager.walletForAddress(from) else { throw TransactionError.privateKeyNotFound(forAddress: from) }
        try Web3Signer.signTX(transaction: &transaction, keystore: keystore, account: from, password: password)
        guard let signedData = transaction.encode(forSignature: false, chainId: nil)?.hex.withHex else { throw TransactionError.cannotEncodeTransaction }
        return signedData
    }
}
