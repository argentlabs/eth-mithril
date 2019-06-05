//
//  W3Structs.swift
//  web3swift
//
//  Created by Dmitry on 11/8/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

@objc public extension NSData {
    @objc func hexString() -> NSString {
        return (self as Data).hex as NSString
    }
}

@objc public extension NSString {
    @objc func hexData() -> NSData? {
        return (try? (self as String).dataFromHex()) as NSData?
    }
}

var opt: ObjcError {
	return .returnsOptionalValue
}
enum ObjcError: Error {
	case returnsOptionalValue
}

extension Address {
    public var objc: W3Address {
        return W3Address(self)
    }
}

extension Address.AddressType {
    public var objc: W3AddressType {
        switch self {
        case .normal: return .normal
        case .contractDeployment: return .contractDeployment
        }
    }
}
@objc public enum W3AddressType: Int, SwiftBridgeable {
	case normal, contractDeployment
	public var swift: Address.AddressType {
		switch self {
		case .normal: return .normal
		case .contractDeployment: return .contractDeployment
		}
	}
}

@objc public class W3Address: NSObject, SwiftContainer {
    public var swift: Address
    public required init(_ swift: Address) {
		self.swift = swift
	}
	@objc public init(string: String) {
		swift = Address(string, type: .normal)
	}
	@objc public init(data: Data) {
		swift = Address(data, type: .normal)
	}
	@objc public var isValid: Bool {
		return swift.isValid
	}
	@objc public var type: W3AddressType {
		get { return swift.type.objc }
		set { swift.type = newValue.swift }
	}
	@objc public var addressData: Data {
		return swift.addressData
	}
	@objc public var address: String {
		return swift.address
	}
	
	@objc public static func toChecksumAddress(_ addr: String) -> String? {
		return Address.toChecksumAddress(addr)
	}
	
	@objc public func check() throws {
		try swift.check()
	}
	
	@objc public static var contractDeployment: W3Address {
		return Address.contractDeployment.objc
	}
	@objc public override var description: String {
		return swift.description
	}
    
    @objc public func call(method: String, arguments: [Any]) throws -> W3SolidityDataReader {
        return try swift.call(method, arguments.swift).wait().objc
    }
    @objc public func send(method: String, arguments: [Any], password: String, options: W3Options?) throws -> W3TransactionSendingResult {
        return try swift.send(method, arguments.swift, password: password, web3: .default, options: options?.swift).wait().objc
    }
}

@objc public extension NSString {
    var address: W3Address {
        return W3Address(string: self as String)
    }
	var isContractAddress: Bool {
		return (self as String).hex.count > 0
	}
	
	var isAddress: Bool {
		return (self as String).hex.count == 20
	}
	
	var contractAddress: W3Address {
		return W3Address(string: self as String)
	}
}

extension Web3Options {
    public var objc: W3Options {
		return W3Options(self)
	}
}
@objc public class W3Options: NSObject, SwiftContainer {
	weak var object: W3OptionsInheritable?
	var options: Web3Options!
    public var swift: Web3Options {
		get { return object?._swiftOptions ?? options }
		set {
			if let object = object {
				object._swiftOptions = newValue
			} else {
				options = newValue
			}
		}
	}
	@objc public var to: W3Address? {
		get { return swift.to?.objc }
		set { swift.to = newValue?.swift }
	}
	@objc public var from: W3Address? {
		get { return swift.from?.objc }
		set { swift.from = newValue?.swift }
	}
	@objc public var gasLimit: W3UInt? {
		get { return swift.gasLimit?.objc }
		set { swift.gasLimit = newValue?.swift }
	}
	@objc public var gasPrice: W3UInt? {
		get { return swift.gasPrice?.objc }
		set { swift.gasPrice = newValue?.swift }
	}
	@objc public var value: W3UInt? {
		get { return swift.value?.objc }
		set { swift.value = newValue?.swift }
	}
	
	
	init(object: W3OptionsInheritable) {
		self.object = object
	}
	public required init(_ swift: Web3Options) {
		self.options = swift
	}
	@objc public override init() {
		self.options = Web3Options()
	}
	@objc public static var `default`: W3Options {
		return Web3Options.default.objc
	}
	
	@objc public init(_ json: [String: Any]) throws {
		self.options = try Web3Options(json)
	}
	
	/// merges two sets of options along with a gas estimate to try to guess the final gas limit value required by user.
	///
	/// Please refer to the source code for a logic.
	@objc public static func smartMergeGasLimit(originalOptions: W3Options?, extraOptions: W3Options?, gasEstimate: W3UInt) -> W3UInt {
		return Web3Options.smartMergeGasLimit(originalOptions: originalOptions?.swift, extraOptions: extraOptions?.swift, gasEstimate: gasEstimate.swift).objc
	}
	
	@objc public static func smartMergeGasPrice(originalOptions: W3Options?, extraOptions: W3Options?, priceEstimate: W3UInt) -> W3UInt {
		return Web3Options.smartMergeGasPrice(originalOptions: originalOptions?.swift, extraOptions: extraOptions?.swift, priceEstimate: priceEstimate.swift).objc
	}
}

