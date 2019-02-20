//
//  W3Web3.swift
//  web3swift
//
//  Created by Dmitry on 11/9/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension Web3Provider {
    public var objc: W3Web3HttpProvider {
		guard let provider = self as? Web3HttpProvider else { fatalError("\(self) is not convertible to objective-c W3Web3HttpProvider") }
		return provider.objc
	}
}

extension Web3 {
    public var objc: W3Web3 {
		return W3Web3(self)
	}
}

@objc public class W3Web3: NSObject, W3OptionsInheritable, SwiftContainer {
	public var swift: Web3
    var _swiftOptions: Web3Options {
        get { return swift.options }
        set { swift.options = newValue }
    }
	public required init(_ swift: Web3) {
		self.swift = swift
		super.init()
		options = W3Options(object: self)
	}
	
	@objc public static var `default`: W3Web3 {
		get { return Web3.default.objc }
		set { Web3.default = newValue.swift }
	}
	@objc public var provider: W3Web3HttpProvider {
		get { return swift.provider.objc }
		set { swift.provider = newValue.swift }
	}
	@objc public var options: W3Options!
	@objc public var defaultBlock: String {
		get { return swift.defaultBlock }
		set { swift.defaultBlock = newValue }
	}
	@objc public var requestDispatcher: W3JsonRpcRequestDispatcher {
		get { return swift.requestDispatcher.objc }
		set { swift.requestDispatcher = newValue.swift }
	}
	@objc public var keystoreManager: W3KeystoreManager {
		get { return swift.provider.attachedKeystoreManager.objc }
		set { swift.provider.attachedKeystoreManager = newValue.swift }
	}
	@objc public var txpool: W3TxPool {
		return W3TxPool(web3: self)
	}
	
	@objc public func dispatch(_ request: W3JsonRpcRequest, completion: @escaping (W3JsonRpcResponse?,Error?)->()) {
		swift.dispatch(request.swift).done {
			completion($0.objc,nil)
		}.catch {
			completion(nil,$0)
		}
	}
	
	@objc public init(provider prov: W3Web3HttpProvider, queue: OperationQueue? = nil) {
		swift = Web3(provider: prov.swift, queue: queue)
		super.init()
		options = W3Options(object: self)
	}
	
    @objc public lazy var eth = W3Eth(web3: self)
    @objc public lazy var personal = W3Personal(web3: self)
    @objc public lazy var wallet = W3Wallet(web3: self)
	
	@objc public init(infura networkId: W3NetworkId) {
		swift = Web3(infura: networkId.swift)
		super.init()
		options = W3Options(object: self)
	}
	
	@objc public init(infura networkId: W3NetworkId, accessToken: String) {
		swift = Web3(infura: networkId.swift, accessToken: accessToken)
		super.init()
		options = W3Options(object: self)
	}
	
	@objc public init?(url: URL) {
		guard let swift = Web3(url: url) else { return nil }
		self.swift = swift
		super.init()
		options = W3Options(object: self)
	}
    
    @objc public func addAccount(mnemonics: String, password: String) throws -> W3Address {
        let mnemonics = try Mnemonics(mnemonics)
        let keystore = try BIP32Keystore(mnemonics: mnemonics, password: password)
        keystoreManager.swift.append(keystore)
        return keystore.addresses.first!.objc
    }
    
    @objc public func addAccount(privateKey: Data, password: String) throws -> W3Address {
        guard let keystore = try EthereumKeystoreV3(privateKey: privateKey, password: password)
            else { throw SECP256K1Error.invalidPrivateKeySize }
        keystoreManager.swift.append(keystore)
        return keystore.addresses.first!.objc
    }
}
