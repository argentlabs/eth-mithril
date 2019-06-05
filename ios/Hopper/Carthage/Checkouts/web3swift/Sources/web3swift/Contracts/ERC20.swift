//
//  ERC20.swift
//  web3swift-iOS
//
//  Created by Dmitry on 12/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit

/**
 Native implementation of ERC20 token
 - Important: NOT main thread friendly
 */
public class ERC20 {
    /// Token address
    public let address: Address
    /// Transaction Options
    public var options: Web3Options = .default
    /// Password to unlock private key for sender address
    public var password: String = "BANKEXFOUNDATION"
    /**
    * Gas price functions if you want to see that
    * Automatically calls if options.gasPrice == nil */
    public var gasPrice: GasPrice { return GasPrice(self) }
    
    /// Represents Address as ERC20 token (with standard password and options)
    /// - Parameter address: Token address
    public init(_ address: Address) {
        self.address = address
    }
    
    /// Represents Address as ERC20 token
    /// - Parameter address: Token address
    /// - Parameter from: Sender address
    /// - Parameter address: Password to decrypt sender's private key
    public init(_ address: Address, from: Address, password: String) {
        self.address = address
        options.from = from
        self.password = password
    }
    /// - Returns: Token name/description
    public func name() throws -> String {
        return try address.call("name()", options: options).wait().string()
    }
    /// - Returns: Token symbol
    public func symbol() throws -> String {
        return try address.call("symbol()", options: options).wait().string()
    }
    /// - Returns: Total token supply
    public func totalSupply() throws -> BigUInt {
        return try address.call("totalSupply()", options: options).wait().uint256()
    }
    /// - Returns: Token decimals
    public func decimals() throws -> BigUInt {
        return try address.call("decimals()", options: options).wait().uint256()
    }
    /// - Returns: User balance in wei
    public func balance(of user: Address) throws -> BigUInt {
        return try address.call("balanceOf(address)", user, options: options).wait().uint256()
    }
    /// - Returns: user balance in human-readable format (automatically calculates with decimals)
    public func naturalBalance(of user: Address) throws -> String {
        let balance = try address.call("balanceOf(address)", user, options: options).wait().uint256()
        let decimals = try self.decimals()
        return balance.string(unitDecimals: Int(decimals))
    }
    /**
     Shows how much balance you approved spender to get from your account.
     
     - Returns: Balance that one user can take from another user
     - Parameter owner: Balance holder
     - Parameter spender: Spender address
    */
    public func allowance(from owner: Address, to spender: Address) throws -> BigUInt {
        return try address.call("allowance(address,address)", owner, spender, options: options).wait().uint256()
    }
    
    /**
     Transfers to user \(amount)
     - Important: Transaction | Requires password
     - Returns: TransactionSendingResult
     - Parameter user: Recipient address
     - Parameter amount: Amount in wei to send. If you want to send 1 token (not 0.00000000001) use NaturalUnits(amount) instead
     */
    public func transfer(to user: Address, amount: BigUInt) throws -> TransactionSendingResult {
        return try address.send("transfer(address,uint256)", user, amount, password: password, options: options).wait()
    }
    /**
     Approves user to take \(amount) tokens from your account.
     
     - Important: Transaction | Requires password
     - Returns: TransactionSendingResult
     - Parameter user: Recipient address
     - Parameter amount: Amount in wei to send. If you want to send 1 token (not 0.00000000001) use NaturalUnits(amount) instead
     */
    public func approve(to user: Address, amount: BigUInt) throws -> TransactionSendingResult {
        
        return try address.send("approve(address,uint256)", user, amount, password: password, options: options).wait()
    }
    
    /**
     Transfers from user1 to user2.
     
     - Important: Transaction | Requires password | Contract owner only.
     ERC20(address, from: me).transfer(to: user, amount: NaturalUnits(0.1)) is not the same as
     ERC20(address).transferFrom(owner: me, to: user, amount: NaturalUnits(0.1))
     - Returns: TransactionSendingResult
     - Parameter user: Recipient address
     - Parameter amount: Amount in wei to send. If you want to send 1 token (not 0.00000000001) use NaturalUnits(amount) instead
     */
    public func transferFrom(owner: Address, to: Address, amount: BigUInt) throws -> TransactionSendingResult {
        return try address.send("transferFrom(address,address,uint256)", owner, to, amount, password: password, options: options).wait()
    }
    
