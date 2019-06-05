//
//  web3swiftInfuraTests.swift
//  web3swift-iOS_Tests
//
//  Created by Георгий Фесенко on 02/07/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import XCTest

@testable import web3swift
class InfuraTests: XCTestCase {
    func testGetBalance() throws {
        let web3 = Web3(infura: .mainnet)
        let address = Address("0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
        let balance = try web3.eth.getBalance(address: address)
        let balString = balance.string(units: .eth, decimals: 3)
        print(balString)
    }
 
    func testGetBlockByHash() throws {
        let web3 = Web3(infura: .mainnet)
        let result = try web3.eth.getBlockByHash("0x6d05ba24da6b7a1af22dc6cc2a1fe42f58b2a5ea4c406b19c8cf672ed8ec0695", fullTransactions: true)
        print(result)
    }

    func testGetBlockByNumber1() throws {
        let web3 = Web3(infura: .mainnet)
        let result = try web3.eth.getBlockByNumber("latest", fullTransactions: true)
        print(result)
    }

    func testGetBlockByNumber2() throws {
        let web3 = Web3(infura: .mainnet)
        let result = try web3.eth.getBlockByNumber(UInt64(5_184_323), fullTransactions: true)
        print(result)
        let transactions = result.transactions
        for transaction in transactions {
            switch transaction {
            case let .transaction(tx):
                print(String(describing: tx))
            default:
                break
            }
        }
    }

    func testGetBlockByNumber3() {
        let web3 = Web3(infura: .mainnet)
        XCTAssertNoThrow(try web3.eth.getBlockByNumber(UInt64(0x5BAD55), fullTransactions: true))
    }

    func testGasPrice() throws {
        let web3 = Web3(infura: .mainnet)
        let gasPrice = try web3.eth.getGasPrice()
        print(gasPrice)
    }
}
