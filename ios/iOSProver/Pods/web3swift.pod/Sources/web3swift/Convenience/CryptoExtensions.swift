//
//  CryptoExtensions.swift
//  web3swift
//
//  Created by Alexander Vlasov on 04.12.2017.
//  Copyright © 2017 Alexander Vlasov. All rights reserved.
//

//import Cryptor
import Foundation

/**
 Scrypt function. Used to generate derivedKey from password, salt, n, r, p
 */


func toByteArray<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafeBytes(of: &value) { Array($0) }
}

enum ScryptError: Error {
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

/// Implementation of the scrypt key derivation function.
private class OldScrypt {
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

    /// Configuration parameters.
    private let salt: Array<UInt8> // S
    private let password: Array<UInt8>
    fileprivate let blocksize: Int // 128 * r
    private let dkLen: Int
    private let N: Int
    private let r: Int
    private let p: Int

    init(password: Array<UInt8>, salt: Array<UInt8>, dkLen: Int, N: Int, r: Int, p: Int) throws {
        precondition(dkLen > 0)
        precondition(N > 0)
        precondition(r > 0)
        precondition(p > 0)

        guard !(N < 2 || (N & (N - 1)) != 0) else { throw ScryptError.nMustBeAPowerOf2GreaterThan1 }

        guard N <= .max / 128 / r else { throw ScryptError.nIsTooLarge }
        guard r <= .max / 128 / p else { throw ScryptError.rIsTooLarge }

        blocksize = 128 * r
        self.N = N
        self.r = r
        self.p = p
        self.password = password
        self.salt = salt
        self.dkLen = dkLen
    }

    /// Runs the key derivation function with a specific password.
    func calculate() throws -> [UInt8] {
        // Allocate memory.
        let B = UnsafeMutableRawPointer.allocate(byteCount: 128 * r * p, alignment: 64)
        let XY = UnsafeMutableRawPointer.allocate(byteCount: 256 * r + 64, alignment: 64)
        let V = UnsafeMutableRawPointer.allocate(byteCount: 128 * r * N, alignment: 64)

        // Deallocate memory when done
        defer {
            B.deallocate()
            XY.deallocate()
            V.deallocate()
        }

        
        /* 1: (B_0 ... B_{p-1}) <-- PBKDF2(P, S, 1, p * MFLen) */
        
        let pw = String(data: Data(password), encoding: .utf8)!
        let barray = try PBKDF.deriveKey(fromPassword: pw, salt: salt, prf: .sha256, rounds: 1, derivedKeyLength: UInt(p * 128 * r))
        
        barray.withUnsafeBytes { p in
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
        let block = [UInt8](bufferPointer)
        return try PBKDF.deriveKey(fromPassword: pw, salt: block, prf: .sha256, rounds: 1, derivedKeyLength: UInt(dkLen))
//        return try PKCS5.PBKDF2(password: password, salt: block, iterations: 1, keyLength: dkLen, variant: .sha256).calculate()
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
        for i in stride(from: 0, to: N, by: 2) {
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
        for _ in stride(from: 0, to: N, by: 2) {
            /* 7: j <-- Integerify(X) mod N */
            var j = Int(integerify(X) & UInt64(N - 1))

            /* 8: X <-- H(X \xor V_j) */
            blockXor(X, v + j * 32 * r, 128 * r)
            blockMixSalsa8(X, Y, Z)

            /* 7: j <-- Integerify(X) mod N */
            j = Int(integerify(Y) & UInt64(N - 1))

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
