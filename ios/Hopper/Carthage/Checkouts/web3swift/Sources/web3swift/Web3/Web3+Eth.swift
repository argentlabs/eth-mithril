//
//  Web3+Eth.swift
//  web3swift
//
//  Created by Alexander Vlasov on 22.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation
import PromiseKit

/// Extension located
public class Web3Eth: Web3OptionsInheritable {
    /// provider for some functions
    var provider: Web3Provider
    unowned var web3: Web3
    /// Default options
	public var options: Web3Options {
        return web3.options
    }
	
	/// init with web3 provider and web3
    public init(provider prov: Web3Provider, web3 web3instance: Web3) {
        provider = prov
        web3 = web3instance
    }
    /// Send an EthereumTransaction object to the network. Transaction is either signed locally if there is a KeystoreManager
    /// object bound to the web3 instance, or sent unsigned to the node. For local signing the password is required.
    ///
	/// - Parameter transaction: Transaction to send
	/// - Parameter options: Object can override the "to", "gasPrice", "gasLimit" and "value" parameters is pre-formed transaction.
    /// "from" field in "options" is mandatory for both local and remote signing.
	/// - Parameter password: Password to decrypt sender's private key
    /// - Important: This function is synchronous!
    public func sendTransaction(_ transaction: EthereumTransaction, options: Web3Options, password: String = "BANKEXFOUNDATION") throws -> TransactionSendingResult {
        return try sendTransactionPromise(transaction, options: options, password: password).wait()
    }

    /// Performs a non-mutating "call" to some smart-contract. EthereumTransaction bears all function parameters required for the call.
    /// Does NOT decode the data returned from the smart-contract.
	/// - Parameter transaction: Transaction to send
	/// - Parameter options: Object can override the "to", "gasPrice", "gasLimit" and "value" parameters is pre-formed transaction.
    /// "from" field in "options" is mandatory for both local and remote signing.
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
    /// or the expected state after all the transactions in memory pool are applied ("pending").
	/// - Important: This function is synchronous!
	/// - Returns: Smart contract response
    public func call(_ transaction: EthereumTransaction, options: Web3Options, onBlock: String = "latest") throws -> Data {
        return try callPromise(transaction, options: options, onBlock: onBlock).wait()
    }

    /// Send raw Ethereum transaction data to the network.
	/// - Parameter transaction: Transaction to send
    /// - Important: This function is synchronous!
	/// - Returns: TransactionSendingResult with transaction and its hash
    public func sendRawTransaction(_ transaction: Data) throws -> TransactionSendingResult {
        return try sendRawTransactionPromise(transaction).wait()
    }

    /// Send raw Ethereum transaction data to the network by first serializing the EthereumTransaction object.
	/// - Parameter transaction: Transaction to send
    /// - Important: This function is synchronous!
	/// - Returns: TransactionSendingResult with transaction and its hash
    public func sendRawTransaction(_ transaction: EthereumTransaction) throws -> TransactionSendingResult {
        return try sendRawTransactionPromise(transaction).wait()
    }

	/// - Parameter address: Transaction sender address
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
    /// or the expected state after all the transactions in memory pool are applied ("pending").
	/// - Returns: A total number of transactions sent by the particular Ethereum address.
    /// - Important: This function is synchronous!
    public func getTransactionCount(address: Address, onBlock: String = "latest") throws -> BigUInt {
        return try getTransactionCountPromise(address: address, onBlock: onBlock).wait()
    }
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
    /// or the expected state after all the transactions in memory pool are applied ("pending").
	/// - Returns: A balance of particular Ethereum address in Wei units (1 ETH = 10^18 Wei).
    ///
    /// - Important: This function is synchronous!
    public func getBalance(address: Address, onBlock: String = "latest") throws -> BigUInt {
        return try getBalancePromise(address: address, onBlock: onBlock).wait()
    }

    /// - Returns: A block number of the last mined block that Ethereum node knows about.
    ///
    /// - Important: This function is synchronous!
    public func getBlockNumber() throws -> BigUInt {
        return try getBlockNumberPromise().wait()
    }

