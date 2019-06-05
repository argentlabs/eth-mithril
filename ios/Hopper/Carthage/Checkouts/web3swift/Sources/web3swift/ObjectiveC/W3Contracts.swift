//
//  W3Contracts.swift
//  web3swift
//
//  Created by Dmitry on 11/8/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

protocol W3OptionsInheritable: class {
    var _swiftOptions: Web3Options { get set }
}

/// Options for sending or calling a particular Ethereum transaction

// MARK:- ERC20
@objc public class W3ERC20: NSObject, SwiftBridgeable {
	public var swift: ERC20 {
		let contract = ERC20(address.swift)
		contract.options = options.swift
		contract.password = password
		return contract
	}
	@objc public let address: W3Address
	@objc public var options: W3Options = .default
	@objc public var password: String = "BANKEXFOUNDATION"
	@objc public var gasPrice: W3ERC20GasPrice { return W3ERC20GasPrice(self) }
	
	@objc public init(address: W3Address) {
		self.address = address
	}
	@objc public init(address: W3Address, from: W3Address, password: String) {
		self.address = address
		self.options.from = from
		self.password = password
	}
	@objc public func name() throws -> String {
		return try swift.name()
	}
	@objc public func symbol() throws -> String {
		return try swift.symbol()
	}
	@objc public func totalSupply() throws -> W3UInt {
		return try swift.totalSupply().objc
	}
	@objc public func decimals() throws -> W3UInt {
		return try swift.decimals().objc
	}
	@objc public func balance(of user: W3Address) throws -> W3UInt {
		return try swift.balance(of: user.swift).objc
	}
	@objc public func naturalBalance(of user: W3Address) throws -> String {
		return try swift.naturalBalance(of: user.swift)
	}
	
	@objc public func allowance(from owner: W3Address, to spender: W3Address) throws -> W3UInt {
		return try swift.allowance(from: owner.swift, to: spender.swift).objc
	}
	
	@objc public func transfer(to user: W3Address, amount: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.transfer(to: user.swift, amount: amount.swift).objc
	}
	
	@objc public func approve(to user: W3Address, amount: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.approve(to: user.swift, amount: amount.swift).objc
	}
	
	
	@objc public func transferFrom(owner: W3Address, to: W3Address, amount: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.transferFrom(owner: owner.swift, to: to.swift, amount: amount.swift).objc
	}
	
	@objc public func transfer(to user: W3Address, naturalUnits: W3NaturalUnits) throws -> W3TransactionSendingResult {
		return try swift.transfer(to: user.swift, amount: naturalUnits.swift).objc
	}
	
	@objc public func approve(to user: W3Address, naturalUnits: W3NaturalUnits) throws -> W3TransactionSendingResult {
		return try swift.approve(to: user.swift, amount: naturalUnits.swift).objc
	}
	
	@objc public func transferFrom(owner: W3Address, to: W3Address, naturalUnits: W3NaturalUnits) throws -> W3TransactionSendingResult {
		return try swift.transferFrom(owner: owner.swift, to: to.swift, amount: naturalUnits.swift).objc
	}
}

@objc public class W3ERC20GasPrice: NSObject {
	let contract: W3ERC20
	init(_ contract: W3ERC20) {
		self.contract = contract
	}
	
	@objc public func transfer(to user: W3Address, amount: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.transfer(to: user.swift, amount: amount.swift).objc
	}
	@objc public func approve(to user: W3Address, amount: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.approve(to: user.swift, amount: amount.swift).objc
	}
	@objc public func transferFrom(owner: W3Address, to: W3Address, amount: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.transferFrom(owner: owner.swift, to: to.swift, amount: amount.swift).objc
	}
	@objc public func transfer(to user: W3Address, naturalUnits: W3NaturalUnits) throws -> W3UInt {
		return try contract.swift.gasPrice.transfer(to: user.swift, amount: naturalUnits.swift).objc
	}
	
	@objc public func approve(to user: W3Address, naturalUnits: W3NaturalUnits) throws -> W3UInt {
		return try contract.swift.gasPrice.approve(to: user.swift, amount: naturalUnits.swift).objc
	}
	
