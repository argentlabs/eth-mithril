//
//  ERC888.swift
//  web3swift
//
//  Created by Dmitry on 12/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit


/**
 ERC888 token
 
string public name;
string public symbol;

mapping (uint256 => string) internal tokenNames;
mapping (uint256 => string) internal tokenSymbols;
mapping (uint256 => uint8) internal tokenDecimals;
mapping (uint256 => mapping (address => uint)) internal balances;

event Transfer(uint256 indexed _id, address indexed _from, address indexed _to, uint256 _value);

function name(uint256 _id) public view returns (string) {
    return tokenNames[_id];
}

function symbol(uint256 _id) public view returns (string) {
    return abi.encode(symbol, "-", tokenSymbols[_id]);
}

function decimals(uint256 _id) public view returns (uint8) {
    return tokenDecimals[_id];
}

function balanceOf(uint256 _id, address _owner) public view returns (uint256 balance) {
    return balances[_id][_owner];
}

function transfer(uint256 _id, address _to, uint256 _value) public returns (bool success) {
    require(balances[msg.sender][_id] >= _value);
    require(balances[_to][_id] + _value >= _value);
    
    balances[msg.sender][_id] -= _value;
    balances[_to][_id] += _value;
    Transfer(_id, msg.sender, _to, _value);
    return true;
}
 */

public class ERC888 {
    /// Token address
    public let address: Address
    /// Transaction Options
    public var options: Web3Options = .default
    /// Password to unlock private key for sender address
    public var password: String = "BANKEXFOUNDATION"
    
    /// Represents Address as ERC888 token (with standard password and options)
    /// - Parameter address: Token address
    public init(_ address: Address) {
        self.address = address
    }
    
    /// Represents Address as ERC888 token
    /// - Parameter address: Token address
    /// - Parameter from: Sender address
    /// - Parameter address: Password to decrypt sender's private key
    public init(_ address: Address, from: Address, password: String) {
        self.address = address
        options.from = from
        self.password = password
    }
    
    /// Returns token with given id
    public func token(id: BigUInt) -> Token {
        return Token(parent: self, id: id)
    }
    
    /// Represents one token
    public class Token {
        /// Token id
        public let id: BigUInt
        /// Token parent
        public let parent: ERC888
        fileprivate var address: Address { return parent.address }
        fileprivate var options: Web3Options { return parent.options }
        fileprivate var password: String { return parent.password }
        /**
         * Gas price functions if you want to see that
         * Automatically calls if options.gasPrice == nil */
        public var gasPrice: GasPrice { return GasPrice(self) }
        
        init(parent: ERC888, id: BigUInt) {
            self.parent = parent
            self.id = id
        }
        
        /// - Returns: token name/description
        public func name() throws -> String {
            return try address.call("name(uint256)", id, options: options).wait().string()
        }
        /// - Returns: token symbol
        public func symbol() throws -> String {
            return try address.call("symbol(uint256)", id, options: options).wait().string()
        }
        /// - Returns: token decimals
        public func decimals() throws -> BigUInt {
            return try address.call("decimals(uint256)", id, options: options).wait().uint256()
        }
        /// - Returns: user balance in wei
        public func balance(of user: Address) throws -> BigUInt {
            return try address.call("balanceOf(uint256,address)", id, user, options: options).wait().uint256()
        }
        /// - Returns: user balance in human-readable format (automatically calculates with decimals)
        public func naturalBalance(of user: Address) throws -> String {
            let balance = try address.call("balanceOf(uint256,address)", id, user, options: options).wait().uint256()
            let decimals = try self.decimals()
            return balance.string(unitDecimals: Int(decimals))
        }
        
        /**
         transfers to user \(amount)
         - Important: Transaction | Requires password | Contract owner only.
         - Returns: TransactionSendingResult
         - Parameter user: Recipient address
         - Parameter amount: Amount in wei to send. If you want to send 1 token (not 0.00000000001) use NaturalUnits(amount) instead
         */
        public func transfer(to user: Address, amount: BigUInt) throws -> TransactionSendingResult {
            return try address.send("transfer(uint256,address,uint256)", id, user, amount, password: password, options: options).wait()
        }
        
        /**
         transfers to user \(amount)
         NaturalUnits is user readable representaion of tokens (like "0.01" / "1.543634")
         - Important: Transaction | Requires password | Contract owner only.
         - Returns: TransactionSendingResult
         */
        public func transfer(to user: Address, amount: NaturalUnits) throws -> TransactionSendingResult {
            let decimals = try Int(self.decimals())
            let amount = amount.number(with: decimals)
            return try transfer(to: user, amount: amount)
        }
    }
    
    /**
     Gas price functions for erc888 token requests
     */
    public struct GasPrice {
        let parent: Token
        var address: Address { return parent.address }
        var options: Web3Options { return parent.options }
        init(_ parent: Token) {
            self.parent = parent
        }
        
        /// - Returns: gas price for transfer(address,uint256) transaction
        public func transfer(to user: Address, amount: BigUInt) throws -> BigUInt {
            return try address.estimateGas("transfer(uint256,address,uint256)", parent.id, user, amount, options: options).wait()
        }
        
        /// - Returns: gas price for transfer(address,uint256) transaction
        public func transfer(to user: Address, amount: NaturalUnits) throws -> BigUInt {
            let decimals = try Int(parent.decimals())
            let amount = amount.number(with: decimals)
            return try transfer(to: user, amount: amount)
        }
    }
}

