//
//  BIP32HDwallet.swift
//  web3swift
//
//  Created by Alexander Vlasov on 09.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
//import Cryptor
import Foundation

extension UInt32 {
    /// - Returns: Serialized bigEndian value as Data
    public func serialize32() -> Data {
        var data = Data(count: 4)
        data.withUnsafeMutableBytes { (body: UnsafeMutablePointer<UInt32>) in
            body[0] = bigEndian
        }
        return data
    }
}

private extension Array where Element == UInt8 {
    func checkEntropySize() throws {
        guard count == 64 else { throw HDNode.Error.invalidEntropySize }
    }
}

private extension Data {
    func checkPublicKeyPrefix() throws {
        let prefix = self[0]
        guard prefix == 0x02 || prefix == 0x03 else { throw HDNode.Error.invalidPublicKeyPrefix }
    }
}

/**
 Represents
 */
public class HDNode {
    /// HD version
    public struct HDversion {
        /// Private key prefix. Default: 0x0488ADE4
        public var privatePrefix = "0x0488ADE4".hex
        /// Public key prefix. Default: 0x0488B21E
        public var publicPrefix = "0x0488B21E".hex
        /// Init with default values
        public init() {}
    }
    
    /// Current path
    public var path: String? = "m"
    /// Private key
    public var privateKey: Data?
    /// Public Key
    public var publicKey: Data
    /// Chain code
    public var chaincode: Data
    /// Current depth
    public var depth: UInt8
    /// Parent 4 byte RIPEMD160 hash prefix
    public var parentFingerprint: Data = Data(repeating: 0, count: 4)
    /// Child number
    public var childNumber: UInt32 = 0
    
    /// Returns true if childNumber is greater than Int32.max
    public var isHardened: Bool {
        return childNumber >= HDNode.hardenedIndexPrefix
    }
    
    /// Returns isHardened ? childNumber - HDNode.hardenedIndexPrefix : childNumber
    public var index: UInt32 {
        return isHardened ? childNumber - HDNode.hardenedIndexPrefix : childNumber
    }

    /// Returns privateKey != nil
    public var hasPrivate: Bool {
        return privateKey != nil
    }

    init() {
        publicKey = Data()
        chaincode = Data()
        depth = UInt8(0)
    }

    /// Init with Base58 encoded string
    public convenience init?(_ serializedString: String) {
        let data = Data(Base58.bytesFromBase58(serializedString))
        self.init(data)
    }
    
    /// Init with binary represented HDNode
    public init?(_ data: Data) {
        guard data.count == 82 else { return nil }
        let header = data[0 ..< 4]
        var serializePrivate = false
        if header == HDNode.HDversion().privatePrefix {
            serializePrivate = true
        }
        depth = data[4 ..< 5].bytes[0]
        parentFingerprint = data[5 ..< 9]
        let cNum = data[9 ..< 13].bytes
        childNumber = UnsafePointer(cNum).withMemoryRebound(to: UInt32.self, capacity: 1) {
            $0.pointee
        }
        chaincode = data[13 ..< 45]
        if serializePrivate {
            privateKey = data[46 ..< 78]
            guard let pubKey = try? Web3Utils.privateToPublic(privateKey!, compressed: true) else { return nil }
            guard pubKey[0] == 0x02 || pubKey[0] == 0x03 else { return nil }
            publicKey = pubKey
        } else {
            publicKey = data[45 ..< 78]
        }
        let hashedData = data[0 ..< 78].sha256().sha256()
        let checksum = hashedData[0 ..< 4]
        if checksum != data[78 ..< 82] { return nil }
    }
    