    /// - Returns: A current gas price in the units of Wei. The node has internal algorithms for averaging over the last few blocks.
    ///
    /// - Important: This function is synchronous!
    public func getGasPrice() throws -> BigUInt {
        return try getGasPricePromise().wait()
    }

    /// - Returns: Transaction details for particular transaction hash. Details indicate position of the transaction in a particular block,
    /// as well as original transaction details such as value, gas limit, gas price, etc.
    ///
    /// - Important: This function is synchronous!
    public func getTransactionDetails(_ txhash: Data) throws -> TransactionDetails {
        return try getTransactionDetailsPromise(txhash).wait()
    }

    /// - Returns: Transaction details for particular transaction hash. Details indicate position of the transaction in a particular block,
    /// as well as original transaction details such as value, gas limit, gas price, etc.
    ///
    /// - Important: This function is synchronous!
    ///
    /// - Returns: TransactionDetails object
    public func getTransactionDetails(_ txhash: String) throws -> TransactionDetails {
        return try getTransactionDetailsPromise(txhash).wait()
    }

    /// - Parameter txhash: Transaction hash
	/// - Returns: Transaction receipt for particular transaction hash. Receipt indicate what has happened when the transaction
	/// was included in block, so it contains logs and status, such as succesful or failed transaction.
	/// - Important: This function is synchronous!
    public func getTransactionReceipt(_ txhash: Data) throws -> TransactionReceipt {
        return try getTransactionReceiptPromise(txhash).wait()
    }

	/// - Parameter txhash: Transaction hash
	/// - Returns: Transaction receipt for particular transaction hash. Receipt indicate what has happened when the transaction
	/// was included in block, so it contains logs and status, such as succesful or failed transaction.
	/// - Important: This function is synchronous!
    public func getTransactionReceipt(_ txhash: String) throws -> TransactionReceipt {
        return try getTransactionReceiptPromise(txhash).wait()
    }

    /// Estimates a minimal amount of gas required to run a transaction. To do it the Ethereum node tries to run it and counts
    /// how much gas it consumes for computations. Setting the transaction gas limit lower than the estimate will most likely
    /// result in a failing transaction.
    ///
	/// - Parameter onBlock: field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
    /// or the expected state after all the transactions in memory pool are applied ("pending").
    ///
    /// - Important: This function is synchronous!
    /// - Returns: Maximum amount of gas that would be used in the transaction
	/// - Throws: Error can also indicate that transaction is invalid in the current state, so formally it's gas limit is infinite.
    /// An example of such transaction can be sending an amount of ETH that is larger than the current account balance.
    public func estimateGas(_ transaction: EthereumTransaction, options: Web3Options?, onBlock: String = "latest") throws -> BigUInt {
        return try estimateGasPromise(transaction, options: options, onBlock: onBlock).wait()
    }

    /// Get a list of Ethereum accounts that a node knows about.
    /// If one has attached a Keystore Manager to the web3 object it returns accounts known to the keystore.
    /// - Important: This function is synchronous!
    /// - Returns: Array of addresses in the node
    public func getAccounts() throws -> [Address] {
        return try getAccountsPromise().wait()
    }

    /// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
    /// this call fill do a virtual join and fetch not just transaction hashes from this block,
    /// but full decoded EthereumTransaction objects.
    ///
    /// - Important: This function is synchronous!
    /// - Returns: Found Block
    public func getBlockByHash(_ hash: String, fullTransactions: Bool = false) throws -> Block {
        return try getBlockByHashPromise(hash, fullTransactions: fullTransactions).wait()
    }

    /// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
    /// this call fill do a virtual join and fetch not just transaction hashes from this block,
    /// but full decoded EthereumTransaction objects.
    ///
    /// - Important: This function is synchronous!
    ///
    /// - Returns: Found Block
    public func getBlockByHash(_ hash: Data, fullTransactions: Bool = false) throws -> Block {
        return try getBlockByHashPromise(hash, fullTransactions: fullTransactions).wait()
    }

