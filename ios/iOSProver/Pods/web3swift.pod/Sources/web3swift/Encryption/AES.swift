//
//  AES.swift
//  web3swift
//
//  Created by Dmitry on 30/11/2018.
//

import Foundation
import CommonCrypto

//extension Data {
//    var bytes: Array<UInt8> {
//        return Array(self)
//    }
//}

enum AesMode {
    case ctr
    case cbc
    var cc: CCMode {
        switch self {
        case .cbc:
            return CCMode(kCCModeCBC)
        case .ctr:
            return CCMode(kCCModeCTR)
        }
    }
    enum Error: Swift.Error {
        case invalidType(String)
    }
    init(_ string: String) throws {
        switch string {
        case "aes-128-ctr": self = .ctr
        case "aes-128-cbc": self = .cbc
        default: throw Error.invalidType(string)
        }
    }
    func blockMode(_ iv: Data) -> BlockMode {
        switch self {
        case .ctr: return CTR(iv: iv.bytes)
        case .cbc: return CBC(iv: iv.bytes)
        }
    }
}

enum AESPadding {
    case noPadding, pkcs5, pkcs7
    var cc: CCPadding {
        switch self {
        case .noPadding:
            return CCPadding(ccNoPadding)
        case .pkcs5:
            return CCPadding(ccPKCS7Padding)
        case .pkcs7:
            return CCPadding(ccPKCS7Padding)
        }
    }
}
struct BlockMode {
    var mode: AesMode
    var iv: Data
}

func CBC(iv: [UInt8]) -> BlockMode {
    return BlockMode(mode: .cbc, iv: Data(iv))
}
func CTR(iv: [UInt8]) -> BlockMode {
    return BlockMode(mode: .ctr, iv: Data(iv))
}

class AES {
    var blockMode: BlockMode
    var padding: AESPadding
    var key: Data
    init(key: [UInt8], blockMode: BlockMode, padding: AESPadding) {
        self.blockMode = blockMode
        self.padding = padding
        self.key = Data(key)
    }
    
    func encrypt(_ digest: [UInt8]) throws -> [UInt8] {
        return try AES128(key: key, iv: blockMode.iv).encrypt(Data(digest), padding: padding, mode: blockMode.mode).bytes
    }
    func encrypt(_ digest: Data) throws -> Data {
        return try AES128(key: key, iv: blockMode.iv).encrypt(digest, padding: padding, mode: blockMode.mode)
    }
    
    func decrypt(_ digest: [UInt8]) throws -> [UInt8] {
        return try AES128(key: key, iv: blockMode.iv).decrypt(Data(digest), padding: padding, mode: blockMode.mode).bytes
    }
    func decrypt(_ digest: Data) throws -> Data {
        return try AES128(key: key, iv: blockMode.iv).decrypt(digest, padding: padding, mode: blockMode.mode)
    }
}

private extension CCCryptorStatus {
    func check() throws {
        guard self == kCCSuccess else { throw AES128.Error.cryptoFailed(status: self) }
    }
}
private extension Data {
    func pointer(_ body: (UnsafePointer<UInt8>?) throws -> ()) rethrows {
        try withUnsafeBytes(body)
    }
}

//PBKDF.deriveKey(fromPassword: mnemonics.decomposedStringWithCompatibilityMapping, salt: saltData, prf: .sha512, rounds: 2048, derivedKeyLength: 64)
struct AES128 {
    private var key: Data
    private var iv: Data
    
    init(key: Data, iv: Data) throws {
        guard key.count == kCCKeySizeAES128 else {
            throw Error.badKeyLength
        }
        guard iv.count == kCCBlockSizeAES128 else {
            throw Error.badInputVectorLength
        }
        self.key = key
        self.iv = iv
    }
    
    enum Error: Swift.Error {
        case keyGeneration(status: Int)
        case cryptoFailed(status: CCCryptorStatus)
        case badKeyLength
        case badInputVectorLength
    }
    
    func encrypt(_ digest: Data, padding: AESPadding, mode: AesMode) throws -> Data {
        return try crypt(input: digest, operation: CCOperation(kCCEncrypt), padding: padding, mode: mode)
    }
    
    func decrypt(_ encrypted: Data, padding: AESPadding, mode: AesMode) throws -> Data {
        return try crypt(input: encrypted, operation: CCOperation(kCCDecrypt), padding: padding, mode: mode)
    }
    
    private func crypt(input: Data, operation: CCOperation, padding: AESPadding, mode: AesMode) throws -> Data {
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var length = 0
        
        var cryptor: CCCryptorRef!
        try iv.pointer { ivBytes in
            try key.pointer { keyBytes in
                try CCCryptorCreateWithMode(operation, mode.cc, CCAlgorithm(kCCAlgorithmAES128), padding.cc, ivBytes, keyBytes, key.count, nil, 0, 0, CCModeOptions(kCCModeOptionCTR_BE), &cryptor).check()
            }
        }
        try input.pointer { encryptedBytes in
            try CCCryptorUpdate(cryptor, encryptedBytes, input.count, &outBytes, outBytes.count, &outLength).check()
        }
        length += outLength
        try CCCryptorFinal(cryptor, &outBytes + outLength, outBytes.count, &outLength).check()
        length += outLength
        
        return Data(bytes: UnsafePointer<UInt8>(outBytes), count: length)
    }
    
    static func createKey(password: Data, salt: Data) throws -> Data {
        let length = kCCKeySizeAES256
        var status = Int32(0)
        var derivedBytes = [UInt8](repeating: 0, count: length)
        password.withUnsafeBytes { (passwordBytes: UnsafePointer<Int8>!) in
            salt.withUnsafeBytes { (saltBytes: UnsafePointer<UInt8>!) in
                status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),                  // algorithm
                    passwordBytes,                                // password
                    password.count,                               // passwordLen
                    saltBytes,                                    // salt
                    salt.count,                                   // saltLen
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),   // prf
                    10000,                                        // rounds
                    &derivedBytes,                                // derivedKey
                    length)                                       // derivedKeyLen
            }
        }
        guard status == 0 else {
            throw Error.keyGeneration(status: Int(status))
        }
        return Data(bytes: UnsafePointer<UInt8>(derivedBytes), count: length)
    }
    
    static func randomIv() -> Data {
        return randomData(length: kCCBlockSizeAES128)
    }
    
    static func randomSalt() -> Data {
        return randomData(length: 8)
    }
    
    static func randomData(length: Int) -> Data {
        var data = Data(count: length)
        let status = data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }
        assert(status == Int32(0))
        return data
    }
}