	/// contract owner only
	/// transfers from owner to recipient
	@objc public func transferFrom(owner: W3Address, to: W3Address, naturalUnits: W3NaturalUnits) throws -> W3UInt {
		return try contract.swift.gasPrice.transferFrom(owner: owner.swift, to: to.swift, amount: naturalUnits.swift).objc
	}
}


// MARK:- ERC721
@objc public class W3ERC721: NSObject {
	public var swift: ERC721 {
		let contract = ERC721(address.swift)
		contract.options = options.swift
		contract.password = password
		return contract
	}
	@objc public let address: W3Address
	@objc public var options: W3Options = .default
	@objc public var password: String = "BANKEXFOUNDATION"
	@objc public var gasPrice: W3ERC721GasPrice { return W3ERC721GasPrice(self) }
	
	@objc public init(address: W3Address) {
		self.address = address
	}
	@objc public init(address: W3Address, from: W3Address, password: String) {
		self.address = address
		self.options.from = from
		self.password = password
	}
	
	@objc public func balance(of user: W3Address) throws -> W3UInt {
		return try swift.balance(of: user.swift).objc
	}
	/// - Returns: address of token holder
	@objc public func owner(of token: W3UInt) throws -> W3Address {
		return try swift.owner(of: token.swift).objc
	}
	
	/// Sending approve that another user can take your token
	@objc public func approve(to user: W3Address, token: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.approve(to: user.swift, token: token.swift).objc
	}
	
	/// - Returns: address
	@objc public func approved(for token: W3UInt) throws -> W3Address {
		return try swift.approved(for: token.swift).objc
	}
	/// sets operator for all your tokens
	@objc public func setApproveForAll(operator: W3Address, approved: Bool) throws -> W3TransactionSendingResult {
		return try swift.setApproveForAll(operator: `operator`.swift, approved: approved).objc
	}
	/// checks if user is approved to manager your tokens
	/// returns bool
	@objc public func isApprovedForAll(owner: W3Address, operator: W3Address) throws -> NSNumber {
		return try swift.isApprovedForAll(owner: owner.swift, operator: `operator`.swift) as NSNumber
	}
	/// transfers token from one address to another
	/// - Important: admin only
	@objc public func transfer(from: W3Address, to: W3Address, token: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.transfer(from: from.swift, to: to.swift, token: token.swift).objc
	}
	
	@objc public func safeTransfer(from: W3Address, to: W3Address, token: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.safeTransfer(from: from.swift, to: to.swift, token: token.swift).objc
	}
}
	
/**
Gas price functions for erc721 token requests
*/
@objc public class W3ERC721GasPrice: NSObject {
	let contract: W3ERC721
	init(_ contract: W3ERC721) {
		self.contract = contract
	}
	
	/// - Returns: gas price for approve(address,uint256) transaction
	@objc public func approve(to user: W3Address, token: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.approve(to: user.swift, token: token.swift).objc
	}
	/// - Returns: gas price for setApprovalForAll(address,bool) transaction
	@objc public func setApproveForAll(operator: W3Address, approved: Bool) throws -> W3UInt {
		return try contract.swift.gasPrice.setApproveForAll(operator: `operator`.swift, approved: approved).objc
	}
	/// - Returns: gas price for transferFrom(address,address,uint256) transaction
	@objc public func transfer(from: W3Address, to: W3Address, token: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.transfer(from: from.swift, to: to.swift, token: token.swift).objc
	}
	/// - Returns: gas price for safeTransferFrom(address,address,uint256) transaction
	@objc public func safeTransfer(from: W3Address, to: W3Address, token: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.safeTransfer(from: from.swift, to: to.swift, token: token.swift).objc
	}
}


// MARK:- ERC777

@objc public class W3ERC777: NSObject {
	public var swift: ERC777 {
		let contract = ERC777(address.swift)
		contract.options = options.swift
		contract.password = password
		return contract
	}
	@objc public let address: W3Address
	@objc public var options: W3Options = .default
	@objc public var password: String = "BANKEXFOUNDATION"
	@objc public var gasPrice: W3ERC777GasPrice { return W3ERC777GasPrice(self) }
	
	@objc public init(address: W3Address) {
		self.address = address
	}
	@objc public init(address: W3Address, from: W3Address, password: String) {
		self.address = address
		self.options.from = from
		self.password = password
	}
	
