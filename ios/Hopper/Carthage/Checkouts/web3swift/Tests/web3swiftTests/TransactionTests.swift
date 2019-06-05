//
//  web3swiftTransactionsTests.swift
//  web3swift-iOS_Tests
//
//  Created by Георгий Фесенко on 02/07/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
//import CryptoSwift
import XCTest

@testable import web3swift

class TransactionsTests: XCTestCase {
    func testTransaction() throws {
        do {
            var transaction = EthereumTransaction(nonce: 9,
                                                  gasPrice: 20_000_000_000,
                                                  gasLimit: 21000,
                                                  to: "0x3535353535353535353535353535353535353535",
                                                  value: "1000000000000000000",
                                                  data: Data(),
                                                  v: 0,
                                                  r: 0,
                                                  s: 0)
            let privateKeyData = Data.fromHex("0x4646464646464646464646464646464646464646464646464646464646464646")!
            let publicKey = try Web3Utils.privateToPublic(privateKeyData, compressed: false)
            let sender = try Web3Utils.publicToAddress(publicKey)
            transaction.chainID = 1
            print(transaction)
            let hash = transaction.hashForSignature(chainID: 1)
            let expectedHash = "0xdaf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53".withoutHex
            XCTAssert(hash!.hex == expectedHash, "Transaction signature failed")
            try Web3Signer.EIP155Signer.sign(transaction: &transaction, privateKey: privateKeyData, useExtraEntropy: false)
            print(transaction)
            XCTAssert(transaction.v == 37, "Transaction signature failed")
            XCTAssert(sender == transaction.sender)
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testEthSendExample() throws {
        let web3 = Web3(infura: .mainnet)
        let sendToAddress = Address("0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
        let tempKeystore = try! EthereumKeystoreV3(password: "")
        let keystoreManager = KeystoreManager([tempKeystore!])
        web3.addKeystoreManager(keystoreManager)
        let contract = try web3.contract(Web3Utils.coldWalletABI, at: sendToAddress)
        var options = Web3Options.default
        options.value = Web3Utils.parseToBigUInt("1.0", units: .eth)
        options.from = keystoreManager.addresses.first
        let intermediate = try contract.method("fallback", options: options)
        do {
            try intermediate.send(password: "")
            XCTFail("Shouldn't be sended")
        } catch let Web3Error.nodeError(descr) {
            XCTAssertEqual(descr, "insufficient funds for gas * price + value")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testTransactionReceipt() throws {
        let web3 = Web3(infura: .mainnet)
        let response = try web3.eth.getTransactionReceipt("0x83b2433606779fd756417a863f26707cf6d7b2b55f5d744a39ecddb8ca01056e")
        XCTAssert(response.status == .ok)
    }

    func testTransactionDetails() throws {
        let web3 = Web3(infura: .mainnet)
        let response = try web3.eth.getTransactionDetails("0x127519412cefd773b952a5413a4467e9119654f59a34eca309c187bd9f3a195a")
        XCTAssert(response.transaction.gasLimit == BigUInt(78423))
    }

    func getKeystoreData() -> Data? {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "key", ofType: "json") else { return nil }
        guard let data = NSData(contentsOfFile: path) else { return nil }
        return data as Data
    }

    func testSendETH() throws {
        guard let keystoreData = getKeystoreData() else { return }
        guard let keystoreV3 = EthereumKeystoreV3(keystoreData) else { return XCTFail() }
        let web3Rinkeby = Web3(infura: .rinkeby)
        let keystoreManager = KeystoreManager([keystoreV3])
        web3Rinkeby.addKeystoreManager(keystoreManager)
        let gasPriceRinkeby = try web3Rinkeby.eth.getGasPrice()
        let sendToAddress = Address("0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
        let intermediate = try web3Rinkeby.eth.sendETH(to: sendToAddress, amount: "0.001")
        var options = Web3Options.default
        options.from = keystoreV3.addresses.first
        options.gasPrice = gasPriceRinkeby
        try intermediate.send(password: "BANKEXFOUNDATION", options: options)
    }

    func testTokenBalanceTransferOnMainNet() throws {
        // BKX TOKEN
        let web3 = Web3(infura: .mainnet)
        let coldWalletAddress = Address("0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
        let contractAddress = Address("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
        var options = Web3Options()
        options.from = coldWalletAddress
        let tempKeystore = try! EthereumKeystoreV3(password: "")
        let keystoreManager = KeystoreManager([tempKeystore!])
        web3.addKeystoreManager(keystoreManager)
        let contract = try web3.contract(Web3Utils.erc20ABI, at: contractAddress)
        try contract.method("transfer", args: coldWalletAddress, BigUInt(1), options: options).call(options: nil)
    }
    
    func testRawTransaction() {
        let transactionString = "0xa9059cbb00000000000000000000000083b0b52a887a4c05429ee6d4619afeb8007c1a330000000000000000000000000000000000000000000000000001c6bf52634000"
        let transactionData = Data.fromHex(transactionString)!
        let rawTransaction = EthereumTransaction.fromRaw(transactionData)
        XCTAssertNil(rawTransaction)
    }

//    func testTokenBalanceTransferOnMainNetUsingConvenience() throws {
//        // BKX TOKEN
//        let web3 = Web3(infura: .mainnet)
//        let coldWalletAddress = Address("0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
//        let contractAddress = Address("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
//        let tempKeystore = try! EthereumKeystoreV3(password: "")
//        let keystoreManager = KeystoreManager([tempKeystore!])
//        web3.addKeystoreManager(keystoreManager)
//        let intermediate = try web3.eth.sendERC20tokensWithNaturalUnits(tokenAddress:contractAddress, from: coldWalletAddress, to: coldWalletAddress, amount: "1.0")
//        let gasLimit = try intermediate.estimateGas(options: nil)
//        var options = Web3Options();
//        options.gasLimit = gasLimit
//        try intermediate.call(options: options)
//    }
}
