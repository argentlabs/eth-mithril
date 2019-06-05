//
//  Encryption.swift
//  web3swift
//
//  Created by Dmitry on 27/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

protocol DerivedKey {
    func calculate(password: Data) throws -> Data
}

enum DecryptionError: Error {
    case invalidPassword
}

enum DerivedKeyType {
    enum Error: Swift.Error {
        case invalidType(String)
    }
    case scrypt
    case pbkdf2
    init(_ type: String) throws {
        switch type {
        case "scrypt": self = .scrypt
        case "pbkdf2": self = .pbkdf2
        default: throw Error.invalidType(type)
        }
    }
    func derivedKey(_ json: AnyReader) throws -> DerivedKey {
        switch self {
        case .scrypt: return try Scrypt(json: json)
        case .pbkdf2: return try PBKDF2Object(json: json)
        }
    }
}

//extension HMAC.Variant {
//    init(_ string: String) throws {
//        switch string {
//        case "hmac-sha256":
//            self = HMAC.Variant.sha256
//        case "hmac-sha384":
//            self = HMAC.Variant.sha384
//        case "hmac-sha512":
//            self = HMAC.Variant.sha512
//        default:
//            throw PBKDF2Object.Error.unknownHmacAlgorithm(string)
//        }
//    }
//    var digestLength: Int {
//        switch self {
//        case .sha1:
//            return 20
//        case .sha256:
//            return SHA2.Variant.sha256.digestLength
//        case .sha384:
//            return SHA2.Variant.sha384.digestLength
//        case .sha512:
//            return SHA2.Variant.sha512.digestLength
//        case .md5:
//            return 16
//        }
//    }
//}


enum HmacVariant {
    case sha1, sha224, sha256, sha384, sha512
    var cc: PBKDF.PseudoRandomAlgorithm {
        switch self {
        case .sha1: return .sha1
        case .sha224: return .sha224
        case .sha256: return .sha256
        case .sha384: return .sha384
        case .sha512: return .sha512
        }
    }
    var c: HMAC.Algorithm {
        switch self {
        case .sha1: return .sha1
        case .sha224: return .sha224
        case .sha256: return .sha256
        case .sha384: return .sha384
        case .sha512: return .sha512
        }
    }
    
    init(_ string: String) throws {
        switch string {
        case "hmac-sha256":
            self = HmacVariant.sha256
        case "hmac-sha384":
            self = HmacVariant.sha384
        case "hmac-sha512":
            self = HmacVariant.sha512
        default:
            throw PBKDF2Object.Error.unknownHmacAlgorithm(string)
        }
    }
    var digestLength: Int {
        switch self {
        case .sha1:
            return 160 / 8
        case .sha224:
            return 224 / 8
        case .sha256:
            return 256 / 8
        case .sha384:
            return 384 / 8
        case .sha512:
            return 512 / 8
        }
    }
}

extension HMAC {
    enum HMACError: Error {
        case authenticationFailed
    }
    convenience init(key: [UInt8], variant: HmacVariant) {
        self.init(using: variant.c, key: Data(key))
    }
    func authenticate(_ bytes: [UInt8]) throws -> [UInt8] {
        if let data = update(byteArray: bytes)?.final() {
            return data
        } else {
            throw HMACError.authenticationFailed
        }
    }
}
func BetterPBKDF(password: [UInt8], salt: [UInt8], iterations: Int, keyLength: Int, variant: HmacVariant) throws -> [UInt8] {
    let string = String(bytes: password, encoding: .utf8)!
    return try PBKDF.deriveKey(fromPassword: string, salt: salt, prf: variant.cc, rounds: UInt32(iterations), derivedKeyLength: UInt(keyLength))
}

class PBKDF2Object: DerivedKey {
    enum Error: Swift.Error {
        case unknownHmacAlgorithm(String)
        case invalidParameters
        var localizedDescription: String {
            switch self {
            case let .unknownHmacAlgorithm(string):
                return "Unknown hmac algorithm \"\(string)\". Allowed: hmac-sha256, hmac-sha384, hmac-sha512"
            case .invalidParameters:
                return "Cannot load PBKDF2 with provided parameters"
            }
        }
    }
    let variant: HmacVariant
    let keyLength: Int
    let iterations: Int
    let salt: [UInt8]
    