extension NetworkId {
    public var objc: W3NetworkId {
		return W3NetworkId(self.rawValue.objc)
	}
}
@objc public class W3NetworkId: NSObject, SwiftBridgeable {
	public var swift: NetworkId {
		return NetworkId(rawValue: rawValue.swift)
	}
	typealias IntegerLiteralType = Int
	@objc public var rawValue: W3UInt
	@objc public required init(rawValue: W3UInt) {
		self.rawValue = rawValue
	}
	
	@objc public init(_ rawValue: W3UInt) {
		self.rawValue = rawValue
	}
	
	@objc public var all: [W3NetworkId] {
		return [.mainnet, .ropsten, .rinkeby, .kovan]
	}
	
	@objc public static var `default`: W3NetworkId = .mainnet
	@objc public static var mainnet: W3NetworkId { return NetworkId.mainnet.objc }
	@objc public static var ropsten: W3NetworkId { return NetworkId.ropsten.objc }
	@objc public static var rinkeby: W3NetworkId { return NetworkId.rinkeby.objc }
	@objc public static var kovan: W3NetworkId { return NetworkId.kovan.objc }
	@objc public override var description: String {
		return swift.description
	}
}

extension TransactionSendingResult {
    public var objc: W3TransactionSendingResult {
		return W3TransactionSendingResult(transaction: transaction.objc, hash: hash)
	}
}
@objc public class W3TransactionSendingResult: NSObject, SwiftBridgeable {
    public var swift: TransactionSendingResult {
        return TransactionSendingResult(transaction: transaction.swift, hash: transactionHash)
    }
    
	@objc public var transaction: W3EthereumTransaction
	@objc public var transactionHash: String
	@objc public init(transaction: W3EthereumTransaction, hash: String) {
		self.transaction = transaction
		self.transactionHash = hash
	}
}

extension TransactionParameters {
    public var objc: W3TransactionParameters {
		return W3TransactionParameters(self)
	}
}
@objc public class W3TransactionParameters: NSObject, SwiftContainer {
	public var swift: TransactionParameters {
		var parameters = TransactionParameters(from: from, to: to)
		parameters.data = data
		parameters.gas = gas
		parameters.gasPrice = gasPrice
		parameters.value = value
		return parameters
	}
	public required init(_ swift: TransactionParameters) {
		data = swift.data
		from = swift.from
		gas = swift.gas
		gasPrice = swift.gasPrice
		to = swift.to
		value = swift.value
	}
	/// transaction parameters
	@objc public var data: String?
	/// transaction sender
	@objc public var from: String?
	/// gas limit
	@objc public var gas: String?
	/// gas price
	@objc public var gasPrice: String?
	/// transaction recipient
	@objc public var to: String?
	/// ether value
	@objc public var value: String? = "0x0"
	
	/// init with sender and recipient
	@objc public init(from _from: String?, to _to: String?) {
		from = _from
		to = _to
	}
}


extension TransactionDetails {
    public var objc: W3TransactionDetails {
		return W3TransactionDetails(self)
	}
}
@objc public class W3TransactionDetails: NSObject, SwiftContainer {
	public let swift: TransactionDetails
	public required init(_ swift: TransactionDetails) {
		self.swift = swift
	}
	
	@objc public var blockHash: Data? {
		return swift.blockHash
	}
	@objc public var blockNumber: W3UInt? {
		return swift.blockNumber?.objc
	}
	@objc public var transactionIndex: W3UInt? {
		return swift.transactionIndex?.objc
	}
	@objc public var transaction: W3EthereumTransaction {
		return swift.transaction.objc
	}
}

extension TransactionReceipt {
    public var objc: W3TransactionReceipt {
		return W3TransactionReceipt(self)
	}
}
@objc public class W3TransactionReceipt: NSObject, SwiftContainer {
	public let swift: TransactionReceipt
	public required init(_ swift: TransactionReceipt) {
		self.swift = swift
	}
	@objc public var transactionHash: Data {
		return swift.transactionHash
	}
	@objc public var blockHash: Data {
		return swift.blockHash
	}
	@objc public var blockNumber: W3UInt {
		return swift.blockNumber.objc
	}
	@objc public var transactionIndex: W3UInt {
		return swift.transactionIndex.objc
	}
	@objc public var contractAddress: W3Address? {
		return swift.contractAddress?.objc
	}
	@objc public var cumulativeGasUsed: W3UInt {
		return swift.cumulativeGasUsed.objc
	}
	@objc public var gasUsed: W3UInt {
		return swift.gasUsed.objc
	}
	@objc public var logs: [W3EventLog] {
		return swift.logs.map { $0.objc }
	}
	@objc public var status: W3TXStatus {
		return swift.status.objc
	}
	@objc public var logsBloom: W3EthereumBloomFilter? {
		return swift.logsBloom?.objc
	}
	
}
extension TransactionReceipt.TXStatus {
    public var objc: W3TXStatus {
		switch self {
		case .ok: return .ok
		case .failed: return .failed
		case .notYetProcessed: return .notYetProcessed
		}
	}
}
@objc public enum W3TXStatus: Int, SwiftBridgeable {
	case ok
	case failed
	case notYetProcessed
    public var swift: TransactionReceipt.TXStatus {
        switch self {
        case .ok: return .ok
        case .failed: return .failed
        case .notYetProcessed: return .notYetProcessed
        }
    }
}

