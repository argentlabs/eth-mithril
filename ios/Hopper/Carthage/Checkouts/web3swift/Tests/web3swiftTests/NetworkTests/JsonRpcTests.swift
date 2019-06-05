//
//  JsonRpcTests.swift
//  Tests
//
//  Created by Dmitry on 17/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import XCTest
import PromiseKit
import BigInt
@testable import web3swift

class TestCallRequest: Request {
    init() {
        super.init(method: "eth_call")
    }
    override func request() -> [Any] {
        return [[
            "data": "0x06fdde03",
            "to":"0x45245bc59219eeaaf6cd3f382e078a461ff9de7b",
            "value":"0x0",
            "gasPrice":"0x0"
            ], "latest"]
    }
    override func response(data: DictionaryReader) throws {
        let expected = "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e2242414e4b4558222070726f6a656374207574696c69747920746f6b656e0000"
        try data.string().equals(expected)
    }
}

class JsonRpcTests: XCTestCase {
    func testRequest() throws {
        let request = TestCallRequest()
        URLSession.shared.send(request: request, to: .infura(.mainnet))
        _ = try! request.promise.wait()
    }
}