    init(salt: Data, iterations: Int, keyLength: Int, variant: HmacVariant) {
        self.salt = Array(salt)
        self.keyLength = keyLength
        self.iterations = iterations
        self.variant = variant
    }
    init(json: AnyReader) throws {
        variant = try HmacVariant(json.at("prf").string())
        keyLength = try json.at("dklen").int()
        iterations = try json.at("c").int()
        salt = try Array(json.at("salt").data())
        guard iterations > 0 && !salt.isEmpty else { throw Error.invalidParameters }
        if Double(keyLength) > (pow(2, 32) - 1) * Double(variant.digestLength) {
            throw Error.invalidParameters
        }
    }
    
    func calculate(password: Data) throws -> Data {
        do {
            return try Data(BetterPBKDF(password: Array(password), salt: Array(salt), iterations: iterations, keyLength: keyLength, variant: variant))
        } catch {
            throw DecryptionError.invalidPassword
        }
    }
}


/**
 Scrypt function. Used to generate derivedKey from password, salt, n, r, p
 */
class Scrypt: DerivedKey {
    enum ScryptError: Swift.Error {
        case nIsTooLarge
        case rIsTooLarge
        case nMustBeAPowerOf2GreaterThan1
        
        var localizedDescription: String {
            switch self {
            case .nIsTooLarge:
                return "Scrypt error: N is too large"
            case .rIsTooLarge:
                return "Scrypt error: R is too large"
            case .nMustBeAPowerOf2GreaterThan1:
                return "Scrypt error: N must be a power of two and greater than 1"
            }
        }
    }
    enum Error: Swift.Error {
        case invalidPassword
        case invalidSalt
        var localizedDescription: String {
            switch self {
            case .invalidPassword:
                return "Scrypt error: invalid password"
            case .invalidSalt:
                return "Scrypt error: invalid salt"
            }
        }
    }
    
    let salt: Data // S
    let dkLen: Int
    let n: Int
    let r: Int
    let p: Int
    
    init(salt: Data, dkLen: Int, N: Int, r: Int, p: Int) throws {
        guard !(N < 2 || (N & (N - 1)) != 0) else { throw ScryptError.nMustBeAPowerOf2GreaterThan1 }
        
        guard N <= .max / 128 / r else { throw ScryptError.nIsTooLarge }
        guard r <= .max / 128 / p else { throw ScryptError.rIsTooLarge }
        
        self.n = N
        self.r = r
        self.p = p
        self.salt = salt
        self.dkLen = dkLen
    }
    init(json: AnyReader) throws {
        dkLen = try json.at("dklen").int()
        n = try json.at("n").int()
        r = try json.at("r").int()
        p = try json.at("p").int()
        salt = try json.at("salt").data()
    }
    
    /// Runs the key derivation function with a specific password.
    func calculate(password: Data) throws -> Data {
        // Allocate memory.
        let B = UnsafeMutableRawPointer.allocate(byteCount: 128 * r * p, alignment: 64)
        let XY = UnsafeMutableRawPointer.allocate(byteCount: 256 * r + 64, alignment: 64)
        let V = UnsafeMutableRawPointer.allocate(byteCount: 128 * r * n, alignment: 64)
        
        // Deallocate memory when done
        defer {
            B.deallocate()
            XY.deallocate()
            V.deallocate()
        }
        
        /* 1: (B_0 ... B_{p-1}) <-- PBKDF2(P, S, 1, p * MFLen) */
        let barray = try PBKDF2Object(salt: salt, iterations: 1, keyLength: p * 128 * r, variant: .sha256).calculate(password: password)
        
        Array(barray).withUnsafeBytes { p in
            B.copyMemory(from: p.baseAddress!, byteCount: barray.count)
        }
        
        /* 2: for i = 0 to p - 1 do */
        for i in 0 ..< p {
            /* 3: B_i <-- MF(B_i, N) */
            smix(B + i * 128 * r, V.assumingMemoryBound(to: UInt32.self), XY.assumingMemoryBound(to: UInt32.self))
        }
        
        /* 5: DK <-- PBKDF2(P, B, 1, dkLen) */
        let pointer = B.assumingMemoryBound(to: UInt8.self)
        let bufferPointer = UnsafeBufferPointer(start: pointer, count: p * 128 * r)
        let block = Data(buffer: bufferPointer)
        return try PBKDF2Object(salt: block, iterations: 1, keyLength: dkLen, variant: .sha256).calculate(password: password)
    }
    
