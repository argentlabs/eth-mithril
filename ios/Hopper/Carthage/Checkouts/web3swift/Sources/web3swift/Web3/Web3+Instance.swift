//
//  Web3+Instance.swift
//  web3swift
//
//  Created by Alexander Vlasov on 19.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation
import PromiseKit

/// A web3 instance bound to provider. All further functionality is provided under web.*. namespaces.
public class Web3: Web3OptionsInheritable {
	/**
	Default Web3 instance.
	
	Uses as default Web3 in blockchain if you didn't provide any.
	
	default: `Web3(infura: .mainnet)`
	*/
    public static var `default`: Web3 = Web3(infura: .mainnet)
	/// Web3 provider. Contains Keystore Manager, node URL and Network id
    public var provider: Web3Provider
	/// Default options. Merges with provided options in every transaction
    public var options: Web3Options = .default
	/// default block. default: "latest"
    public var defaultBlock = "latest"
	/**
	request dispatcher.
	
	by default on sending request, waits 0.1 second for another request to combine them in one
	then sends up to 10 requests as one
	
	you can setup here request options
	*/
    public var requestDispatcher: JsonRpcRequestDispatcher
	
	/// Keystore manager which actually is a setter/getter for provider.attachedKeystoreManager
    public var keystoreManager: KeystoreManager {
        get { return provider.attachedKeystoreManager }
        set { provider.attachedKeystoreManager = newValue }
    }
	
	/// Contains transaction pool requests
    public var txpool: TxPool {
        return TxPool(web3: self)
    }
	
    /// Public web3.eth.* namespace.
    public lazy var eth = Web3Eth(provider: self.provider, web3: self)
    
    /// Public web3.personal.* namespace.
    public lazy var personal = Web3Personal(provider: self.provider, web3: self)
    
    /// Public web3.wallet.* namespace.
    public lazy var wallet = Web3Wallet(provider: self.provider, web3: self)
    
    /// Public web3.browserFunctions.* namespace.
    public lazy var browserFunctions = Web3BrowserFunctions(provider: self.provider, web3: self)

    /// Add a provider request to the dispatch queue.
    public func dispatch(_ request: JsonRpcRequest) -> Promise<JsonRpcResponse> {
        return requestDispatcher.addToQueue(request: request)
    }

    /// Raw initializer using a Web3Provider protocol object, dispatch queue and request dispatcher.
    public init(provider prov: Web3Provider, queue _: OperationQueue? = nil, requestDispatcher: JsonRpcRequestDispatcher? = nil) {
        provider = prov
        if requestDispatcher == nil {
            self.requestDispatcher = JsonRpcRequestDispatcher(provider: provider, queue: DispatchQueue.global(qos: .userInteractive), policy: .Batch(32))
        } else {
            self.requestDispatcher = requestDispatcher!
        }
    }

    /**
     Keystore manager can be bound to Web3 instance.
     If some manager is bound all further account related functions, such
     as account listing, transaction signing, etc.
     are done locally using private keys and accounts found in a manager.
     */
    public func addKeystoreManager(_ manager: KeystoreManager) {
        provider.attachedKeystoreManager = manager
    }
}
