//
//  web3swiftTests.swift
//  web3swiftTests
//
//  Created by Alexander Vlasov on 04.12.2017.
//  Copyright © 2017 Alexander Vlasov. All rights reserved.
//

import BigInt
//import CryptoSwift
import XCTest

@testable import web3swift

class Tests: XCTestCase {
    func testBitFunctions() {
        let data = Data([0xF0, 0x02, 0x03])
        let firstBit = data.bitsInRange(0, 1)
        XCTAssert(firstBit == 1)
        let first4bits = data.bitsInRange(0, 4)
        XCTAssert(first4bits == 0x0F)
    }

    func testCombiningPublicKeys() {
        let priv1 = Data(repeating: 0x01, count: 32)
        let pub1 = try! Web3Utils.privateToPublic(priv1, compressed: true)
        let priv2 = Data(repeating: 0x02, count: 32)
        let pub2 = try! Web3Utils.privateToPublic(priv2, compressed: true)
        let combined = try! SECP256K1.combineSerializedPublicKeys(keys: [pub1, pub2], outputCompressed: true)
        let compinedPriv = Data(repeating: 0x03, count: 32)
        let compinedPub = try! Web3Utils.privateToPublic(compinedPriv, compressed: true)
        XCTAssert(compinedPub == combined)
    }

    func testChecksumAddress() {
        let input = "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359"
        let output = Address.toChecksumAddress(input)
        XCTAssert(output == "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359", "Failed to checksum address")
    }

    func testChecksumAddressParsing() {
        let input = "0xfb6916095ca1df60bB79Ce92cE3Ea74c37c5d359"
        let addr = Address(input)
        XCTAssert(addr.isValid)
//        let invalidInput = "0xfb6916095ca1df60bB79Ce92cE3Ea74c37c5d359"
//        let invalidAddr = Address(invalidInput)
//        XCTAssert(!invalidAddr.isValid)
    }

    func testBigUIntFromHex() {
        let hexRepresentation = "0x1c31de57e49fc00".withoutHex
        let biguint = BigUInt(hexRepresentation, radix: 16)!
        XCTAssert(biguint == BigUInt("126978086000000000"))
    }

    func testBloom() {
        let positive = [
            "testtest",
            "test",
            "hallo",
            "other",
        ]
        let negative = [
            "tes",
            "lo",
        ]
        var bloom = EthereumBloomFilter()
        for str in positive {
            let oldBytes = bloom.bytes
            bloom.add(BigUInt(str.data))
            let newBytes = bloom.bytes
            if newBytes != oldBytes {
                print("Added new bits")
            }
        }
        for str in positive {
            XCTAssert(bloom.test(topic: str.data), "Failed")
        }
        for str in negative {
            XCTAssert(bloom.test(topic: str.data) == false, "Failed")
        }
    }

    func testMakePrivateKey() {
        let privateKey = Data.random(length: 32)
        let publicKey = try? SECP256K1.privateToPublic(privateKey: privateKey)
        XCTAssert(publicKey != nil, "Failed to create new private key")
    }

    func testUserCaseEventParsing() throws {
        let contractAddress = Address("0x7ff546aaccd379d2d1f241e1d29cdd61d4d50778")
        let jsonString = "[{\"constant\":false,\"inputs\":[{\"name\":\"_id\",\"type\":\"string\"}],\"name\":\"deposit\",\"outputs\":[],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"name\":\"_from\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"_id\",\"type\":\"string\"},{\"indexed\":true,\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"Deposit\",\"type\":\"event\"}]"
        let web3 = Web3(infura: .rinkeby)
        let contract = try web3.contract(jsonString, at: contractAddress)
        guard let eventParser = contract.createEventParser("Deposit", filter: nil) else { return XCTFail() }
        let pres = try eventParser.parseBlockByNumber(UInt64(2_138_657))
        print(pres)
        XCTAssert(pres.count == 1)
    }

    func testIBANCreation() {
        let iban = "XE7338O073KYGTWWZN0F2WZ0R8PX5ZPPZS"
        let native = IBAN(iban)
        XCTAssert(native != nil)
        let expectedAddress = "0x00c5496aEe77C1bA1f0854206A26DdA82a81D6D8"
        let createdAddress = native?.toAddress()?.address
        XCTAssert(createdAddress == expectedAddress)

        let address = Address("0x03c5496aee77c1ba1f0854206a26dda82a81d6d8")
        let fromAddress = IBAN(address)
        let ibn = fromAddress.iban
        XCTAssert(ibn == "XE83FUTTUNPK7WZJSGGCWVEBARQWQ8YML4")
    }
    
    func testIBANCheckAddress() {
        XCTAssertFalse(IBAN.check("0x9e87448bff240dace7cea2e90670b8d6c2c73a6e"))
        XCTAssertTrue(IBAN.check("0x00c5496aEe77C1bA1f0854206A26DdA82a81D6D8"))
    }

    func testGenericRPCresponse() {
        let hex = "0x1"
        let rpcResponse = JsonRpcResponse(id: 1, jsonrpc: "2.0", result: hex, error: nil)
        let value: BigUInt? = rpcResponse.getValue()
        XCTAssert(value == 1)
    }

    func testPublicMappingsAccess() throws {
        let jsonString = "[{\"constant\":true,\"inputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"users\",\"outputs\":[{\"name\":\"name\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"\",\"type\":\"address\"}],\"name\":\"userDeviceCount\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"totalUsers\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}]"
        let web3 = Web3(infura: .rinkeby)
        let addr = Address("0xdef61132a0c1259464b19e4590e33666aae38574")
        let contract = try web3.contract(jsonString, at: addr)
        let allMethods = contract.contract.allMethods
        let userDeviceCount = try contract.method("userDeviceCount", args: addr, options: nil).callPromise().wait()
        print(userDeviceCount)
        let totalUsers = try contract.method("totalUsers", options: nil).callPromise().wait()
        print(totalUsers)
        let user = try contract.method("users", args: 0, options: nil).callPromise().wait()
        print(user)
        print(allMethods)
    }
}
