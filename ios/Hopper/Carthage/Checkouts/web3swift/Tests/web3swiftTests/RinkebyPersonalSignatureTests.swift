//
//  web3swift_personal_signature_Tests.swift
//  web3swift-iOS_Tests
//
//  Created by Anton Grigoriev on 02.07.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
//import CryptoSwift
import XCTest

@testable import web3swift

class RinkebyPersonalSignatureTests: XCTestCase {
    func testPersonalSignature() throws {
        let web3 = Web3(infura: .rinkeby)
        let tempKeystore = try! EthereumKeystoreV3(password: "")
        let keystoreManager = KeystoreManager([tempKeystore!])
        web3.addKeystoreManager(keystoreManager)
        let message = "Hello World".data
        let expectedAddress = keystoreManager.addresses[0]
        print(expectedAddress)
        let signature = try web3.personal.signPersonalMessage(message: message, from: expectedAddress, password: "")
        let unmarshalledSignature = try SECP256K1.unmarshalSignature(signatureData: signature)
        print("V = " + String(unmarshalledSignature.v))
        print("R = " + Data(unmarshalledSignature.r).hex)
        print("S = " + Data(unmarshalledSignature.s).hex)
        try! print("Personal hash = " + Web3Utils.hashPersonalMessage(message).hex)
        let signer = try web3.personal.ecrecover(personalMessage: message, signature: signature)
        XCTAssert(expectedAddress == signer, "Failed to sign personal message")
    }

    func testPersonalSignatureOnContract() throws {
        let web3 = Web3(infura: .rinkeby)
        let tempKeystore = try! EthereumKeystoreV3(password: "")
        let keystoreManager = KeystoreManager([tempKeystore!])
        web3.addKeystoreManager(keystoreManager)
        let message = "Hello World"
        let messageData = message.data
        let expectedAddress = keystoreManager.addresses[0]
        print(expectedAddress)
        let signature = try web3.personal.signPersonalMessage(message: messageData, from: expectedAddress, password: "")
        let unmarshalledSignature = try SECP256K1.unmarshalSignature(signatureData: signature)
        print("V = " + String(unmarshalledSignature.v))
        print("R = " + Data(unmarshalledSignature.r).hex)
        print("S = " + Data(unmarshalledSignature.s).hex)
        try print("Personal hash = " + Web3Utils.hashPersonalMessage(messageData).hex)
        let jsonString = "[{\"inputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"constant\":true,\"inputs\":[{\"name\":\"_message\",\"type\":\"string\"}],\"name\":\"hashPersonalMessage\",\"outputs\":[{\"name\":\"hash\",\"type\":\"bytes32\"}],\"payable\":false,\"stateMutability\":\"pure\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_message\",\"type\":\"string\"},{\"name\":\"v\",\"type\":\"uint8\"},{\"name\":\"r\",\"type\":\"bytes32\"},{\"name\":\"s\",\"type\":\"bytes32\"}],\"name\":\"recoverSigner\",\"outputs\":[{\"name\":\"signer\",\"type\":\"address\"}],\"payable\":false,\"stateMutability\":\"pure\",\"type\":\"function\"}]"
        let contract = try web3.contract(jsonString, at: "0x6f1745a39059268e8e4572e97897b50e4aab62a8")
        var options = Web3Options.default
        options.from = expectedAddress
        var intermediate = try contract.method("hashPersonalMessage", args: message, options: options)
        var res = try intermediate.call(options: nil)
        guard let hash = res["hash"]! as? Data else { return XCTFail() }
        let hash2 = try Web3Utils.hashPersonalMessage(messageData)
        XCTAssert(hash2 == hash)

        intermediate = try contract.method("recoverSigner", args: message, unmarshalledSignature.v, Data(unmarshalledSignature.r), Data(unmarshalledSignature.s), options: options)
        res = try intermediate.call(options: nil)
        guard let signer = res["signer"]! as? Address else { return XCTFail() }
        print(signer)
        XCTAssert(signer == expectedAddress)
    }
}