    /// Computes `B = SMix_r(B, N)`.
    ///
    /// The input `block` must be `128*r` bytes in length; the temporary storage `v` must be `128*r*n` bytes in length;
    /// the temporary storage `xy` must be `256*r + 64` bytes in length. The arrays `block`, `v`, and `xy` must be
    /// aligned to a multiple of 64 bytes.
    private func smix(_ block: UnsafeMutableRawPointer, _ v: UnsafeMutablePointer<UInt32>, _ xy: UnsafeMutablePointer<UInt32>) {
        let X = xy
        let Y = xy + 32 * r
        let Z = xy + 64 * r
        
        /* 1: X <-- B */
        for k in 0 ..< 32 * r {
            X[k] = (block + 4 * k).load(as: UInt32.self)
        }
        
        
        /* 2: for i = 0 to N - 1 do */
        for i in stride(from: 0, to: n, by: 2) {
            /* 3: V_i <-- X */
            UnsafeMutableRawPointer(v + i * (32 * r)).copyMemory(from: X, byteCount: 128 * r)
            
            
            /* 4: X <-- H(X) */
            blockMixSalsa8(X, Y, Z)
            
            /* 3: V_i <-- X */
            UnsafeMutableRawPointer(v + (i + 1) * (32 * r)).copyMemory(from: Y, byteCount: 128 * r)
            
            /* 4: X <-- H(X) */
            blockMixSalsa8(Y, X, Z)
        }
        
        /* 6: for i = 0 to N - 1 do */
        for _ in stride(from: 0, to: n, by: 2) {
            /* 7: j <-- Integerify(X) mod N */
            var j = Int(integerify(X) & UInt64(n - 1))
            
            /* 8: X <-- H(X \xor V_j) */
            blockXor(X, v + j * 32 * r, 128 * r)
            blockMixSalsa8(X, Y, Z)
            
            /* 7: j <-- Integerify(X) mod N */
            j = Int(integerify(Y) & UInt64(n - 1))
            
            /* 8: X <-- H(X \xor V_j) */
            blockXor(Y, v + j * 32 * r, 128 * r)
            blockMixSalsa8(Y, X, Z)
        }
        
        /* 10: B' <-- X */
        for k in 0 ..< 32 * r {
            UnsafeMutableRawPointer(block + 4 * k).storeBytes(of: X[k], as: UInt32.self)
        }
    }
    
    /// Returns the result of parsing `B_{2r-1}` as a little-endian integer.
    private func integerify(_ block: UnsafeRawPointer) -> UInt64 {
        let bi = block + (2 * r - 1) * 64
        return bi.load(as: UInt64.self)
    }
    
    /// Compute `bout = BlockMix_{salsa20/8, r}(bin)`.
    ///
    /// The input `bin` must be `128*r` bytes in length; the output `bout` must also be the same size. The temporary
    /// space `x` must be 64 bytes.
    private func blockMixSalsa8(_ bin: UnsafePointer<UInt32>, _ bout: UnsafeMutablePointer<UInt32>, _ x: UnsafeMutablePointer<UInt32>) {
        UnsafeMutableRawPointer(x).copyMemory(from: bin + (2 * r - 1) * 16, byteCount: 64)
        for i in stride(from: 0, to: 2 * r, by: 2) {
            blockXor(x, bin + i * 16, 64)
            salsa20_8(x)
            UnsafeMutableRawPointer(bout + i * 8).copyMemory(from: x, byteCount: 64)
            
            blockXor(x, bin + i * 16 + 16, 64)
            salsa20_8(x)
            UnsafeMutableRawPointer(bout + i * 8 + r * 16).copyMemory(from: x, byteCount: 64)
        }
    }
    