	@objc public func name() throws -> String {
		return try swift.name()
	}
	@objc public func symbol() throws -> String {
		return try swift.symbol()
	}
	@objc public func totalSupply() throws -> W3UInt {
		return try swift.totalSupply().objc
	}
	@objc public func decimals() throws -> W3UInt {
		return try swift.decimals().objc
	}
	@objc public func balance(of user: W3Address) throws -> W3UInt {
		return try swift.balance(of: user.swift).objc
	}
	
	@objc public func allowance(from owner: W3Address, to spender: W3Address) throws -> W3UInt {
		return try swift.allowance(from: owner.swift, to: spender.swift).objc
	}
	@objc public func transfer(to user: W3Address, amount: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.transfer(to: user.swift, amount: amount.swift).objc
	}
	@objc public func approve(to user: W3Address, amount: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.approve(to: user.swift, amount: amount.swift).objc
	}
	@objc public func transfer(from: W3Address, to: W3Address, amount: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.transfer(from: from.swift, to: to.swift, amount: amount.swift).objc
	}
	
	@objc public func send(to user: W3Address, amount: W3UInt) throws -> W3TransactionSendingResult {
		return try swift.send(to: user.swift, amount: amount.swift).objc
	}
	@objc public func send(to user: W3Address, amount: W3UInt, userData: Data) throws -> W3TransactionSendingResult {
		return try swift.send(to: user.swift, amount: amount.swift, userData: userData).objc
	}
	
	@objc public func authorize(operator user: W3Address) throws -> W3TransactionSendingResult {
		return try swift.authorize(operator: user.swift).objc
	}
	@objc public func revoke(operator user: W3Address) throws -> W3TransactionSendingResult {
		return try swift.revoke(operator: user.swift).objc
	}
	
	@objc public func isOperatorFor(operator user: W3Address, tokenHolder: W3Address) throws -> NSNumber {
		return try swift.isOperatorFor(operator: user.swift, tokenHolder: tokenHolder.swift) as NSNumber
	}
	@objc public func operatorSend(from: W3Address, to: W3Address, amount: W3UInt, userData: Data) throws -> W3TransactionSendingResult {
		return try swift.operatorSend(from: from.swift, to: to.swift, amount: amount.swift, userData: userData).objc
	}
}

@objc public class W3ERC777GasPrice: NSObject {
	let contract: W3ERC777
	init(_ contract: W3ERC777) {
		self.contract = contract
	}
	
	/// - Returns: gas price for transfer(address,uint256) transaction
	@objc public func transfer(to user: W3Address, amount: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.transfer(to: user.swift, amount: amount.swift).objc
	}
	/// - Returns: gas price for approve(address,uint256) transaction
	@objc public func approve(to user: W3Address, amount: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.approve(to: user.swift, amount: amount.swift).objc
	}
	/// - Returns: gas price for transferFrom(address,address,uint256) transaction
	@objc public func transfer(from: W3Address, to: W3Address, amount: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.transfer(from: from.swift, to: to.swift, amount: amount.swift).objc
	}
	
	/// - Returns: gas price for send(address,uint256) transaction
	@objc public func send(to user: W3Address, amount: W3UInt) throws -> W3UInt {
		return try contract.swift.gasPrice.send(to: user.swift, amount: amount.swift).objc
	}
	/// - Returns: gas price for send(address,uint256,bytes) transaction
	@objc public func send(to user: W3Address, amount: W3UInt, userData: Data) throws -> W3UInt {
		return try contract.swift.gasPrice.send(to: user.swift, amount: amount.swift, userData: userData).objc
	}
	
	/// - Returns: gas price for authorizeOperator(address) transaction
	@objc public func authorize(operator user: W3Address) throws -> W3UInt {
		return try contract.swift.gasPrice.authorize(operator: user.swift).objc
	}
	/// - Returns: gas price for revokeOperator(address) transaction
	@objc public func revoke(operator user: W3Address) throws -> W3UInt {
		return try contract.swift.gasPrice.revoke(operator: user.swift).objc
	}
	
	/// - Returns: gas price for operatorSend(address,address,uint256,bytes) transaction
	@objc public func operatorSend(from: W3Address, to: W3Address, amount: W3UInt, userData: Data) throws -> W3UInt {
		return try contract.swift.gasPrice.operatorSend(from: from.swift, to: to.swift, amount: amount.swift, userData: userData).objc
	}
}
