//
//  web3swift_numberFormattingUtil_Tests.swift
//  web3swift-iOS_Tests
//
//  Created by Антон Григорьев on 02.07.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
//import CryptoSwift
import XCTest

@testable import web3swift

class NumberFormattingUtilTests: XCTestCase {
    func testNumberFormattingUtil() {
        let balance = BigInt("-1000000000000000000")!
        let formatted = balance.string(unitDecimals: 18, decimals: 4, decimalSeparator: ",")
        XCTAssertEqual(formatted, "-1")
    }

    func testNumberFormattingUtil2() {
        let balance = BigInt("-1000000000000000")!
        let formatted = balance.string(unitDecimals: 18, decimals: 4, decimalSeparator: ",")
        XCTAssertEqual(formatted, "-0,001")
    }

    func testNumberFormattingUtil3() {
        let balance = BigInt("-1000000000000")!
        let formatted = balance.string(unitDecimals: 18, decimals: 4, decimalSeparator: ",")
        XCTAssertEqual(formatted, "-0")
    }

    func testNumberFormattingUtil4() {
        let balance = BigInt("-1000000000000")!
        let formatted = balance.string(unitDecimals: 18, decimals: 9, decimalSeparator: ",")
        XCTAssertEqual(formatted, "-0,000001")
    }

    func testNumberFormattingUtil5() {
        let balance = BigInt("-1")!
        let formatted = balance.string(unitDecimals: 18, decimals: 9, decimalSeparator: ",", options: [.stripZeroes,.fallbackToScientific])
        XCTAssertEqual(formatted, "-1e-18")
    }

    func testNumberFormattingUtil6() {
        let balance = BigInt("0")!
        let formatted = balance.string(unitDecimals: 18, decimals: 9, decimalSeparator: ",")
        XCTAssertEqual(formatted, "0")
    }

    func testNumberFormattingUtil7() {
        let balance = BigInt("-1100000000000000000")!
        let formatted = balance.string(unitDecimals: 18, decimals: 4, decimalSeparator: ",")
        XCTAssertEqual(formatted, "-1,1")
    }
    
    func testNumberFormattingUtil8() {
        let balance = BigInt("100")!
        let formatted = balance.string(unitDecimals: 18, decimals: 4, decimalSeparator: ",", options: [.stripZeroes,.fallbackToScientific])
        XCTAssertEqual(formatted, "1,00e-16")
    }
    
    func testNumberFormattingUtil9() {
        let balance = BigInt("1000000")!
        let formatted = balance.string(unitDecimals: 18, decimals: 4, decimalSeparator: ",", options: [.stripZeroes,.fallbackToScientific])
        XCTAssertEqual(formatted, "1,0000e-12")
    }
}