    /// HDNode errors
    public enum Error: Swift.Error {
        /// Seed size should be at least 16 bytes
        case invalidSeedSize
        /// Entropy size should be 64 bytes
        case invalidEntropySize
        /// Public key should start with 0x02 or 0x03
        case invalidPublicKeyPrefix
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case .invalidSeedSize:
                return "Seed size should be at least 16 bytes"
            case .invalidEntropySize:
                return "Entropy size should be 64 bytes"
            case .invalidPublicKeyPrefix:
                return "Public key should start with 0x02 or 0x03"
            }
        }
    }
    
    /// Init with seed
    public init(seed: Data) throws {
        guard seed.count >= 16 else { throw Error.invalidSeedSize }
        let hmacKey = "Bitcoin seed".data(using: .ascii)!
        let hmac = HMAC(key: hmacKey.bytes, variant: .sha512)
        let entropy = try hmac.authenticate(seed.bytes)
        try entropy.checkEntropySize()
        let I_L = entropy[0 ..< 32]
        let I_R = entropy[32 ..< 64]
        chaincode = Data(I_R)
        let privKeyCandidate = Data(I_L)
        try SECP256K1.verifyPrivateKey(privateKey: privKeyCandidate)
        let pubKeyCandidate = try SECP256K1.privateToPublic(privateKey: privKeyCandidate, compressed: true)
        guard pubKeyCandidate[0] == 0x02 || pubKeyCandidate[0] == 0x03 else { throw Error.invalidPublicKeyPrefix }
        publicKey = pubKeyCandidate
        privateKey = privKeyCandidate
        depth = 0x00
        childNumber = UInt32(0)
    }

    private static var curveOrder = BigUInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
    
    /// "m/44'/60'/0'/0"
    public static var defaultPath: String = "m/44'/60'/0'/0"
    /// "m/44'/60'/0'"
    public static var defaultPathPrefix: String = "m/44'/60'/0'"
    /// "m/44'/60'/0'/0/0"
    public static var defaultPathMetamask: String = "m/44'/60'/0'/0/0"
    /// "m/44'/60'/0'/0"
    public static var defaultPathMetamaskPrefix: String = "m/44'/60'/0'/0"
    /// 1 << 31 or UInt32(Int32.max) + 1
    public static var hardenedIndexPrefix: UInt32 = (UInt32(1) << 31)

    /// Derive Errors
    public enum DeriveError: Swift.Error {
        /// You have to provide a private key if you want to derive private key
        case providePrivateKey
        
        /// Provided index is too big
        case indexIsTooBig
        
        /// Depth shouldn't be deeper than 254 levels
        case depthIsTooBig
        
        /// Cannot derive public key in hardened mode
        case noHardenedDerivation
        
        /// Cannot derive public key in hardened mode
        case pathComponentsShouldBeConvertibleToNumber
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case .providePrivateKey:
                return "You have to provide a private key"
            case .indexIsTooBig:
                return "Provided index is too big"
            case .depthIsTooBig:
                return "Depth shouldn't be deeper than 254 levels"
            case .noHardenedDerivation:
                return "Cannot derive public key in hardened mode"
            case .pathComponentsShouldBeConvertibleToNumber:
                return "HDPath index should should be convertible"
            }
        }
    }
    
    /// Returns HDNode with new index
    public func derive(index: UInt32, derivePrivateKey: Bool, hardened: Bool = false) throws -> HDNode {
        if derivePrivateKey {
            guard hasPrivate else { throw DeriveError.providePrivateKey }
            let entropy: Array<UInt8>
            var trueIndex: UInt32
            if index >= HDNode.hardenedIndexPrefix || hardened {
                trueIndex = index
                if trueIndex < HDNode.hardenedIndexPrefix {
                    trueIndex = trueIndex + HDNode.hardenedIndexPrefix
                }
                let hmac = HMAC(key: chaincode.bytes, variant: .sha512)
                var inputForHMAC = Data()
                inputForHMAC.append(Data([UInt8(0x00)]))
                inputForHMAC.append(privateKey!)
                inputForHMAC.append(trueIndex.serialize32())
                entropy = try hmac.authenticate(inputForHMAC.bytes)
                try entropy.checkEntropySize()
            } else {
                trueIndex = index
                let hmac = HMAC(key: chaincode.bytes, variant: .sha512)
                var inputForHMAC = Data()
                inputForHMAC.append(publicKey)
                inputForHMAC.append(trueIndex.serialize32())
                entropy = try hmac.authenticate(inputForHMAC.bytes)
                try entropy.checkEntropySize()
            }
            let I_L = entropy[0 ..< 32]
            let I_R = entropy[32 ..< 64]
            let cc = Data(I_R)
            let bn = BigUInt(Data(I_L))
            if bn > HDNode.curveOrder {
                guard trueIndex != UInt32.max else { throw DeriveError.indexIsTooBig }
                return try derive(index: index + 1, derivePrivateKey: derivePrivateKey, hardened: hardened)
            }
            let newPK = (bn + BigUInt(privateKey!)) % HDNode.curveOrder
            if newPK == BigUInt(0) {
                guard trueIndex != UInt32.max else { throw DeriveError.indexIsTooBig }
                return try derive(index: index + 1, derivePrivateKey: derivePrivateKey, hardened: hardened)
            }
            let privKeyCandidate = newPK.serialize().setLengthLeft(32)!
            try SECP256K1.verifyPrivateKey(privateKey: privKeyCandidate)
            let pubKeyCandidate = try SECP256K1.privateToPublic(privateKey: privKeyCandidate, compressed: true)
            try pubKeyCandidate.checkPublicKeyPrefix()
            guard depth < UInt8.max else { throw DeriveError.depthIsTooBig }
            let newNode = HDNode()
            newNode.chaincode = cc
            newNode.depth = depth + 1
            newNode.publicKey = pubKeyCandidate
            newNode.privateKey = privKeyCandidate
            newNode.childNumber = trueIndex
            let fprint = RIPEMD160.hash(message: publicKey.sha256())[0 ..< 4]
            newNode.parentFingerprint = fprint
            var newPath = String()
            if newNode.isHardened {
                newPath = path! + "/"
                newPath += String(newNode.index % HDNode.hardenedIndexPrefix) + "'"
            } else {
                newPath = path! + "/" + String(newNode.index)
            }
            newNode.path = newPath
            return newNode
        } else { // deriving only the public key
            guard !(index >= HDNode.hardenedIndexPrefix || hardened) else { throw DeriveError.noHardenedDerivation }
            let hmac = HMAC(key: self.chaincode.bytes, variant: .sha512)
            var inputForHMAC = Data()
            inputForHMAC.append(publicKey)
            inputForHMAC.append(index.serialize32())
            var entropy = try hmac.authenticate(inputForHMAC.bytes) // derive public key when is itself public key
            try entropy.checkEntropySize()
            let tempKey = Data(entropy[0 ..< 32])
            let chaincode = Data(entropy[32 ..< 64])
            let bn = BigUInt(tempKey)
            if bn > HDNode.curveOrder {
                guard index < UInt32.max else { throw DeriveError.indexIsTooBig }
                return try derive(index: index + 1, derivePrivateKey: derivePrivateKey, hardened: hardened)
            }
            try SECP256K1.verifyPrivateKey(privateKey: tempKey)
            let pubKeyCandidate = try SECP256K1.privateToPublic(privateKey: tempKey, compressed: true)
            try pubKeyCandidate.checkPublicKeyPrefix()
            let newPublicKey = try SECP256K1.combineSerializedPublicKeys(keys: [self.publicKey, pubKeyCandidate], outputCompressed: true)
            try newPublicKey.checkPublicKeyPrefix()
            guard depth < UInt8.max else { throw DeriveError.depthIsTooBig }
            let newNode = HDNode()
            newNode.chaincode = chaincode
            newNode.depth = depth + 1
            newNode.publicKey = pubKeyCandidate
            newNode.childNumber = index
            let fprint = RIPEMD160.hash(message: publicKey.sha256())[0 ..< 4]
            newNode.parentFingerprint = fprint
            var newPath = String()
            if newNode.isHardened {
                newPath = path! + "/"
                newPath += String(newNode.index % HDNode.hardenedIndexPrefix) + "'"
            } else {
                newPath = path! + "/" + String(newNode.index)
            }
            newNode.path = newPath
            return newNode
        }
    }
    
    /// Returns HDNode with appended path
    public func derive(path: String, derivePrivateKey: Bool = true) throws -> HDNode {
        let components = path.components(separatedBy: "/")
        var currentNode: HDNode = self
        var firstComponent = 0
        if path.hasPrefix("m") {
            firstComponent = 1
        }
        for component in components[firstComponent ..< components.count] {
            var component = component
            let hardened = component.hasSuffix("'")
            if hardened {
                component.removeLast()
            }
            guard let index = UInt32(component) else { throw DeriveError.pathComponentsShouldBeConvertibleToNumber }
            currentNode = try currentNode.derive(index: index, derivePrivateKey: derivePrivateKey, hardened: hardened)
        }
        return currentNode
    }
    
    /// Base58 string representation of HDNode's data
    public func serializeToString(serializePublic: Bool = true, version: HDversion = HDversion()) -> String? {
        guard let data = self.serialize(serializePublic: serializePublic, version: version) else { return nil }
        let encoded = Base58.base58FromBytes(data.bytes)
        return encoded
    }
    
    /// Data representation of HDNode
    public func serialize(serializePublic: Bool = true, version: HDversion = HDversion()) -> Data? {
        var data = Data()
        if !serializePublic && !hasPrivate { return nil }
        if serializePublic {
            data.append(version.publicPrefix)
        } else {
            data.append(version.privatePrefix)
        }
        data.append(contentsOf: [self.depth])
        data.append(parentFingerprint)
        data.append(childNumber.serialize32())
        data.append(chaincode)
        if serializePublic {
            data.append(publicKey)
        } else {
            data.append(contentsOf: [0x00])
            data.append(privateKey!)
        }
        let hashedData = data.sha256().sha256()
        let checksum = hashedData[0 ..< 4]
        data.append(checksum)
        return data
    }
}
