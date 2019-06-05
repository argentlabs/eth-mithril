//
//  Tests.swift
//  Tests
//
//  Created by Dmitry on 13/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

class GanacheTests: XCTestCase {

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // Connecting to your ganache node
        guard let web3 = try? Web3.local(port: 8545) else { return }
        Web3.default = web3
        
        // Importing account using mnemonics
        let mnemonicsString = "nation tornado double since increase orchard tonight left drip talk sand mad"
        let mnemonics = try! Mnemonics(mnemonicsString)
        
        let keystore = try! BIP32Keystore(mnemonics: mnemonics)
        
        // Now set keystore as your Web3.default keystore
        Web3.default.keystoreManager.append(keystore)
        
        // Ganache using hdpath for its accounts. So to load next 9 subaccounts just use:
        for _ in 0..<9 {
            try keystore.createNewChildAccount()
        }
        
        // Now you can print them all:
        print(keystore.addresses.map { $0.description }.joined(separator: "\n"))
        
        /* prints:
         0xDf2bC70175311A6807F085e54881Fc4931359dBF
         0xA6090DE9BcDcfdF153cDa9c56d3c1b324d9E6c1f
         0xC711490Bca5Bb74218EBf48BbA9Fe46718658eCF
         0x1349D9fFf512F322a1575cE2b2d6C3b4F9D2D4Ee
         0xDbA8EAa24a192dFfBDcdCe8599c3ED9451566572
         0x57034d57b69b2f172814252Df7A54B072cF46104
         0x588F661eF26ff481C580755E1A58029807DE6E73
         0x085fe021f91AA43587f7c18785dd7DC6e938B3a8
         0x2608dAC7b490Fa3A7DC4De38B046Dc3b5CB60910
         0x3868dd20179e53B0449f62Cf4933B359369eA00f
         */
        
        // and check the balance:
        for address in web3.keystoreManager.addresses {
            web3.eth.getBalancePromise(address: address).done { balance in
                let privateKey: Data = try! web3.keystoreManager.UNSAFE_getPrivateKeyData(account: address)
                print("")
                print("Address:", address)
                print("Private key:", privateKey.hex.withHex)
                print("Balance:", balance.string(units: .eth), "ether")
            }.catch { error in
                print("error: \(error)")
            }
        }
        
        /* prints:
         
         Address: 0x57034d57b69b2f172814252Df7A54B072cF46104
         Private key: 0x1085338b5ca27ad6e0beee3de9f54fc8afbaf98b1a62d86a2c7b9ea8555aaefd
         Balance: 100 ether
         
         Address: 0xDf2bC70175311A6807F085e54881Fc4931359dBF
         Private key: 0x8e3ed3451ab7058fc15b789d52991b47f2a9e373de9280982ac79244ccceb862
         Balance: 100 ether
         
         Address: 0x085fe021f91AA43587f7c18785dd7DC6e938B3a8
         Private key: 0xa8a454547853ad4acc71dfddc1d9ec279c87c1d8463c9e4c9ae089c9861debf3
         Balance: 100 ether
         
         Address: 0xC711490Bca5Bb74218EBf48BbA9Fe46718658eCF
         Private key: 0x458d2c3daafc6a0ab327e1ee8451a8adeb72f78abeb279d0db05a698889ffd53
         Balance: 100 ether
         
         Address: 0x3868dd20179e53B0449f62Cf4933B359369eA00f
         Private key: 0x7ae211cd18ce0ad2222cf324944861076008f4a4856cd54f0846ed064f88778d
         Balance: 100 ether
         
         Address: 0x2608dAC7b490Fa3A7DC4De38B046Dc3b5CB60910
         Private key: 0x4e4282e6d3e95194260b8bd18e7925f2fc45a7ed7fe20bb9a7b839a915ab1002
         Balance: 100 ether
         
         Address: 0xDbA8EAa24a192dFfBDcdCe8599c3ED9451566572
         Private key: 0xe15befa58edf55c2ac1bc68027d8926be80125da268e2ba86eba7e2815bc709a
         Balance: 100 ether
         
         Address: 0x1349D9fFf512F322a1575cE2b2d6C3b4F9D2D4Ee
         Private key: 0xf277c64480cf53e8eedf8fc30df8aafc13d6a8e3750882efc248ba2ccb8baaa2
         Balance: 100 ether
         
         Address: 0x588F661eF26ff481C580755E1A58029807DE6E73
         Private key: 0x7799fe5004d928282ad997670aa9fc7ac7aaf27d88e6c969761c4b1863df14a2
         Balance: 100 ether
         
         Address: 0xA6090DE9BcDcfdF153cDa9c56d3c1b324d9E6c1f
         Private key: 0x17215215562d34c3a256c255e396135072af433c0a0060d1130fea12d6ea7254
         Balance: 100 ether
         */
        
        // and now you can send some ether from one account to another
        var options = Web3Options.default
        options.from = keystore.addresses[0]
        
        let transaction = try web3.eth.sendETH(to: keystore.addresses[1], amount: BigUInt("10", units: .eth)!).send(options: options)
        print(transaction.hash)
        // prints: 0x6f150015d033de944f17c1e1f63aa798bcbac7b9144f53520f4795596df84852
        
        let details = try Web3.default.eth.getTransactionDetails(transaction.hash)
        print(details)
        /* prints:
         TransactionDetails(blockHash: Optional(32 bytes), blockNumber: Optional(1), transactionIndex: Optional(1), transaction: Transaction
         Nonce: 0
         Gas price: 2000000000
         Gas limit: 21000
         To: 0x57034d57b69b2f172814252Df7A54B072cF46104
         Value: 10000000000000000000
         Data: 00
         v: 11590
         r: 75318665125390684876839360987611904628529668743494333300496321819169931926792
         s: 28634163277963307970864505412680829623562938665383387835249573242584919213107
         Intrinsic chainID: Optional()
         Infered chainID: Optional()
         sender: Optional("0x4BFE5EC6182Dd745c3FB3a20A58b69a18013D8e8")
         hash: Optional(32 bytes))
         */
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testDetails() throws {
        guard let web3 = try? Web3.local(port: 8545) else { return }
        Web3.default = web3
        
        let details = try Web3.default.eth.getTransactionDetails("0x6f150015d033de944f17c1e1f63aa798bcbac7b9144f53520f4795596df84852")
        print(details)
        /* prints:
         TransactionDetails(blockHash: Optional(32 bytes), blockNumber: Optional(1), transactionIndex: Optional(1), transaction: Transaction
         Nonce: 0
         Gas price: 2000000000
         Gas limit: 21000
         To: 0x57034d57b69b2f172814252Df7A54B072cF46104
         Value: 10000000000000000000
         Data: 00
         v: 11590
         r: 75318665125390684876839360987611904628529668743494333300496321819169931926792
         s: 28634163277963307970864505412680829623562938665383387835249573242584919213107
         Intrinsic chainID: Optional()
         Infered chainID: Optional()
         sender: Optional("0x4BFE5EC6182Dd745c3FB3a20A58b69a18013D8e8")
         hash: Optional(32 bytes))
         */
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
