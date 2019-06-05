//
//  web3swift_EIP67_Tests.swift
//  web3swift-iOS_Tests
//
//  Created by Anton Grigoriev on 02.07.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

#if canImport(CIImage)
import BigInt
//import CryptoSwift
import XCTest

@testable import web3swift

class EIP67Tests: XCTestCase {
    let address: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
    func testEIP67encoding() {
        var eip67Data = EIP67Code(address: address)
        eip67Data.gasLimit = BigUInt(21000)
        eip67Data.amount = BigUInt("1000000000000000000")
        //        eip67Data.data =
        let encoding = eip67Data.toString()
        print(encoding)
    }

    func testEIP67codeGeneration() {
        var eip67Data = EIP67Code(address: address)
        eip67Data.gasLimit = BigUInt(21000)
        eip67Data.amount = BigUInt("1000000000000000000")
        //        eip67Data.data =
        let encoding = eip67Data.toImage(scale: 5.0)
        XCTAssert(encoding != CIImage())
    }

    func testEIP67decoding() {
        var eip67Data = EIP67Code(address: address)
        eip67Data.gasLimit = BigUInt(21000)
        eip67Data.amount = BigUInt("1000000000000000000")
        //        eip67Data.data =
        let encoding = eip67Data.toString()
        guard let code = EIP67Code(string: encoding) else { return XCTFail() }
        XCTAssert(code.address == eip67Data.address)
        XCTAssert(code.gasLimit == eip67Data.gasLimit)
        XCTAssert(code.amount == eip67Data.amount)
    }
}
#endif
