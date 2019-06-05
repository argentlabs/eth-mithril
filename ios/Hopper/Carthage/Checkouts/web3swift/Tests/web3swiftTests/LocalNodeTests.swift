////
////  web3swift_local_node_Tests.swift
////  web3swift-iOS_Tests
////
////  Created by Petr Korolev on 16/04/2018.
////  Copyright © 2018 Bankex Foundation. All rights reserved.
////

import BigInt
//import CryptoSwift
import XCTest

@testable import web3swift

class LocalNodeTests: XCTestCase {
    var web3: Web3?
    override func setUp() {
        web3 = try? .local(port: 8545)
        if let web3 = web3 {
            Web3.default = web3
        }
    }
    func testDeployWithRemoteSigning() throws {
        guard let web3 = web3 else { return }
        let allAddresses = try web3.eth.getAccounts()
        let abiString = "[{\"constant\":true,\"inputs\":[],\"name\":\"getFlagData\",\"outputs\":[{\"name\":\"data\",\"type\":\"string\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"data\",\"type\":\"string\"}],\"name\":\"setFlagData\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]"
        let bytecode = "6060604052341561000f57600080fd5b6103358061001e6000396000f30060606040526004361061004c576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff168063a16e94bf14610051578063a46b5b6b146100df575b600080fd5b341561005c57600080fd5b61006461013c565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156100a4578082015181840152602081019050610089565b50505050905090810190601f1680156100d15780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156100ea57600080fd5b61013a600480803590602001908201803590602001908080601f0160208091040260200160405190810160405280939291908181526020018383808284378201915050505050509190505061020d565b005b610144610250565b6000808073ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156102035780601f106101d857610100808354040283529160200191610203565b820191906000526020600020905b8154815290600101906020018083116101e657829003601f168201915b5050505050905090565b806000808073ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600001908051906020019061024c929190610264565b5050565b602060405190810160405280600081525090565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106102a557805160ff19168380011785556102d3565b828001600101855582156102d3579182015b828111156102d25782518255916020019190600101906102b7565b5b5090506102e091906102e4565b5090565b61030691905b808211156103025760008160009055506001016102ea565b5090565b905600a165627a7a7230582017359d063cd7fdf56f19ca186a54863ce855c8f070acece905d8538fbbc4d1bf0029".hex
        let contract = try web3.contract(abiString, at: nil)
        var options = Web3Options.default
        options.from = allAddresses[0]
        options.gasLimit = BigUInt(3_000_000)
        let intermediate = try contract.deploy(bytecode: bytecode, options: options)
        let res = try intermediate.send(password: "")
        let txHash = res.hash
        print("Transaction with hash " + txHash)
        sleep(1)
        let rec = try web3.eth.getTransactionReceipt(txHash)
        XCTAssertNotEqual(rec.status, .notYetProcessed)
        let details = try web3.eth.getTransactionDetails(txHash)
        print(details)
    }

    func testEthSendExampleWithRemoteSigning() throws {
        guard let web3 = web3 else { return }
        let allAddresses = try web3.eth.getAccounts()
        let sendToAddress = Address("0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
        let contract = try web3.contract(Web3Utils.coldWalletABI, at: sendToAddress)
        var options = Web3Options.default
        options.value = Web3Utils.parseToBigUInt("1.0", units: .eth)
        options.from = allAddresses[0]
        let intermediate = try contract.method("fallback", options: options)
        try intermediate.send(password: "")
    }

    func testSignPersonal() throws {
        guard let web3 = web3 else { return }
        let allAddresses = try web3.eth.getAccounts()
        _ = try web3.personal.signPersonalMessage(message: "hello world".data, from: allAddresses[0])
    }

    // TODO: preinit new account to test
    //    func testUnlockAccount() {
    //        let web3 = Web3(url: URL(string: "http://127.0.0.1:8545")!)!
    //        guard case .success(let allAddresses) = web3.eth.getAccounts() else { return XCTFail() }
    //        let response = web3.personal.unlockAccount(account: Address("0x8c685dee28d5290e7d29e30b3deecd14853cd32b"), password: "1234")
    //        switch response {
    //        case .failure(_):
    //            XCTFail()
    //            return
    //        case .success(let result):
    //            print(result)
    //        }
    //    }
}