    @inline(__always)
    func rotate(_ a: UInt32, _ b: UInt32) -> UInt32 {
        return (a << b) | (a >> (32 - b))
    }
    
    /// Applies the salsa20/8 core to the provided block.
    private func salsa20_8(_ block: UnsafeMutablePointer<UInt32>) {
        var x0 = block[0]
        var x1 = block[1]
        var x2 = block[2]
        var x3 = block[3]
        var x4 = block[4]
        var x5 = block[5]
        var x6 = block[6]
        var x7 = block[7]
        var x8 = block[8]
        var x9 = block[9]
        var x10 = block[10]
        var x11 = block[11]
        var x12 = block[12]
        var x13 = block[13]
        var x14 = block[14]
        var x15 = block[15]
        
        for _ in 0 ..< 4 {
            x4 ^= rotate(x0 &+ x12, 7)
            x8 ^= rotate(x4 &+ x0, 9)
            x12 ^= rotate(x8 &+ x4, 13)
            x0 ^= rotate(x12 &+ x8, 18)
            x9 ^= rotate(x5 &+ x1, 7)
            x13 ^= rotate(x9 &+ x5, 9)
            x1 ^= rotate(x13 &+ x9, 13)
            x5 ^= rotate(x1 &+ x13, 18)
            x14 ^= rotate(x10 &+ x6, 7)
            x2 ^= rotate(x14 &+ x10, 9)
            x6 ^= rotate(x2 &+ x14, 13)
            x10 ^= rotate(x6 &+ x2, 18)
            x3 ^= rotate(x15 &+ x11, 7)
            x7 ^= rotate(x3 &+ x15, 9)
            x11 ^= rotate(x7 &+ x3, 13)
            x15 ^= rotate(x11 &+ x7, 18)
            x1 ^= rotate(x0 &+ x3, 7)
            x2 ^= rotate(x1 &+ x0, 9)
            x3 ^= rotate(x2 &+ x1, 13)
            x0 ^= rotate(x3 &+ x2, 18)
            x6 ^= rotate(x5 &+ x4, 7)
            x7 ^= rotate(x6 &+ x5, 9)
            x4 ^= rotate(x7 &+ x6, 13)
            x5 ^= rotate(x4 &+ x7, 18)
            x11 ^= rotate(x10 &+ x9, 7)
            x8 ^= rotate(x11 &+ x10, 9)
            x9 ^= rotate(x8 &+ x11, 13)
            x10 ^= rotate(x9 &+ x8, 18)
            x12 ^= rotate(x15 &+ x14, 7)
            x13 ^= rotate(x12 &+ x15, 9)
            x14 ^= rotate(x13 &+ x12, 13)
            x15 ^= rotate(x14 &+ x13, 18)
        }
        block[0] = block[0] &+ x0
        block[1] = block[1] &+ x1
        block[2] = block[2] &+ x2
        block[3] = block[3] &+ x3
        block[4] = block[4] &+ x4
        block[5] = block[5] &+ x5
        block[6] = block[6] &+ x6
        block[7] = block[7] &+ x7
        block[8] = block[8] &+ x8
        block[9] = block[9] &+ x9
        block[10] = block[10] &+ x10
        block[11] = block[11] &+ x11
        block[12] = block[12] &+ x12
        block[13] = block[13] &+ x13
        block[14] = block[14] &+ x14
        block[15] = block[15] &+ x15
    }
    
    private func blockXor(_ dest: UnsafeMutableRawPointer, _ src: UnsafeRawPointer, _ len: Int) {
        let D = dest.assumingMemoryBound(to: UInt.self)
        let S = src.assumingMemoryBound(to: UInt.self)
        let L = len / MemoryLayout<UInt>.size
        
        for i in 0 ..< L {
            D[i] ^= S[i]
        }
    }
}
