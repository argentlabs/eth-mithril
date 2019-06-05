//
//  scrypt_Tests.swift
//  web3swift-iOS_Tests
//
//  Created by Alexander Vlasov on 10.08.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import XCTest

@testable import web3swift

class ScryptTests: XCTestCase {
    func testScrypt() {
        let password = "password"
        let salt = "NaCl".data
        let derived = scrypt(password: password, salt: salt, length: 64, N: 1024, R: 8, P: 16)!
        let expected = """
                fd ba be 1c 9d 34 72 00 78 56 e7 19 0d 01 e9 fe
                   7c 6a d7 cb c8 23 78 30 e7 73 76 63 4b 37 31 62
                   2e af 30 d9 2e 22 a3 88 6f f1 09 27 9d 98 30 da
                   c7 27 af b9 4a 83 ee 6d 83 60 cb df a2 cc 06 40
        """.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "").hex
        XCTAssertEqual(derived, expected)
    }

    func testProfilerRun() {
        //            N: Int = 4096, R: Int = 6, P: Int = 1
        let password = "BANKEXFOUNDATION"
        let salt = Data.random(length: 32)
        XCTAssertNotNil(scrypt(password: password, salt: salt, length: 32, N: 4096, R: 6, P: 1))
    }

//    func testLibsodiumPerformance() {
//        let password = "BANKEXFOUNDATION"
//        let salt = Data.random(length: 32)
//        measure {
//            _ = scrypt(password: password, salt: salt, length: 32, N: 4096, R: 6, P: 1)
//        }
//    }
}
