//
//  EthereumKeystoreV3.swift
//  web3swift
//
//  Created by Alexander Vlasov on 18.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import Foundation

/**
# Web3 Secret Storage

Used to store your account in json file safely

[https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition](https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition)
*/
public class EthereumKeystoreV3: AbstractKeystore {
	/// - Returns: array of single address or empty array
    public var addresses: [Address] {
        guard let address = address else { return [] }
        return [address]
    }
	
	/// - Returns false
    public var isHDKeystore = false

    /// throws AbstractKeystoreError.invalidPasswordError
    /// throws AbstractKeystoreError.invalidAccountError
    public func UNSAFE_getPrivateKeyData(password: String, account: Address) throws -> Data {
        if addresses.count == 1 && account == addresses.last {
            guard let pk = try? self.getKeyData(password) else { throw AbstractKeystoreError.invalidPasswordError }
            guard let privateKey = pk else { throw AbstractKeystoreError.invalidAccountError }
            return privateKey
        }
        throw AbstractKeystoreError.invalidAccountError
    }

    /// Keystore address
    public private(set) var address: Address?
	/// Keystore Parameters (Json convertible)
    public var keystoreParams: KeystoreParamsV3?

	/// Init with json file
    public convenience init?(_ jsonString: String) {
        self.init(jsonString.lowercased().data)
    }
	
	/// Init with json file
    public convenience init?(_ jsonData: Data) {
        guard let keystoreParams = try? JSONDecoder().decode(KeystoreParamsV3.self, from: jsonData) else { return nil }
        self.init(keystoreParams)
    }
	
	/// Init with decoded keystore parameters
    public init?(_ keystoreParams: KeystoreParamsV3) {
        if keystoreParams.version != 3 { return nil }
        if keystoreParams.crypto.version != nil && keystoreParams.crypto.version != "1" { return nil }
        self.keystoreParams = keystoreParams
        if keystoreParams.address != nil {
            address = Address(keystoreParams.address!.withHex)
        } else {
            return nil
        }
    }
	
	/**
	Creates a new keystore with password and aesMode.
	Clears the private key seed from memory after init
	- Parameter password: Password that would be used to encrypt private key
	- Parameter aesMode: Encryption mode. Allowed: "aes-128-cbc", "aes-128-ctr"
	*/
    public init? (password: String = "BANKEXFOUNDATION", aesMode: String = "aes-128-cbc") throws {
        var newPrivateKey = Data.random(length: 32)
        defer { Data.zero(&newPrivateKey) }
        try encryptDataToStorage(password, keyData: newPrivateKey, aesMode: aesMode)
    }
    
    /// Init with private key. Encrypts key but not clears it from memory.
    ///
    /// - Parameters:
    ///   - privateKey: Private key that would be used for this keystore
    ///   - password: Password that would be used to encrypt private key
    ///   - aesMode: Encryption mode. Allowed: "aes-128-cbc", "aes-128-ctr"
    /// - Throws: Error if password is invalid or
    /// - Important: Don't forget to clear your private key from memory using
    /// ```
    /// Data.zero(&privateKey)
    /// ```
    public init? (privateKey: Data, password: String = "BANKEXFOUNDATION", aesMode: String = "aes-128-cbc") throws {
        guard privateKey.count == 32 else { return nil }
        try SECP256K1.verifyPrivateKey(privateKey: privateKey)
        try encryptDataToStorage(password, keyData: privateKey, aesMode: aesMode)
    }

    fileprivate func encryptDataToStorage(_ password: String, keyData: Data?, dkLen: Int = 32, N: Int = 4096, R: Int = 6, P: Int = 1, aesMode: String = "aes-128-cbc") throws {
        if keyData == nil {
            throw AbstractKeystoreError.encryptionError("Encryption without key data")
        }
        let saltLen = 32
        let saltData = Data.random(length: saltLen)
        guard let derivedKey = scrypt(password: password, salt: saltData, length: dkLen, N: N, R: R, P: P) else { throw AbstractKeystoreError.keyDerivationError }
        let last16bytes = Data(derivedKey[(derivedKey.count - 16) ... (derivedKey.count - 1)])
        let encryptionKey = Data(derivedKey[0 ... 15])
        let IV = Data.random(length: 16)
        var aesCipher: AES!
        switch aesMode {
        case "aes-128-cbc":
            aesCipher = AES(key: encryptionKey.bytes, blockMode: CBC(iv: IV.bytes), padding: .noPadding)
        case "aes-128-ctr":
            aesCipher = AES(key: encryptionKey.bytes, blockMode: CTR(iv: IV.bytes), padding: .noPadding)
        default:
            aesCipher = nil
        }
        guard aesCipher != nil else { throw AbstractKeystoreError.aesError }
        let encryptedKey = try aesCipher.encrypt(keyData!.bytes)
        let encryptedKeyData = Data(bytes: encryptedKey)
        var dataForMAC = Data()
        dataForMAC.append(last16bytes)
        dataForMAC.append(encryptedKeyData)
        let mac = dataForMAC.keccak256()
        let kdfparams = KdfParamsV3(salt: saltData.hex, dklen: dkLen, n: N, p: P, r: R, c: nil, prf: nil)
        let cipherparams = CipherParamsV3(iv: IV.hex)
        let crypto = CryptoParamsV3(ciphertext: encryptedKeyData.hex, cipher: aesMode, cipherparams: cipherparams, kdf: "scrypt", kdfparams: kdfparams, mac: mac.hex, version: nil)
        let pubKey = try Web3Utils.privateToPublic(keyData!)
        let addr = try Web3Utils.publicToAddress(pubKey)
        address = addr
        let keystoreparams = KeystoreParamsV3(address: addr.address.lowercased(), crypto: crypto, id: UUID().uuidString.lowercased(), version: 3)
        keystoreParams = keystoreparams
    }

