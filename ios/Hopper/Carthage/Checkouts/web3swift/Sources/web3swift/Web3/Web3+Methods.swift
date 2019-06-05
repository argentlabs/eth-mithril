//
//  Web3+Methods.swift
//  web3swift
//
//  Created by Alexander Vlasov on 21.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import Foundation

/// Contains JsonRpc api methods and required number of parameters
public struct JsonRpcMethod: Encodable, Equatable {
	/// Method name
    public var api: String
	/// Required number of parameters
    public var parameters: Int
	
	/// init with api and parameters. Used for custom api methods
    public init(api: String, parameters: Int) {
        self.api = api
        self.parameters = parameters
    }
	
	/// eth_gasPrice method
    public static let gasPrice = JsonRpcMethod(api: "eth_gasPrice", parameters: 0)
	/// eth_blockNumber method
    public static let blockNumber = JsonRpcMethod(api: "eth_blockNumber", parameters: 0)
	/// net_version method
    public static let getNetwork = JsonRpcMethod(api: "net_version", parameters: 0)
	/// eth_sendRawTransaction method
    public static let sendRawTransaction = JsonRpcMethod(api: "eth_sendRawTransaction", parameters: 1)
	/// eth_sendTransaction method
    public static let sendTransaction = JsonRpcMethod(api: "eth_sendTransaction", parameters: 1)
	/// eth_estimateGas method
    public static let estimateGas = JsonRpcMethod(api: "eth_estimateGas", parameters: 1)
	/// eth_call method
    public static let call = JsonRpcMethod(api: "eth_call", parameters: 2)
	/// eth_getTransactionCount method
    public static let getTransactionCount = JsonRpcMethod(api: "eth_getTransactionCount", parameters: 2)
	/// eth_getBalance method
    public static let getBalance = JsonRpcMethod(api: "eth_getBalance", parameters: 2)
	/// eth_getCode method
    public static let getCode = JsonRpcMethod(api: "eth_getCode", parameters: 2)
	/// eth_getStorageAt method
    public static let getStorageAt = JsonRpcMethod(api: "eth_getStorageAt", parameters: 2)
	/// eth_getTransactionByHash method
    public static let getTransactionByHash = JsonRpcMethod(api: "eth_getTransactionByHash", parameters: 1)
	/// eth_getTransactionReceipt method
    public static let getTransactionReceipt = JsonRpcMethod(api: "eth_getTransactionReceipt", parameters: 1)
	/// eth_accounts method
    public static let getAccounts = JsonRpcMethod(api: "eth_accounts", parameters: 0)
	/// eth_getBlockByHash method
    public static let getBlockByHash = JsonRpcMethod(api: "eth_getBlockByHash", parameters: 2)
	/// eth_getBlockByNumber method
    public static let getBlockByNumber = JsonRpcMethod(api: "eth_getBlockByNumber", parameters: 2)
	/// eth_sign method
    public static let personalSign = JsonRpcMethod(api: "eth_sign", parameters: 1)
	/// personal_unlockAccount method
    public static let unlockAccount = JsonRpcMethod(api: "personal_unlockAccount", parameters: 1)
	/// eth_getLogs method
    public static let getLogs = JsonRpcMethod(api: "eth_getLogs", parameters: 1)
	/// txpool_status method
    public static let txPoolStatus = JsonRpcMethod(api: "txpool_status", parameters: 0)
	/// txpool_inspect method
    public static let txPoolInspect = JsonRpcMethod(api: "txpool_inspect", parameters: 0)
	/// txpool_content method
    public static let txPoolContent = JsonRpcMethod(api: "txpool_content", parameters: 0)
}
