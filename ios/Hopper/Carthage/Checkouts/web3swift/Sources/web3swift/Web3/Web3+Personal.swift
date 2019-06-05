//
//  Web3+Personal.swift
//  web3swift
//
//  Created by Alexander Vlasov on 14.04.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation
import PromiseKit

/// Personal functions
public class Web3Personal: Web3OptionsInheritable {
    /// provider for some functions
    var provider: Web3Provider
    unowned var web3: Web3
    /// Default options
    public var options: Web3Options {
        return web3.options
    }
	
	/// init with provider and web3 instanse
    public init(provider prov: Web3Provider, web3 web3instance: Web3) {
        provider = prov
        web3 = web3instance
    }
	
    /**
     *Locally or remotely sign a message (arbitrary data) with the private key. To avoid potential signing of a transaction the message is first prepended by a special header and then hashed.*

     - Parameter message: Message Data
     - Parameter from: Use a private key that corresponds to this account
     - Parameter password: Password for account if signing locally
     - Returns: signed message data
     - Important: This call is synchronous

     */
    public func signPersonalMessage(message: Data, from: Address, password: String = "BANKEXFOUNDATION") throws -> Data {
        return try signPersonalMessagePromise(message: message, from: from, password: password).wait()
    }

    /**
     *Unlock an account on the remote node to be able to send transactions and sign messages.*

     - Parameter account: Address of the account to unlock
     - Parameter password: Password to use for the account
     - Parameter seconds: Time inteval before automatic account lock by Ethereum node
     - Returns: isUnlocked
     - Important: This call is synchronous. Does nothing if private keys are stored locally.

     */
    public func unlockAccount(account: Address, password _: String = "BANKEXFOUNDATION", seconds _: UInt64 = 300) throws -> Bool {
        return try unlockAccountPromise(account: account).wait()
    }

    /**
     *Recovers a signer of some message. Message is first prepended by special prefix (check the "signPersonalMessage" method description) and then hashed.*
     
     - Parameter personalMessage: Message Data
     - Parameter signature: Serialized signature, 65 bytes
     - Returns: signer address

     */
    public func ecrecover(personalMessage: Data, signature: Data) throws -> Address {
        return try Web3Utils.personalECRecover(personalMessage, signature: signature)
    }

    /**
     *Recovers a signer of some hash. Checking what is under this hash is on behalf of the user.*
     
     - Parameter hash: Signed hash
     - Parameter signature: Serialized signature, 65 bytes
     - Returns: signer address

     */
    public func ecrecover(hash: Data, signature: Data) throws -> Address {
        return try Web3Utils.hashECRecover(hash: hash, signature: signature)
    }
    
    public func signPersonalMessagePromise(message: Data, from: Address, password: String = "BANKEXFOUNDATION") -> Promise<Data> {
        let queue = web3.requestDispatcher.queue
        do {
            if web3.provider.attachedKeystoreManager.isEmpty {
                let hexData = message.hex.withHex
				let request = JsonRpcRequest(method: .personalSign, parameters: from.address.lowercased(), hexData)
                return web3.dispatch(request).map(on: queue) { response in
                    guard let value: Data = response.getValue() else {
                        if response.error != nil {
                            throw Web3Error.nodeError(response.error!.message)
                        }
                        throw Web3Error.nodeError("Invalid value from Ethereum node")
                    }
                    return value
                }
            }
            let signature = try Web3Signer.signPersonalMessage(message, keystore: web3.provider.attachedKeystoreManager, account: from, password: password)
            let returnPromise = Promise<Data>.pending()
            queue.async {
                returnPromise.resolver.fulfill(signature)
            }
            return returnPromise.promise
        } catch {
            let returnPromise = Promise<Data>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
    
    
    func unlockAccountPromise(account: Address, password: String = "BANKEXFOUNDATION", seconds: UInt64 = 300) -> Promise<Bool> {
        let addr = account.address
        return unlockAccountPromise(account: addr, password: password, seconds: seconds)
    }
    
    func unlockAccountPromise(account: String, password: String = "BANKEXFOUNDATION", seconds: UInt64 = 300) -> Promise<Bool> {
        let queue = web3.requestDispatcher.queue
        do {
            if web3.provider.attachedKeystoreManager.isEmpty {
				let request = JsonRpcRequest(method: .unlockAccount, parameters: account.lowercased(), password, seconds)
                return web3.dispatch(request).map(on: queue) { response in
                    guard let value: Bool = response.getValue() else {
                        if response.error != nil {
                            throw Web3Error.nodeError(response.error!.message)
                        }
                        throw Web3Error.nodeError("Invalid value from Ethereum node")
                    }
                    return value
                }
            }
            throw Web3Error.inputError("Can not unlock a local keystore")
        } catch {
            let returnPromise = Promise<Bool>.pending()
            queue.async {
                returnPromise.resolver.reject(error)
            }
            return returnPromise.promise
        }
    }
    
}