    /// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
    /// this call fill do a virtual join and fetch not just transaction hashes from this block,
    /// but full decoded EthereumTransaction objects.
    ///
    /// - Important: This function is synchronous!
    ///
    /// - Returns: Found Block
    public func getBlockByNumber(_ number: UInt64, fullTransactions: Bool = false) throws -> Block {
        return try getBlockByNumberPromise(number, fullTransactions: fullTransactions).wait()
    }

    /// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
    /// this call fill do a virtual join and fetch not just transaction hashes from this block,
    /// but full decoded EthereumTransaction objects.
    ///
    /// - Important: This function is synchronous!
    ///
	/// - Returns: Found Block
    public func getBlockByNumber(_ number: BigUInt, fullTransactions: Bool = false) throws -> Block {
        return try getBlockByNumberPromise(number, fullTransactions: fullTransactions).wait()
    }

    /// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
    /// this call fill do a virtual join and fetch not just transaction hashes from this block,
    /// but full decoded EthereumTransaction objects.
    ///
    /// - Important: This function is synchronous!
    ///
	/// - Returns: Found Block
    public func getBlockByNumber(_ block: String, fullTransactions: Bool = false) throws -> Block {
        return try getBlockByNumberPromise(block, fullTransactions: fullTransactions).wait()
    }

    /**
     Convenience wrapper to send Ethereum to another address. Internally it creates a virtual contract and encodes all the options and data.
     - Parameter to: Address to send funds to
     - Parameter amount: BigUInt indicating the amount in wei
     - Parameter extraData: Additional data to attach to the transaction
     - Parameter options: Web3Options to override the default gas price, gas limit. "Value" field of the options is ignored and the "amount" parameter is used instead

     - Returns: TransactionIntermediate object
     */
    public func sendETH(to: Address, amount: BigUInt, extraData: Data = Data(), options: Web3Options? = nil) throws -> TransactionIntermediate {
        let contract = try web3.contract(Web3Utils.coldWalletABI, at: to)
        var mergedOptions = self.options.merge(with: options)
        mergedOptions.value = amount
        return try contract.method("fallback", extraData: extraData, options: mergedOptions)
    }
	