	/// Updates account password
    public func regenerate(oldPassword: String, newPassword: String, dkLen _: Int = 32, N _: Int = 4096, R _: Int = 6, P _: Int = 1) throws {
        var keyData = try getKeyData(oldPassword)
        if keyData == nil {
            throw AbstractKeystoreError.encryptionError("Failed to decrypt a keystore")
        }
        defer { Data.zero(&keyData!) }
        try encryptDataToStorage(newPassword, keyData: keyData!, aesMode: keystoreParams!.crypto.cipher)
    }

    fileprivate func getKeyData(_ password: String) throws -> Data? {
        guard let keystoreParams = self.keystoreParams else { return nil }
        guard let saltData = Data.fromHex(keystoreParams.crypto.kdfparams.salt) else { return nil }
        let derivedLen = keystoreParams.crypto.kdfparams.dklen
        var passwordDerivedKey: Data?
        switch keystoreParams.crypto.kdf {
        case "scrypt":
            guard let N = keystoreParams.crypto.kdfparams.n else { return nil }
            guard let P = keystoreParams.crypto.kdfparams.p else { return nil }
            guard let R = keystoreParams.crypto.kdfparams.r else { return nil }
            passwordDerivedKey = scrypt(password: password, salt: saltData, length: derivedLen, N: N, R: R, P: P)
        case "pbkdf2":
            guard let algo = keystoreParams.crypto.kdfparams.prf else { return nil }
            let hashVariant = try HmacVariant(algo)
            guard let c = keystoreParams.crypto.kdfparams.c else { return nil }
            guard let derivedArray = try? BetterPBKDF(password: Array(password.utf8), salt: saltData.bytes, iterations: c, keyLength: derivedLen, variant: hashVariant) else { return nil }
            passwordDerivedKey = Data(bytes: derivedArray)
        default:
            return nil
        }
        guard let derivedKey = passwordDerivedKey else { return nil }
        var dataForMAC = Data()
        dataForMAC.append(derivedKey.suffix(16))
        guard let cipherText = Data.fromHex(keystoreParams.crypto.ciphertext) else { return nil }
        if cipherText.count != 32 { return nil }
        dataForMAC.append(cipherText)
        let mac = dataForMAC.keccak256()
        guard let calculatedMac = Data.fromHex(keystoreParams.crypto.mac), mac.constantTimeComparisonTo(calculatedMac) else { return nil }
        let cipher = keystoreParams.crypto.cipher
        let decryptionKey = derivedKey.prefix(16)
        guard let IV = Data.fromHex(keystoreParams.crypto.cipherparams.iv) else { return nil }
        var decryptedPK: Array<UInt8>?
        switch cipher {
        case "aes-128-ctr":
            let aesCipher = AES(key: decryptionKey.bytes, blockMode: CTR(iv: IV.bytes), padding: .noPadding)
            decryptedPK = try aesCipher.decrypt(cipherText.bytes)
        case "aes-128-cbc":
            let aesCipher = AES(key: decryptionKey.bytes, blockMode: CBC(iv: IV.bytes), padding: .noPadding)
            decryptedPK = try aesCipher.decrypt(cipherText.bytes)
        default:
            return nil
        }
        guard decryptedPK != nil else { return nil }
        return Data(bytes: decryptedPK!)
    }
	
	/// Returns json file encoded with v3 standard
    public func serialize() throws -> Data? {
        guard let params = self.keystoreParams else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(params)
        return data
    }
}

/**
 Keystore parameters [v3 compatible](https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition)
 
 Json example:
 ```
 {
 "crypto" : {
 "cipher" : "aes-128-ctr",
 "cipherparams" : {
 "iv" : "6087dab2f9fdbbfaddc31a909735c1e6"
 },
 "ciphertext" : "5318b4d5bcd28de64ee5559e671353e16f075ecae9f99c7a79a38af5f869aa46",
 "kdf" : "pbkdf2",
 "kdfparams" : {
 "c" : 262144,
 "dklen" : 32,
 "prf" : "hmac-sha256",
 "salt" : "ae3cd4e7013836a3df6bd7241b12db061dbe2c6785853cce422d148a624ce0bd"
 },
 "mac" : "517ead924a9d0dc3124507e3393d175ce3ff7c1e96529c6c555ce9e51205e9b2"
 },
 "id" : "3198bc9c-6672-5ab3-d995-4942343ae5b6",
 "version" : 3
 }
 ```
 */
public struct KeystoreParamsV3: Decodable, Encodable {
    var address: String?
    var crypto: CryptoParamsV3
    var id: String?
    var version: Int
    
    /// Init with all params
    public init(address ad: String?, crypto cr: CryptoParamsV3, id i: String, version ver: Int) {
        address = ad?.withoutHex
        crypto = cr
        id = i
        version = ver
    }
}
/// Keystore encryption info
public struct CryptoParamsV3: Decodable, Encodable {
    var ciphertext: String
    var cipher: String
    var cipherparams: CipherParamsV3
    var kdf: String
    var kdfparams: KdfParamsV3
    var mac: String
    var version: String?
}
struct KdfParamsV3: Decodable, Encodable {
    var salt: String
    var dklen: Int
    var n: Int?
    var p: Int?
    var r: Int?
    var c: Int?
    var prf: String?
}
struct CipherParamsV3: Decodable, Encodable {
    var iv: String
}
