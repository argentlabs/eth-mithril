//
//  TxPoolTests.swift
//  web3swift-iOS_Tests
//
//  Created by Dmitry on 28/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import XCTest
@testable import web3swift
import BigInt

class TxPoolTests: XCTestCase {
    var localNodeFound = false
    override func setUp() {
        let url = URL(string: "http://127.0.0.1:8545")!
        if let provider = Web3HttpProvider(url, network: nil) {
            localNodeFound = true
            Web3.default = Web3(provider: provider)
        } else {
            localNodeFound = false
        }
    }
    func testTxPoolStatus() throws {
        
        guard localNodeFound else { return }
        try XCTAssertNoThrow(TxPool.default.status().wait())
    }
    
    func testTxPoolInspect() throws {
        guard localNodeFound else { return }
        try XCTAssertNoThrow(TxPool.default.inspect().wait())
        
    }
    func testTxPoolContent() throws {
        guard localNodeFound else { return }
        try XCTAssertNoThrow(TxPool.default.content().wait())
    }
}