extension EventLog {
    public var objc: W3EventLog {
		return W3EventLog(self)
	}
}
@objc public class W3EventLog: NSObject, SwiftContainer {
	public let swift: EventLog
	public required init(_ swift: EventLog) {
		self.swift = swift
	}
	@objc public var address: W3Address {
		return swift.address.objc
	}
	@objc public var blockHash: Data {
		return swift.blockHash
	}
	@objc public var blockNumber: W3UInt {
		return swift.blockNumber.objc
	}
	@objc public var data: Data {
		return swift.data
	}
	@objc public var logIndex: W3UInt {
		return swift.logIndex.objc
	}
	@objc public var removed: Bool {
		return swift.removed
	}
	@objc public var topics: [Data] {
		return swift.topics
	}
	@objc public var transactionHash: Data {
		return swift.transactionHash
	}
	@objc public var transactionIndex: W3UInt {
		return swift.transactionIndex.objc
	}
	
}


extension TransactionInBlock {
    public var objc: W3TransactionInBlock {
		return W3TransactionInBlock(self)
	}
}
@objc public class W3TransactionInBlock: NSObject, SwiftContainer {
    public var swift: TransactionInBlock {
        if let hash = transactionHash {
            return .hash(hash)
        } else if let transaction = transaction {
            return .transaction(transaction.swift)
        } else {
            return .null
        }
    }
	public required init(_ swift: TransactionInBlock) {
		switch swift {
		case let .hash(data):
			transactionHash = data
		case let .transaction(transaction):
			self.transaction = transaction.objc
		case .null: break
		}
	}
	
	var transactionHash: Data?
	var transaction: W3EthereumTransaction?
}


extension Block {
    public var objc: W3Block {
		return W3Block(self)
	}
}
@objc public class W3Block: NSObject, SwiftContainer {
	public let swift: Block
	public required init(_ swift: Block) {
		self.swift = swift
	}
	
	@objc public var number: W3UInt {
		return swift.number.objc
	}
	@objc public var blockHash: Data {
		return swift.hash
	}
	@objc public var parentHash: Data {
		return swift.parentHash
	}
	@objc public var nonce: Data? {
		return swift.nonce
	}
	@objc public var sha3Uncles: Data {
		return swift.sha3Uncles
	}
	@objc public var logsBloom: W3EthereumBloomFilter? {
		return swift.logsBloom?.objc
	}
	@objc public var transactionsRoot: Data {
		return swift.transactionsRoot
	}
	@objc public var stateRoot: Data {
		return swift.stateRoot
	}
	@objc public var receiptsRoot: Data {
		return swift.receiptsRoot
	}
	@objc public var miner: W3Address? {
		return swift.miner?.objc
	}
	@objc public var difficulty: W3UInt {
		return swift.difficulty.objc
	}
	@objc public var totalDifficulty: W3UInt {
		return swift.totalDifficulty.objc
	}
	@objc public var extraData: Data {
		return swift.extraData
	}
	@objc public var size: W3UInt {
		return swift.size.objc
	}
	@objc public var gasLimit: W3UInt {
		return swift.gasLimit.objc
	}
	@objc public var gasUsed: W3UInt {
		return swift.gasUsed.objc
	}
	@objc public var timestamp: Date {
		return swift.timestamp
	}
	@objc public var transactions: [W3TransactionInBlock] {
		return swift.transactions.map { $0.objc }
	}
	@objc public var uncles: [Data] {
		return swift.uncles
	}
}


extension EventParserResult {
    public var objc: W3EventParserResult {
		return W3EventParserResult(self)
	}
}
@objc public class W3EventParserResult: NSObject, SwiftContainer {
	public let swift: EventParserResult
	public required init(_ swift: EventParserResult) {
		self.swift = swift
	}
	
	@objc public var eventName: String {
		return swift.eventName
	}
	@objc public var transactionReceipt: W3TransactionReceipt? {
		return swift.transactionReceipt?.objc
	}
	@objc public var contractAddress: W3Address {
		return swift.contractAddress.objc
	}
	@objc public var decodedResult: [String: Any] {
		return swift.decodedResult
	}
	@objc public var eventLog: W3EventLog? {
		return swift.eventLog?.objc
	}
}

extension EthereumBloomFilter {
    public var objc: W3EthereumBloomFilter {
		return W3EthereumBloomFilter(self)
	}
}

@objc public class W3EthereumBloomFilter: NSObject, SwiftContainer {
	public let swift: EthereumBloomFilter
	public required init(_ swift: EthereumBloomFilter) {
		self.swift = swift
	}
	
	@objc public var bytes: Data {
		return swift.bytes
	}
	@objc public func asBigUInt() -> W3UInt {
		return swift.asBigUInt().objc
	}
}