	/// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
	/// this call fill do a virtual join and fetch not just transaction hashes from this block,
	/// but full decoded EthereumTransaction objects.
	///
	/// - Returns: Found Block
    public func getBlockNumberPromise() -> Promise<BigUInt> {
		let request = JsonRpcRequest(method: .blockNumber)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue) { response in
            guard let value: BigUInt = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
	
	/// - Returns: A current gas price in the units of Wei. The node has internal algorithms for averaging over the last few blocks.
    public func getGasPricePromise() -> Promise<BigUInt> {
        let request = JsonRpcRequest(method: .gasPrice)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue) { response in
            guard let value: BigUInt = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
    
	/// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
	/// this call fill do a virtual join and fetch not just transaction hashes from this block,
	/// but full decoded EthereumTransaction objects.
	///
	/// - Returns: Found Block
    public func getBlockByHashPromise(_ hash: Data, fullTransactions: Bool = false) -> Promise<Block> {
        let hashString = hash.hex.withHex
        return getBlockByHashPromise(hashString, fullTransactions: fullTransactions)
    }
	
	/// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
	/// this call fill do a virtual join and fetch not just transaction hashes from this block,
	/// but full decoded EthereumTransaction objects.
	///
	/// - Returns: Found Block
    public func getBlockByHashPromise(_ hash: String, fullTransactions: Bool = false) -> Promise<Block> {
        let request = JsonRpcRequest(method: .getBlockByHash, parameters: hash, fullTransactions)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue) { response in
            guard let value: Block = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
    
	
	/// - Returns: Transaction details for particular transaction hash. Details indicate position of the transaction in a particular block,
	/// as well as original transaction details such as value, gas limit, gas price, etc.
    public func getTransactionDetailsPromise(_ txhash: Data) -> Promise<TransactionDetails> {
        let hashString = txhash.hex.withHex
        return getTransactionDetailsPromise(hashString)
    }
	
	/// - Returns: Transaction details for particular transaction hash. Details indicate position of the transaction in a particular block,
	/// as well as original transaction details such as value, gas limit, gas price, etc.
    public func getTransactionDetailsPromise(_ txhash: String) -> Promise<TransactionDetails> {
        let request = JsonRpcRequest(method: .getTransactionByHash, parameters: txhash)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue) { response in
            guard let value: TransactionDetails = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
    
	
	/// Send an EthereumTransaction object to the network. Transaction is either signed locally if there is a KeystoreManager
	/// object bound to the web3 instance, or sent unsigned to the node. For local signing the password is required.
	///
	/// - Parameter transaction: Transaction to send
	/// - Parameter options: Object can override the "to", "gasPrice", "gasLimit" and "value" parameters is pre-formed transaction.
	/// "from" field in "options" is mandatory for both local and remote signing.
	/// - Parameter password: Password to decrypt sender's private key
    public func sendTransactionPromise(_ transaction: EthereumTransaction, options: Web3Options, password: String = "BANKEXFOUNDATION") -> Promise<TransactionSendingResult> {
        //        print(transaction)
        var assembledTransaction: EthereumTransaction = transaction.mergedWithOptions(options)
        let queue = web3.requestDispatcher.queue
        do {
            if web3.provider.attachedKeystoreManager.isEmpty {
                guard let request = EthereumTransaction.createRequest(method: .sendTransaction, transaction: assembledTransaction, onBlock: nil, options: options) else {
                    throw Web3Error.processingError("Failed to create a request to send transaction")
                }
                return web3.dispatch(request).map(on: queue) { response in
                    guard let value: String = response.getValue() else {
                        if response.error != nil {
                            throw Web3Error.nodeError(response.error!.message)
                        }
                        throw Web3Error.nodeError("Invalid value from Ethereum node")
                    }
                    let result = TransactionSendingResult(transaction: assembledTransaction, hash: value)
                    return result
                }
            }
            guard let from = options.from else {
                throw Web3Error.inputError("No 'from' field provided")
            }
            do {
                try Web3Signer.signTX(transaction: &assembledTransaction, keystore: web3.provider.attachedKeystoreManager, account: from, password: password)
            } catch {
                throw Web3Error.inputError("Failed to locally sign a transaction")
            }
            return web3.eth.sendRawTransactionPromise(assembledTransaction)
        } catch {
            let returnPromise = Promise<TransactionSendingResult>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
	
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
	/// or the expected state after all the transactions in memory pool are applied ("pending").
	/// - Returns: A balance of particular Ethereum address in Wei units (1 ETH = 10^18 Wei).
	public func getBalancePromise(address: Address, onBlock: String = "latest") -> Promise<BigUInt> {
		let request = JsonRpcRequest(method: .getBalance, parameters: address._address.lowercased(), onBlock)
		let rp = web3.dispatch(request)
		let queue = web3.requestDispatcher.queue
		return rp.map(on: queue) { response in
			guard let value: BigUInt = response.getValue() else {
				if response.error != nil {
					throw Web3Error.nodeError(response.error!.message)
				}
				throw Web3Error.nodeError("Invalid value from Ethereum node")
			}
			return value
		}
	}
    
	
	/// - Parameter txhash: Transaction hash
	/// - Returns: Transaction receipt for particular transaction hash. Receipt indicate what has happened when the transaction
	/// was included in block, so it contains logs and status, such as succesful or failed transaction.
	/// - Important: This function is synchronous!
    public func getTransactionReceiptPromise(_ txhash: Data) -> Promise<TransactionReceipt> {
        let hashString = txhash.hex.withHex
        return getTransactionReceiptPromise(hashString)
    }
	
	/// - Parameter txhash: Transaction hash
	/// - Returns: Transaction receipt for particular transaction hash. Receipt indicate what has happened when the transaction
	/// was included in block, so it contains logs and status, such as succesful or failed transaction.
	/// - Important: This function is synchronous!
    public func getTransactionReceiptPromise(_ txhash: String) -> Promise<TransactionReceipt> {
        let request = JsonRpcRequest(method: .getTransactionReceipt, parameters: txhash)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue) { response in
            guard let value: TransactionReceipt = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
	/// Estimates a minimal amount of gas required to run a transaction. To do it the Ethereum node tries to run it and counts
	/// how much gas it consumes for computations. Setting the transaction gas limit lower than the estimate will most likely
	/// result in a failing transaction.
	///
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
	/// or the expected state after all the transactions in memory pool are applied ("pending").
	///
	/// - Important: This function is synchronous!
	/// - Returns: Maximum amount of gas that would be used in the transaction
	/// - Throws: Error can also indicate that transaction is invalid in the current state, so formally it's gas limit is infinite.
	/// An example of such transaction can be sending an amount of ETH that is larger than the current account balance.
    func estimateGasPromise(_ transaction: EthereumTransaction, options: Web3Options? = nil, onBlock: String = "latest") -> Promise<BigUInt> {
        let queue = web3.requestDispatcher.queue
        do {
            guard let request = EthereumTransaction.createRequest(method: .estimateGas, transaction: transaction, onBlock: onBlock, options: options) else {
                throw Web3Error.processingError("Transaction is invalid")
            }
            let rp = web3.dispatch(request)
            return rp.map(on: queue) { response in
                guard let value: BigUInt = response.getValue() else {
                    if response.error != nil {
                        throw Web3Error.nodeError(response.error!.message)
                    }
                    throw Web3Error.nodeError("Invalid value from Ethereum node")
                }
                return value
            }
        } catch {
            let returnPromise = Promise<BigUInt>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
    
	/// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
	/// this call fill do a virtual join and fetch not just transaction hashes from this block,
	/// but full decoded EthereumTransaction objects.
	///
	/// - Important: This function is synchronous!
	///
	/// - Returns: Found Block
    public func getBlockByNumberPromise(_ number: UInt64, fullTransactions: Bool = false) -> Promise<Block> {
        let block = String(number, radix: 16).withHex
        return getBlockByNumberPromise(block, fullTransactions: fullTransactions)
    }
	
	/// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
	/// this call fill do a virtual join and fetch not just transaction hashes from this block,
	/// but full decoded EthereumTransaction objects.
	///
	/// - Important: This function is synchronous!
	///
	/// - Returns: Found Block
    public func getBlockByNumberPromise(_ number: BigUInt, fullTransactions: Bool = false) -> Promise<Block> {
        let block = String(number, radix: 16).withHex
        return getBlockByNumberPromise(block, fullTransactions: fullTransactions)
    }
	
	/// Get information about the particular block in Ethereum network. If "fullTransactions" parameter is set to "true"
	/// this call fill do a virtual join and fetch not just transaction hashes from this block,
	/// but full decoded EthereumTransaction objects.
	///
	/// - Important: This function is synchronous!
	///
	/// - Returns: Found Block
    public func getBlockByNumberPromise(_ number: String, fullTransactions: Bool = false) -> Promise<Block> {
        let request = JsonRpcRequest(method: .getBlockByNumber, parameters: number, fullTransactions)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue) { response in
            guard let value: Block = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
	
	/// Send raw Ethereum transaction data to the network.
	/// - Parameter transaction: Transaction to send
	/// - Important: This function is synchronous!
	/// - Returns: TransactionSendingResult with transaction and its hash
    func sendRawTransactionPromise(_ transaction: Data) -> Promise<TransactionSendingResult> {
        guard let deserializedTX = EthereumTransaction.fromRaw(transaction) else {
            let promise = Promise<TransactionSendingResult>.pending()
            promise.resolver.reject(Web3Error.processingError("Serialized TX is invalid"))
            return promise.promise
        }
        return sendRawTransactionPromise(deserializedTX)
    }
	
	/// Send raw Ethereum transaction data to the network.
	/// - Parameter transaction: Transaction to send
	/// - Important: This function is synchronous!
	/// - Returns: TransactionSendingResult with transaction and its hash
    func sendRawTransactionPromise(_ transaction: EthereumTransaction) -> Promise<TransactionSendingResult> {
        //        print(transaction)
        let queue = web3.requestDispatcher.queue
        do {
            guard let request = EthereumTransaction.createRawTransaction(transaction: transaction) else {
                throw Web3Error.processingError("Transaction is invalid")
            }
            let rp = web3.dispatch(request)
            return rp.map(on: queue) { response in
                guard let value: String = response.getValue() else {
                    if response.error != nil {
                        throw Web3Error.nodeError(response.error!.message)
                    }
                    throw Web3Error.nodeError("Invalid value from Ethereum node")
                }
                let result = TransactionSendingResult(transaction: transaction, hash: value)
                return result
            }
        } catch {
            let returnPromise = Promise<TransactionSendingResult>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
    
	/// - Parameter address: Transaction sender address
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
	/// or the expected state after all the transactions in memory pool are applied ("pending").
	/// - Returns: A total number of transactions sent by the particular Ethereum address.
	/// - Important: This function is synchronous!
    public func getTransactionCountPromise(address: Address, onBlock: String = "latest") -> Promise<BigUInt> {
        let addr = address.address
        return getTransactionCountPromise(address: addr, onBlock: onBlock)
    }
	
	/// - Parameter address: Transaction sender address
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
	/// or the expected state after all the transactions in memory pool are applied ("pending").
	/// - Returns: A total number of transactions sent by the particular Ethereum address.
	/// - Important: This function is synchronous!
    public func getTransactionCountPromise(address: String, onBlock: String = "latest") -> Promise<BigUInt> {
        let request = JsonRpcRequest(method: .getTransactionCount, parameters: address.lowercased(), onBlock)
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue) { response in
            guard let value: BigUInt = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
    
	/// Get a list of Ethereum accounts that a node knows about.
	/// If one has attached a Keystore Manager to the web3 object it returns accounts known to the keystore.
	/// - Important: This function is synchronous!
	/// - Returns: Array of addresses in the node
    public func getAccountsPromise() -> Promise<[Address]> {
        let queue = web3.requestDispatcher.queue
        if !web3.provider.attachedKeystoreManager.isEmpty {
            let promise = Promise<[Address]>.pending()
            queue.async {
                let accounts = self.web3.wallet.getAccounts()
                promise.resolver.fulfill(accounts)
            }
            return promise.promise
        }
        let request = JsonRpcRequest(method: .getAccounts)
        let rp = web3.dispatch(request)
        return rp.map(on: queue) { response in
            guard let value: [Address] = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(response.error!.message)
                }
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
        }
    }
    
	/// Performs a non-mutating "call" to some smart-contract. EthereumTransaction bears all function parameters required for the call.
	/// Does NOT decode the data returned from the smart-contract.
	/// - Parameter transaction: Transaction to send
	/// - Parameter options: Object can override the "to", "gasPrice", "gasLimit" and "value" parameters is pre-formed transaction.
	/// "from" field in "options" is mandatory for both local and remote signing.
	/// - Parameter onBlock: Field determines if value is returned based on the state of a blockchain on the latest mined block ("latest")
	/// or the expected state after all the transactions in memory pool are applied ("pending").
	/// - Important: This function is synchronous!
	/// - Returns: Smart contract response
    func callPromise(_ transaction: EthereumTransaction, options: Web3Options, onBlock: String = "latest") -> Promise<Data> {
        let queue = web3.requestDispatcher.queue
        do {
            guard let request = EthereumTransaction.createRequest(method: .call, transaction: transaction, onBlock: onBlock, options: options) else {
                throw Web3Error.processingError("Transaction is invalid")
            }
            let rp = web3.dispatch(request)
            return rp.map(on: queue) { response in
                guard let value: Data = response.getValue() else {
                    if response.error != nil {
                        throw Web3Error.nodeError(response.error!.message)
                    }
                    throw Web3Error.nodeError("Invalid value from Ethereum node")
                }
                return value
            }
        } catch {
            let returnPromise = Promise<Data>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
}
