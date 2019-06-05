//
//  Web3+JSONRPC.swift
//  web3swift
//
//  Created by Alexander Vlasov on 21.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Global counter object to enumerate JSON RPC requests.
struct Counter {
    static var current = 1
    static var lockQueue = DispatchQueue(label: "counterQueue")
    static func increment() -> Int {
        var c: Int = 0
        lockQueue.sync {
            c = Counter.current
            Counter.current = Counter.current + 1
        }
        return c
    }
}


/// JSON RPC request structure for serialization and deserialization purposes.
public struct JsonRpcRequest: Encodable {
    /// jsonrpc version
    public var jsonrpc: String = "2.0"
    /// node api
    public var method: JsonRpcMethod
    /// node input
    public var params: JsonRpcParams
    /// request local id
    public var id: Int = Counter.increment()
    
    /// A type that can be used as a key for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case method
        case params
        case id
    }
	
	/// init with api method and parameters
	public init(method: JsonRpcMethod, parameters: Encodable...) {
		self.method = method
		self.params = JsonRpcParams(params: parameters)
	}
    /// init with api method and parameters
	public init(method: JsonRpcMethod, parametersArray: [Encodable]) {
		self.method = method
		self.params = JsonRpcParams(params: parametersArray)
	}
    
    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method.api, forKey: .method)
        try container.encode(params, forKey: .params)
        try container.encode(id, forKey: .id)
    }
    
    /// checks if input parameters.count is equal to method.parameters
    public var isValid: Bool {
        return method.parameters == params.params.count
    }
}

/// JSON RPC batch request structure for serialization and deserialization purposes.
public struct JsonRpcRequestBatch: Encodable {
    var requests: [JsonRpcRequest]

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(requests)
    }
}

/// JSON RPC response structure for serialization and deserialization purposes.
public struct JsonRpcResponse: Decodable {
	/// Request id
    public var id: Int
	/// JsonRpc version
    public var jsonrpc = "2.0"
	/// JsonRpc optional result at "data" key
    public var result: Any?
	/// JsonRpc optional error
    public var error: ErrorMessage?
	/// JsonRpc optional error message
    public var message: String?
	
	/// - Returns: .result as DictionaryReader or throw .error
	/// - Throws: Web3Error.nodeError(error.message), Web3Error.nodeError("No response found")
    public func response() throws -> AnyReader {
        if let error = error {
            throw Web3Error.nodeError(error.message)
        } else if let result = result {
            return AnyReader(result)
        } else {
            throw Web3Error.nodeError("No response found")
        }
    }
	
    enum JSONRPCresponseKeys: String, CodingKey {
        case id
        case jsonrpc
        case result
        case error
    }
	
	/// Init with parameters (for testing purpose?)
    public init(id: Int, jsonrpc: String, result: Any?, error: ErrorMessage?) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.result = result
        self.error = error
    }
	
	/// Error message from jsonrpc response
    public struct ErrorMessage: Decodable {
		/// Error code
        public var code: Int
		/// Error message
        public var message: String
    }
    
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONRPCresponseKeys.self)
        let id: Int = try container.decode(Int.self, forKey: .id)
        let jsonrpc: String = try container.decode(String.self, forKey: .jsonrpc)
        let errorMessage = try container.decodeIfPresent(ErrorMessage.self, forKey: .error)
        if errorMessage != nil {
            self.init(id: id, jsonrpc: jsonrpc, result: nil, error: errorMessage)
            return
        }
        var result: Any?
        
        if let rawValue = try? container.decodeIfPresent(String.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(Int.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(Bool.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(EventLog.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(Block.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(TransactionReceipt.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(TransactionDetails.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([EventLog].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([Block].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([TransactionReceipt].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([TransactionDetails].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([Bool].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([Int].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: String].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: Int].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: Any].self, forKey: .result) {
            result = rawValue
        }
        self.init(id: id, jsonrpc: jsonrpc, result: result, error: nil)
    }

    /// Get the JSON RCP reponse value by deserializing it into some native <T> class.
    ///
    /// Returns nil if serialization fails
    public func getValue<T>() -> T? {
        let slf = T.self
        if slf == BigUInt.self {
            guard let string = self.result as? String else { return nil }
            guard let value = BigUInt(string.withoutHex, radix: 16) else { return nil }
            return value as? T
        } else if slf == BigInt.self {
            guard let string = self.result as? String else { return nil }
            guard let value = BigInt(string.withoutHex, radix: 16) else { return nil }
            return value as? T
        } else if slf == Data.self {
            guard let string = self.result as? String else { return nil }
            guard let value = Data.fromHex(string) else { return nil }
            return value as? T
        } else if slf == Address.self {
            guard let string = self.result as? String else { return nil }
            let value = Address(string)
            guard value.isValid else { return nil }
            return value as? T
        } else if slf == [BigUInt].self {
            guard let string = self.result as? [String] else { return nil }
            let values = string.compactMap { (str) -> BigUInt? in
                return BigUInt(str.withoutHex, radix: 16)
            }
            return values as? T
        } else if slf == [BigInt].self {
            guard let string = self.result as? [String] else { return nil }
            let values = string.compactMap { (str) -> BigInt? in
                return BigInt(str.withoutHex, radix: 16)
            }
            return values as? T
        } else if slf == [Data].self {
            guard let string = self.result as? [String] else { return nil }
            let values = string.compactMap { (str) -> Data? in
                return Data.fromHex(str)
            }
            return values as? T
        } else if slf == [Address].self {
            guard let string = self.result as? [String] else { return nil }
            let values = string.compactMap { (str) -> Address? in
                let address = Address(str)
                guard address.isValid else { return nil }
                return address
            }
            return values as? T
        }
        guard let value = self.result as? T else { return nil }
        return value
    }
}

/// JSON RPC batch response structure for serialization and deserialization purposes.
/// Stores response for each request in the same order as it sent
public struct JsonRpcResponseBatch: Decodable {
    /// response for each request. stores in the same order as sent
    var responses: [JsonRpcResponse]
    
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let responses = try container.decode([JsonRpcResponse].self)
        self.responses = responses
    }
}

/// Transaction parameters JSON structure for interaction with Ethereum node.
public struct TransactionParameters: Codable {
    /// transaction parameters
    public var data: String?
    /// transaction sender
    public var from: String?
    /// gas limit
    public var gas: String?
    /// gas price
    public var gasPrice: String?
    /// transaction recipient
    public var to: String?
    /// ether value
    public var value: String? = "0x0"
    
    /// init with sender and recipient
    public init(from _from: String?, to _to: String?) {
        from = _from
        to = _to
    }
}

/// Event filter parameters JSON structure for interaction with Ethereum node.
public struct EventFilterParameters: Codable {
	/// from
    public var fromBlock: String?
	/// to
    public var toBlock: String?
	/// topics array
    public var topics: [[String?]?]?
	/// addresses
    public var address: [String?]?
}

/// Raw JSON RCP 2.0 internal flattening wrapper.
public struct JsonRpcParams: Encodable {
    /// Raw parameters
    public var params = [Any]()

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for par in params {
            if let p = par as? TransactionParameters {
                try container.encode(p)
            } else if let p = par as? String {
                try container.encode(p)
            } else if let p = par as? Bool {
                try container.encode(p)
            } else if let p = par as? EventFilterParameters {
                try container.encode(p)
            }
        }
    }
}
