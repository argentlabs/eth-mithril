//
//  W3TxPool.swift
//  web3swift
//
//  Created by Dmitry on 11/9/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

@objc public class W3TxPool: NSObject {
	@objc public unowned var web3: W3Web3
	@objc public init(web3: W3Web3) {
		self.web3 = web3
	}
	@objc public func status(completion: @escaping (W3TxPoolStatus?,Error?)->()) {
		web3.swift.txpool.status().done {
			completion($0.objc, nil)
		}.catch {
			completion(nil, $0)
		}
	}
	@objc public func inspect(completion: @escaping (W3TxPoolInspect?,Error?)->()) {
		web3.swift.txpool.inspect().done {
			completion($0.objc, nil)
		}.catch {
			completion(nil, $0)
		}
	}
	@objc public func content(completion: @escaping (W3TxPoolContent?,Error?)->()) {
		web3.swift.txpool.content().done {
			completion($0.objc, nil)
		}.catch {
			completion(nil, $0)
		}
	}
}

extension TxPoolStatus {
    public var objc: W3TxPoolStatus {
		return W3TxPoolStatus(self)
	}
}
@objc public class W3TxPoolStatus: NSObject, SwiftContainer {
	public let swift: TxPoolStatus
	public required init(_ swift: TxPoolStatus) {
		self.swift = swift
	}
	@objc public var pending: Int { return swift.pending }
	@objc public var queued: Int { return swift.queued }
}

extension TxPoolInspect {
    public var objc: W3TxPoolInspect {
		return W3TxPoolInspect(self)
	}
}
@objc public class W3TxPoolInspect: NSObject, SwiftContainer {
	public let swift: TxPoolInspect
	public required init(_ swift: TxPoolInspect) {
		self.swift = swift
	}
	@objc public var pending: [W3InspectedTransaction] { return swift.pending.map { $0.objc } }
	@objc public var queued: [W3InspectedTransaction] { return swift.queued.map { $0.objc } }
	
}

extension TxPoolInspect.Transaction {
    public var objc: W3InspectedTransaction {
		return W3InspectedTransaction(self)
	}
}
@objc public class W3InspectedTransaction: NSObject, SwiftContainer {
	public let swift: TxPoolInspect.Transaction
	public required init(_ swift: TxPoolInspect.Transaction) {
		self.swift = swift
	}
	@objc public var from: W3Address { return swift.from.objc }
	@objc public var nonce: Int { return swift.nonce }
	@objc public var to: W3Address { return swift.to.objc }
	@objc public var value: W3UInt { return swift.value.objc }
	@objc public var gasLimit: W3UInt { return swift.gasLimit.objc }
	@objc public var gasPrice: W3UInt { return swift.gasPrice.objc }
	
}

extension TxPoolContent {
    public var objc: W3TxPoolContent {
		return W3TxPoolContent(self)
	}
}
@objc public class W3TxPoolContent: NSObject, SwiftContainer {
	public let swift: TxPoolContent
	public required init(_ swift: TxPoolContent) {
		self.swift = swift
	}
	@objc public var pending: [W3TxPoolTransaction] { return swift.pending.map { $0.objc } }
	@objc public var queued: [W3TxPoolTransaction] { return swift.queued.map { $0.objc } }
	
}

extension TxPoolContent.Transaction {
    public var objc: W3TxPoolTransaction {
		return W3TxPoolTransaction(self)
	}
}
@objc public class W3TxPoolTransaction: NSObject, SwiftContainer {
	public let swift: TxPoolContent.Transaction
	public required init(_ swift: TxPoolContent.Transaction) {
		self.swift = swift
	}
	@objc public var from: W3Address { return swift.from.objc }
	@objc public var nonce: Int { return swift.nonce }
	@objc public var to: W3Address { return swift.to.objc }
	@objc public var value: W3UInt { return swift.value.objc }
	@objc public var gasLimit: W3UInt { return swift.gasLimit.objc }
	@objc public var gasPrice: W3UInt { return swift.gasPrice.objc }
	@objc public var input: Data { return swift.input }
	@objc public var transactionHash: Data { return swift.hash }
	@objc public var v: W3UInt { return swift.v.objc }
	@objc public var r: W3UInt { return swift.r.objc }
	@objc public var s: W3UInt { return swift.s.objc }
	@objc public var blockHash: Data { return swift.blockHash }
	@objc public var transactionIndex: W3UInt { return swift.transactionIndex.objc }
	
}


