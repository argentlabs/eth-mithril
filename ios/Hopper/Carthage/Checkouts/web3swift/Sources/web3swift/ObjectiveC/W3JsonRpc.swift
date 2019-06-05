//
//  W3JsonRpc.swift
//  web3swift
//
//  Created by Dmitry on 09/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension JsonRpcMethod {
    public var objc: W3JsonRpcMethod {
        return W3JsonRpcMethod(api: api, parameters: parameters)
    }
}

@objc public class W3JsonRpcMethod: NSObject, Encodable, SwiftBridgeable {
    public var swift: JsonRpcMethod {
        return JsonRpcMethod(api: api, parameters: parameters)
    }
    
    @objc public var api: String
    @objc public var parameters: Int
    @objc public init(api: String, parameters: Int) {
        self.api = api
        self.parameters = parameters
    }
    @objc public static let gasPrice = JsonRpcMethod.gasPrice.objc
    @objc public static let blockNumber = JsonRpcMethod.blockNumber.objc
    @objc public static let getNetwork = JsonRpcMethod.getNetwork.objc
    @objc public static let sendRawTransaction = JsonRpcMethod.sendRawTransaction.objc
    @objc public static let sendTransaction = JsonRpcMethod.sendTransaction.objc
    @objc public static let estimateGas = JsonRpcMethod.estimateGas.objc
    @objc public static let call = JsonRpcMethod.call.objc
    @objc public static let getTransactionCount = JsonRpcMethod.getTransactionCount.objc
    @objc public static let getBalance = JsonRpcMethod.getBalance.objc
    @objc public static let getCode = JsonRpcMethod.getCode.objc
    @objc public static let getStorageAt = JsonRpcMethod.getStorageAt.objc
    @objc public static let getTransactionByHash = JsonRpcMethod.getTransactionByHash.objc
    @objc public static let getTransactionReceipt = JsonRpcMethod.getTransactionReceipt.objc
    @objc public static let getAccounts = JsonRpcMethod.getAccounts.objc
    @objc public static let getBlockByHash = JsonRpcMethod.getBlockByHash.objc
    @objc public static let getBlockByNumber = JsonRpcMethod.getBlockByNumber.objc
    @objc public static let personalSign = JsonRpcMethod.personalSign.objc
    @objc public static let unlockAccount = JsonRpcMethod.unlockAccount.objc
    @objc public static let getLogs = JsonRpcMethod.getLogs.objc
    @objc public static let txPoolStatus = JsonRpcMethod.txPoolStatus.objc
    @objc public static let txPoolInspect = JsonRpcMethod.txPoolInspect.objc
    @objc public static let txPoolContent = JsonRpcMethod.txPoolContent.objc
}


extension JsonRpcRequest {
    public var objc: W3JsonRpcRequest {
        return W3JsonRpcRequest(self)
    }
}

@objc public class W3JsonRpcRequest: NSObject, SwiftContainer {
    public let swift: JsonRpcRequest
    public required init(_ swift: JsonRpcRequest) {
        self.swift = swift
    }
    /// init with api method
    @objc public required init(method: W3JsonRpcMethod) {
        self.swift = JsonRpcRequest(method: method.swift)
    }
    @objc public var isValid: Bool {
        return swift.isValid
    }
}
//
//@objc public class JsonRpcRequestBatch: NSObject {
//    var requests: [JsonRpcRequest]
//}

/// JSON RPC response structure for serialization and deserialization purposes.

extension JsonRpcResponse.ErrorMessage {
    public var objc: W3ErrorMessage {
		return W3ErrorMessage(self)
	}
}
@objc public class W3ErrorMessage: NSObject, SwiftContainer {
	@objc public var code: Int
	@objc public var message: String
    public var swift: JsonRpcResponse.ErrorMessage {
        return JsonRpcResponse.ErrorMessage(code: code, message: message)
    }
	public required init(_ swift: JsonRpcResponse.ErrorMessage) {
		code = swift.code
		message = swift.message
	}
}
extension JsonRpcResponse {
    public var objc: W3JsonRpcResponse {
		return W3JsonRpcResponse(self)
	}
}
@objc public class W3JsonRpcResponse: NSObject, SwiftContainer {
	public let swift: JsonRpcResponse
	public required init(_ swift: JsonRpcResponse) {
		self.swift = swift
	}
	@objc public var id: Int {
		return swift.id
	}
	@objc public var jsonrpc: String? {
		return swift.jsonrpc
	}
	@objc public var result: Any? {
		return swift.result
	}
	@objc public var error: W3ErrorMessage? {
		return swift.error?.objc
	}
	@objc public var message: String? {
		return swift.message
	}
	
}

extension JsonRpcResponseBatch {
    public var objc: W3JsonRpcResponseBatch {
		return W3JsonRpcResponseBatch(self)
	}
}

@objc public class W3JsonRpcResponseBatch: NSObject, SwiftContainer {
	public let swift: JsonRpcResponseBatch
	public required init(_ swift: JsonRpcResponseBatch) {
		self.swift = swift
	}
}

//extension EventFilterParameters {
//	public func _bridgeToObjectiveC() -> W3EventFilterParameters {
//		return W3EventFilterParameters(self)
//	}
//}
//@objc public class W3EventFilterParameters: NSObject, Codable, SwiftContainer {
//	public var swift: EventFilterParameters
//	public required init(_ swift: EventFilterParameters) {
//		self.swift = swift
//	}
//
//    @objc public var fromBlock: String?
//    @objc public var toBlock: String?
//    @objc public var topics: [[String]]?
//	  @objc public var address: [String]?
//}

extension JsonRpcParams {
    public var objc: W3JsonRpcParams {
		return W3JsonRpcParams(self)
	}
}
@objc public class W3JsonRpcParams: NSObject, SwiftContainer {
	public var swift: JsonRpcParams
	public required init(_ swift: JsonRpcParams) {
		self.swift = swift
	}
	
	@objc public var params: [Any] {
		get { return swift.params }
		set { swift.params = newValue.swift }
	}
}

extension JsonRpcRequestDispatcher {
    public var objc: W3JsonRpcRequestDispatcher {
		return W3JsonRpcRequestDispatcher(self)
	}
}

@objc public class W3JsonRpcRequestDispatcher: NSObject, SwiftContainer {
	public let swift: JsonRpcRequestDispatcher
	public required init(_ swift: JsonRpcRequestDispatcher) {
		self.swift = swift
	}
	
	@objc public var MAX_WAIT_TIME: TimeInterval {
		get { return swift.MAX_WAIT_TIME }
		set { swift.MAX_WAIT_TIME = newValue }
	}
	@objc public var batchLimit: Int {
		get {
			switch swift.policy {
			case .NoBatching:
				return 1
			case let .Batch(size):
				return size
			}
		} set {
			swift.policy = newValue > 1 ? .Batch(newValue) : .NoBatching
		}
	}
	@objc public var queue: DispatchQueue {
		get { return swift.queue }
		set { swift.queue = newValue }
	}
}