    /**
     Transfers to user \(amount)
     NaturalUnits is user readable representaion of tokens (like "0.01" / "1.543634")
     - Important: Transaction | Requires password | Contract owner only.
     - Returns: TransactionSendingResult
     */
    public func transfer(to user: Address, amount: NaturalUnits) throws -> TransactionSendingResult {
        let decimals = try Int(self.decimals())
        let amount = amount.number(with: decimals)
        return try transfer(to: user, amount: amount)
    }
    /**
     approves user to take \(amount) tokens from your account
     NaturalUnits is user readable representaion of tokens (like "0.01" / "1.543634")
     - Important: Transaction | Requires password
     - Returns: TransactionSendingResult
     */
    public func approve(to user: Address, amount: NaturalUnits) throws -> TransactionSendingResult {
        let decimals = try Int(self.decimals())
        let amount = amount.number(with: decimals)
        return try transfer(to: user, amount: amount)
    }
    
    /**
     Transfers from user1 to user2
     NaturalUnits is user readable representaion of tokens (like "0.01" / "1.543634")
     - Important: Transaction | Requires password | Contract owner only.
     ```
     ERC20(address, from: me).transfer(to: user, amount: NaturalUnits(0.1))
     ```
     is not the same as
     ```
     ERC20(address).transferFrom(owner: me, to: user, amount: NaturalUnits(0.1))
     ```
     - Returns: TransactionSendingResult
     */
    public func transferFrom(owner: Address, to: Address, amount: NaturalUnits) throws -> TransactionSendingResult {
        let decimals = try Int(self.decimals())
        let amount = amount.number(with: decimals)
        return try transferFrom(owner: owner, to: to, amount: amount)
    }
    
    /**
     Gas price functions for erc20 token requests
     */
    public struct GasPrice {
        let erc20: ERC20
        var address: Address { return erc20.address }
        var options: Web3Options { return erc20.options }
        init(_ erc20: ERC20) {
            self.erc20 = erc20
        }
        
        /// - Returns: Gas price for transfer(address,uint256) transaction
        public func transfer(to user: Address, amount: BigUInt) throws -> BigUInt {
            return try address.estimateGas("transfer(address,uint256)", user, amount, options: options).wait()
        }
        /// - Returns: Gas price for approve(address,uint256) transaction
        public func approve(to user: Address, amount: BigUInt) throws -> BigUInt {
            return try address.estimateGas("approve(address,uint256)", user, amount, options: options).wait()
        }
        /// - Returns: Gas price for transferFrom(address,address,uint256) function
        public func transferFrom(owner: Address, to: Address, amount: BigUInt) throws -> BigUInt {
            return try address.estimateGas("transferFrom(address,address,uint256)", owner, to, amount, options: options).wait()
        }
        
        /// - Returns: Gas price for transfer(address,uint256) transaction
        public func transfer(to user: Address, amount: NaturalUnits) throws -> BigUInt {
            let decimals = try Int(erc20.decimals())
            let amount = amount.number(with: decimals)
            return try transfer(to: user, amount: amount)
        }
        
        /// - Returns: Gas price for approve(address,uint256) transaction
        public func approve(to user: Address, amount: NaturalUnits) throws -> BigUInt {
            let decimals = try Int(erc20.decimals())
            let amount = amount.number(with: decimals)
            return try transfer(to: user, amount: amount)
        }
        
        /// - Returns: Gas price for transferFrom(address,address,uint256) function
        public func transferFrom(owner: Address, to: Address, amount: NaturalUnits) throws -> BigUInt {
            let decimals = try Int(erc20.decimals())
            let amount = amount.number(with: decimals)
            return try transferFrom(owner: owner, to: to, amount: amount)
        }
    }
}

