//
//  web3swiftKyestoresTests.swift
//  web3swift-iOS_Tests
//
//  Created by Георгий Фесенко on 02/07/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import XCTest
//import Cryptor

@testable import web3swift

class KeystoresTests: XCTestCase {

    func testBIP39() throws {
        // 2.159708023071289 sec to complete
        var entropy = Data.fromHex("00000000000000000000000000000000")!
        var mnemonics = try Mnemonics(entropy: entropy)
        XCTAssertEqual(mnemonics.string, "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
        mnemonics.password = "TREZOR"
        var seed = mnemonics.seed()
        XCTAssert(seed.hex == "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04")
        entropy = Data.fromHex("68a79eaca2324873eacc50cb9c6eca8cc68ea5d936f98787c60c7ebc74e6ce7c")!
        mnemonics = try Mnemonics(entropy: entropy)
        XCTAssertEqual(mnemonics.string, "hamster diagram private dutch cause delay private meat slide toddler razor book happy fancy gospel tennis maple dilemma loan word shrug inflict delay length")
        mnemonics.password = "TREZOR"
        seed = mnemonics.seed()
        XCTAssert(seed.hex == "64c87cde7e12ecf6704ab95bb1408bef047c22db4cc7491c4271d170a1b213d20b385bc1588d9c7b38f1b39d415665b8a9030c9ec653d75e65f847d8fc1fc440")
    }
    
    func testImportAndExport() throws {
        let json = """
{"version":3,"id":"8b60fda9-5f27-4478-9cc9-72059571aa6e","crypto":{"ciphertext":"d34e78640359a599970a58b3b4b7c987945e56c69411028ea62394e8d1ea7e4b","cipherparams":{"iv":"6e4a429a30807ab9202a9aefad152398"},"kdf":"scrypt","kdfparams":{"r":6,"p":1,"n":4096,"dklen":32,"salt":"0000000000000000000000000000000000000000000000000000000000000000"},"mac":"79888d6ce3a2a24d6b70d07ca9067b57e4a57bd9416a3abb336900cacf82e29a","cipher":"aes-128-cbc"},"address":"0b0f7a95485060973726d03e7c326a6542bcb55b"}
"""
        let keystore = EthereumKeystoreV3(json)!
        let data = try keystore.serialize()!
        let key = try keystore.UNSAFE_getPrivateKeyData(password: "hello world", account: keystore.addresses[0]).hex
        
        let keystore2 = EthereumKeystoreV3(data)!
        let data2 = try keystore2.serialize()!
        let key2 = try keystore2.UNSAFE_getPrivateKeyData(password: "hello world", account: keystore.addresses[0]).hex
        
        XCTAssertEqual(data,data2)
        XCTAssertEqual(key,key2)
    }

    func testHMAC() {
        // 0.0021849870681762695 sec to complete
        let seed = "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b".hex.bytes
        let data = "4869205468657265".hex
        let hmac = try! HMAC(key: seed, variant: .sha512).authenticate(data.bytes)
        XCTAssert(Data(hmac).hex == "87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854")
    }
    
    func testMnemonicsWithAllLanguagesAndEntropySizes() {
        let languages: [BIP39Language] = [.english, .chinese_simplified, .chinese_traditional, .japanese, .korean, .french, .italian, .spanish]
        var mnemonics: Mnemonics!
        let entropySizes: [EntropySize] = [.b128, .b160, .b192, .b224, .b256]
        for language in languages {
            for size in entropySizes {
                mnemonics = Mnemonics(entropySize: size, language: language)
            }
        }
        XCTAssert(mnemonics.seed().count > 0)
    }

    func testV3keystoreExportPrivateKey() {
        // 5.033522009849548 sec to complete
        let keystore = try! EthereumKeystoreV3(password: "")
        XCTAssertNotNil(keystore)
        let account = keystore!.addresses[0]
        let data = try! keystore!.serialize()
        _ = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0))
        let key = try! keystore!.UNSAFE_getPrivateKeyData(password: "", account: account)
        XCTAssertNotNil(key)
    }

    func testNewBIP32keystore() throws {
        // 1.7766820192337036 sec to complete
        let mnemonics = Mnemonics()
        XCTAssertNoThrow(try BIP32Keystore(mnemonics: mnemonics, password: ""))
    }

    func testBIP32keystoreExportPrivateKey() throws {
        // 6.153380036354065 sec to complete
        let mnemonics = try! Mnemonics("normal dune pole key case cradle unfold require tornado mercy hospital buyer")
        let keystore = try! BIP32Keystore(mnemonics: mnemonics, password: "")
        XCTAssertNotNil(keystore)
        let account = keystore.addresses[0]
        _ = try! keystore.UNSAFE_getPrivateKeyData(password: "", account: account)
    }

    func testBIP32keystoreMatching() throws {
        // 5.8 sec to complete
        let mnemonics = try Mnemonics("fruit wave dwarf banana earth journey tattoo true farm silk olive fence")
        mnemonics.password = "banana"
        let keystore = try BIP32Keystore(mnemonics: mnemonics, password: "")
        let account = keystore.addresses[0]
        let privateKey = try keystore.UNSAFE_getPrivateKeyData(password: "", account: account)
        let publicKey = try Web3Utils.privateToPublic(privateKey, compressed: true)
        XCTAssertEqual(publicKey.hex, "027160bd3a4d938cac609ff3a11fe9233de7b76c22a80d2b575e202cbf26631659")
    }

    func testBIP32keystoreMatchingRootNode() throws {
        // 5.793358087539673 sec to complete
        let mnemonics = try Mnemonics("fruit wave dwarf banana earth journey tattoo true farm silk olive fence")
        mnemonics.password = "banana"
        let keystore = try BIP32Keystore(mnemonics: mnemonics, password: "")
        let rootNode = try keystore.serializeRootNodeToString(password: "")
        XCTAssertEqual(rootNode, "xprvA2KM71v838kPwE8Lfr12m9DL939TZmPStMnhoFcZkr1nBwDXSG7c3pjYbMM9SaqcofK154zNSCp7W7b4boEVstZu1J3pniLQJJq7uvodfCV")
    }

    func testBIP32keystoreCustomPathMatching() throws {
        // 5.992403030395508 sec to complete
        let mnemonics = try Mnemonics("fruit wave dwarf banana earth journey tattoo true farm silk olive fence")
        mnemonics.password = "banana"
        let keystore = try BIP32Keystore(mnemonics: mnemonics, password: "", prefixPath: "m/44'/60'/0'/0")
        XCTAssertNotNil(keystore)
        let account = keystore.addresses[0]
        let key = try keystore.UNSAFE_getPrivateKeyData(password: "", account: account)
        let pubKey = try Web3Utils.privateToPublic(key, compressed: true)
        XCTAssertEqual(pubKey.hex, "027160bd3a4d938cac609ff3a11fe9233de7b76c22a80d2b575e202cbf26631659")
    }

    func testByBIP32keystoreCreateChildAccount() throws {
        //  sec to complete
        let mnemonics = try Mnemonics("normal dune pole key case cradle unfold require tornado mercy hospital buyer")
        let keystore = try! BIP32Keystore(mnemonics: mnemonics, password: "")
        XCTAssertNotNil(keystore)
        XCTAssertEqual(keystore.addresses.count, 1)
        try! keystore.createNewChildAccount(password: "")
        XCTAssertEqual(keystore.addresses.count, 2)
        let account = keystore.addresses[0]
        let key = try! keystore.UNSAFE_getPrivateKeyData(password: "", account: account)
        XCTAssertNotNil(key)
    }

    func testByBIP32keystoreCreateCustomChildAccount() throws {
        //  sec to complete
        let mnemonics = try Mnemonics("normal dune pole key case cradle unfold require tornado mercy hospital buyer")
        let keystore = try! BIP32Keystore(mnemonics: mnemonics, password: "")
        XCTAssertNotNil(keystore)
        XCTAssertEqual(keystore.addresses.count, 1)
        try! keystore.createNewCustomChildAccount(password: "", path: "/42/1")
        XCTAssertEqual(keystore.addresses.count, 2)
        let account = keystore.addresses[1]
        let key = try! keystore.UNSAFE_getPrivateKeyData(password: "", account: account)
        XCTAssertNotNil(key)
        print(keystore.paths)
    }

    func testByBIP32keystoreSaveAndDeriva() throws {
        let mnemonics = try Mnemonics("normal dune pole key case cradle unfold require tornado mercy hospital buyer")
        let keystore = try! BIP32Keystore(mnemonics: mnemonics, password: "", prefixPath: "m/44'/60'/0'")
        XCTAssertNotNil(keystore)
        XCTAssertEqual(keystore.addresses.count, 1)
        try! keystore.createNewCustomChildAccount(password: "", path: "/0/1")
        XCTAssertEqual(keystore.addresses.count, 2)
        let data = try! keystore.serialize()!
        guard let recreatedStore = BIP32Keystore(data) else { XCTFail(); return }
        XCTAssert(keystore.addresses.count == recreatedStore.addresses.count)
        XCTAssert(keystore.rootPrefix == recreatedStore.rootPrefix)
        XCTAssertEqual(Set(keystore.addresses), Set(recreatedStore.addresses))
    }

    //    func testPBKDF2() {
    //        let pass = "passDATAb00AB7YxDTTl".data
    //        let salt = "saltKEYbcTcXHCBxtjD2".data
    //        let dataArray = try? PKCS5.PBKDF2(password: pass.bytes, salt: salt.bytes, iterations: 100000, keyLength: 65, variant: HMAC.Variant.sha512).calculate()
    //        XCTAssert(Data(dataArray!).hex.withHex.lowercased() == "0x594256B0BD4D6C9F21A87F7BA5772A791A10E6110694F44365CD94670E57F1AECD797EF1D1001938719044C7F018026697845EB9AD97D97DE36AB8786AAB5096E7".lowercased())
    //    }

    func testRIPEMD() {
        //  sec to complete
        let data = "message digest".data(using: .ascii)
        let hash = RIPEMD160.hash(message: data!)
        XCTAssert(hash.hex == "5d0689ef49d2fae572b881b123a85ffa21595f36")
    }

    func testHD32() throws {
        //  sec to complete
        let seed = Data.fromHex("000102030405060708090a0b0c0d0e0f")!
        let node = try! HDNode(seed: seed)
        XCTAssert(node.chaincode == Data.fromHex("873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"))
        let serialized = node.serializeToString()
        let serializedPriv = node.serializeToString(serializePublic: false)
        XCTAssert(serialized == "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8")
        XCTAssert(serializedPriv == "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi")

        let deserializedNode = HDNode(serializedPriv!)
        XCTAssert(deserializedNode != nil)
        XCTAssert(deserializedNode?.depth == 0)
        XCTAssert(deserializedNode?.index == UInt32(0))
        XCTAssert(deserializedNode?.isHardened == false)
        XCTAssert(deserializedNode?.parentFingerprint == Data.fromHex("00000000"))
        XCTAssert(deserializedNode?.privateKey == node.privateKey)
        XCTAssert(deserializedNode?.publicKey == node.publicKey)
        XCTAssert(deserializedNode?.chaincode == node.chaincode)

        let nextNode = try node.derive(index: 0, derivePrivateKey: true)
        XCTAssert(nextNode.depth == 1)
        XCTAssert(nextNode.index == UInt32(0))
        XCTAssert(nextNode.isHardened == false)
        XCTAssert(nextNode.parentFingerprint == Data.fromHex("3442193e"))
        XCTAssert(nextNode.publicKey.hex == "027c4b09ffb985c298afe7e5813266cbfcb7780b480ac294b0b43dc21f2be3d13c")
        XCTAssert(nextNode.serializeToString() == "xpub68Gmy5EVb2BdFbj2LpWrk1M7obNuaPTpT5oh9QCCo5sRfqSHVYWex97WpDZzszdzHzxXDAzPLVSwybe4uPYkSk4G3gnrPqqkV9RyNzAcNJ1")
        XCTAssert(nextNode.serializeToString(serializePublic: false) == "xprv9uHRZZhbkedL37eZEnyrNsQPFZYRAvjy5rt6M1nbEkLSo378x1CQQLo2xxBvREwiK6kqf7GRNvsNEchwibzXaV6i5GcsgyjBeRguXhKsi4R")

        let nextNodeHardened = try node.derive(index: 0, derivePrivateKey: true, hardened: true)
        XCTAssert(nextNodeHardened.depth == 1)
        XCTAssert(nextNodeHardened.index == UInt32(0))
        XCTAssert(nextNodeHardened.isHardened == true)
        XCTAssert(nextNodeHardened.parentFingerprint == Data.fromHex("3442193e"))
        XCTAssert(nextNodeHardened.publicKey.hex == "035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56")
        XCTAssert(nextNodeHardened.serializeToString() == "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw")
        XCTAssert(nextNodeHardened.serializeToString(serializePublic: false) == "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7")

        let treeNode = try node.derive(path: HDNode.defaultPath)
        XCTAssert(treeNode.depth == 4)
        XCTAssert(treeNode.serializeToString() == "xpub6DZ3xpo1ixWwwNDQ7KFTamRVM46FQtgcDxsmAyeBpTHEo79E1n1LuWiZSMSRhqMQmrHaqJpek2TbtTzbAdNWJm9AhGdv7iJUpDjA6oJD84b")
        XCTAssert(treeNode.serializeToString(serializePublic: false) == "xprv9zZhZKG7taxeit8w1HiTDdUko2Fm1RxkrjxANbEaG7kFvJp5UEh6MiQ5b5XvwWg8xdHMhueagettVG2AbfqSRDyNpxRDBLyMSbNq1KhZ8ai")
    }

    func testBIP32derivation2() throws {
        //  sec to complete
        let seed = Data.fromHex("fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")!
        let node = try HDNode(seed: seed)
        let path = "m/0/2147483647'/1/2147483646'/2"
        let treeNode = try node.derive(path: path)
        XCTAssert(treeNode.depth == 5)
        XCTAssert(treeNode.serializeToString() == "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt")
        XCTAssert(treeNode.serializeToString(serializePublic: false) == "xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j")
    }
    
    
    func testKeystoreThrows() throws {
        // 13 words
        XCTAssertThrowsError(try Mnemonics("fruit wave dwarf banana earth journey tattoo true farm silk olive fence fruit"))
        // 8 words
        XCTAssertThrowsError(try Mnemonics("fruit wave dwarf banana earth journey tattoo true"))
        // no words
        XCTAssertThrowsError(try Mnemonics(""))
        // invalid 12 words
        XCTAssertThrowsError(try Mnemonics("a b c d a b c d a b c d"))
        let validMnemonics = try Mnemonics("fruit wave dwarf banana earth journey tattoo true farm silk olive fence")
        validMnemonics.password = "banana"
        let keystore = try BIP32Keystore(mnemonics: validMnemonics, password: "", prefixPath: "m/44'/60'/0'/0")
        let account = keystore.addresses[0]
        XCTAssertThrowsError(try keystore.UNSAFE_getPrivateKeyData(password: "some password", account: account))
        let key = try keystore.UNSAFE_getPrivateKeyData(password: "", account: account)
        XCTAssertNoThrow(try Web3Utils.privateToPublic(key, compressed: true))
        
        let address = keystore.addresses[0]
        
        let options = Web3Options.default
        
        let function = try! SolidityFunction(function: "some(address)")
        let data = function.encode([address])
        var transaction = EthereumTransaction(to: address, data: data, options: options)
        
        XCTAssertNoThrow(try Web3Signer.signTX(transaction: &transaction, keystore: keystore, account: address, password: ""))
        XCTAssertThrowsError(try Web3Signer.signTX(transaction: &transaction, keystore: keystore, account: address, password: "some password"))
    }
}
