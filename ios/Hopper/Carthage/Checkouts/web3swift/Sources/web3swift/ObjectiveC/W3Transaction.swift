//
//  W3Transaction.swift
//  web3swift
//
//  Created by Dmitry on 11/9/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

extension EthereumTransaction {
    public var objc: W3EthereumTransaction {
		return W3EthereumTransaction(self)
	}
}
@objc public class W3EthereumTransaction: NSObject, SwiftContainer {
	public var swift: EthereumTransaction
	public required init(_ swift: EthereumTransaction) {
		self.swift = swift
	}
	@objc public var nonce: W3UInt {
		get { return swift.nonce.objc }
		set { swift.nonce = newValue.swift }
	}
	@objc public var gasPrice: W3UInt {
		get { return swift.gasPrice.objc }
		set { swift.gasPrice = newValue.swift }
	}
	@objc public var gasLimit: W3UInt {
		get { return swift.gasLimit.objc }
		set { swift.gasLimit = newValue.swift }
	}
	@objc public var to: W3Address {
		get { return swift.to.objc }
		set { swift.to = newValue.swift }
	}
	@objc public var data: Data {
		get { return swift.data }
		set { swift.data = newValue }
	}
	@objc public var value: W3UInt {
		get { return swift.value.objc }
		set { swift.value = newValue.swift }
	}
	@objc public var v: W3UInt {
		get { return swift.v.objc }
		set { swift.v = newValue.swift }
	}
	@objc public var r: W3UInt {
		get { return swift.r.objc }
		set { swift.r = newValue.swift }
	}
	@objc public var s: W3UInt {
		get { return swift.s.objc }
		set { swift.s = newValue.swift }
	}
	
	@objc public var inferedChainID: W3NetworkId? {
		return swift.inferedChainID?.objc
	}
	
	@objc public var intrinsicChainID: W3UInt? {
		return swift.intrinsicChainID?.objc
	}
	
	@objc public func UNSAFE_setChainID(_ chainID: W3NetworkId?) {
		swift.UNSAFE_setChainID(chainID?.swift)
	}
	@objc public var transactionHash: Data? {
		return swift.hash
	}
	
	@objc public init(gasPrice: W3UInt, gasLimit: W3UInt, to: W3Address, value: W3UInt, data: Data) {
		swift = EthereumTransaction(gasPrice: gasPrice.swift, gasLimit: gasLimit.swift, to: to.swift, value: value.swift, data: data)
	}
	
	@objc public init(to: W3Address, data: Data, options: W3Options) {
		swift = EthereumTransaction(to: to.swift, data: data, options: options.swift)
	}
	
	@objc public init(nonce: W3UInt, gasPrice: W3UInt, gasLimit: W3UInt, to: W3Address, value: W3UInt, data: Data, v: W3UInt, r: W3UInt, s: W3UInt) {
		swift = EthereumTransaction(nonce: nonce.swift, gasPrice: gasPrice.swift, gasLimit: gasLimit.swift, to: to.swift, value: value.swift, data: data, v: v.swift, r: r.swift, s: s.swift)
	}
	
	@objc public func mergedWithOptions(_ options: W3Options) -> W3EthereumTransaction {
		return swift.mergedWithOptions(options.swift).objc
	}
	
	@objc public override var description: String {
		return swift.description
	}
	
	@objc public var sender: W3Address? {
		return swift.sender?.objc
	}
	
	@objc public func recoverPublicKey() -> Data? {
		return swift.recoverPublicKey()
	}
	
	@objc public var txhash: String? {
		return swift.txhash
	}
	
	@objc public var txid: String? {
		return swift.txid
	}
	
	@objc public func encode(forSignature: Bool = false, chainId: W3NetworkId? = nil) -> Data? {
		return swift.encode(forSignature: forSignature, chainId: chainId?.swift)
	}
	
	@objc public func encodeAsDictionary(from: W3Address? = nil) -> W3TransactionParameters? {
		return swift.encodeAsDictionary(from: from?.swift)?.objc
	}
	
	@objc public func hashForSignature(chainID: W3NetworkId? = nil) -> Data? {
		return swift.hashForSignature(chainID: chainID?.swift)
	}
	@objc public static func fromRaw(_ raw: Data) -> W3EthereumTransaction? {
		return EthereumTransaction.fromRaw(raw)?.objc
	}
}
