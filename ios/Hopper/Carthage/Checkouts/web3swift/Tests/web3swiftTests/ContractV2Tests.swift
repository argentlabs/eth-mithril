//
//  web3swift_contractV2_Tests.swift
//  web3swift-iOS_Tests
//
//  Created by Антон Григорьев on 02.07.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
//import CryptoSwift
import XCTest

@testable import web3swift

class ContractV2Tests: XCTestCase {
    func testDecodeInputData() throws {
        let contract = try ContractV2(Web3Utils.erc20ABI)
        let dataToDecode = Data.fromHex("0xa9059cbb000000000000000000000000cdd45864e794fe5e3e1b0045b77e62f4c43b8bd9000000000000000000000000000000000000000000000224b5f018c3e30142d5")!
        let decoded = contract.decodeInputData("transfer", data: dataToDecode)
        XCTAssert(decoded!["_to"] as? Address == "0xcdd45864e794fe5e3e1b0045b77e62f4c43b8bd9")
    }

    func testDecodeInputDataWithoutMethodName() throws {
        let contract = try ContractV2(Web3Utils.erc20ABI)
        let dataToDecode = Data.fromHex("0xa9059cbb000000000000000000000000cdd45864e794fe5e3e1b0045b77e62f4c43b8bd9000000000000000000000000000000000000000000000224b5f018c3e30142d5")!
        let decoded = contract.decodeInputData(dataToDecode)
        XCTAssert(decoded!["_to"] as? Address == "0xcdd45864e794fe5e3e1b0045b77e62f4c43b8bd9")
    }
}
