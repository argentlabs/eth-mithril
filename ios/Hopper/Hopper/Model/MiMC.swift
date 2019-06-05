//
//  MiMC.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 07/05/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import SwiftKeccak
import BigInt

extension Data {
    init?(fromHexString hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}

class MiMC {
    static let scalarField: BInt = BInt("21888242871839275222246405745257275088548364400416034343698204186575808495617")!
    static let seed: BInt = BInt("82724731331859054037315113496710413141112897654334566532528783843265082629790")! // keccak256("mimc")
    
    static private func bint_keccak256(_ input: BInt) -> BInt {
        let input_hex = input.asString(radix: 16).paddingLeft(toLength: 64, withPad: "0")
        let input_data = Data(fromHexString: input_hex)!
        let output_hex = keccak256(input_data).toHexString()
        return BInt(output_hex, radix: 16)!
    }
    
    static private func mimc_pe_7(in_x: BInt, in_k: BInt, in_seed: BInt, round_count: Int) -> BInt {
        assert(round_count >= 1)
        var c = in_seed
        var x = in_x
        for _ in (1...round_count) {
            c = bint_keccak256(c)
            let t = (x + c + in_k) % scalarField
            x = (t ** 7) % scalarField
        }
        x = (x + in_k) % scalarField
        return x
    }
    
    static private func mimc_pe_7_mp(in_xs: [BInt], in_k: BInt, in_seed: BInt, round_count: Int) -> BInt {
        var r = in_k
        for in_x in in_xs {
            r = (r + in_x + mimc_pe_7(in_x: in_x, in_k: r, in_seed: in_seed, round_count: round_count)) % scalarField
        }
        return r
    }
    
    static func hash(in_msgs: [BInt], in_key: BInt = 0) -> BInt {
        return mimc_pe_7_mp(in_xs: in_msgs, in_k: in_key, in_seed: seed, round_count: 91)
    }
    
    static func hash(in_msgs: [BigUInt], in_key: BigUInt = 0) -> BigUInt {
        let bint_in_msgs: [BInt] = in_msgs.map { BInt($0.description)! }
        let bint_output: BInt = hash(in_msgs: bint_in_msgs, in_key: BInt(in_key.description)!)
        return BigUInt(bint_output)
    }

}

