//
//  BloomFilter.swift
//  web3swift
//
//  Created by Alexander Vlasov on 02.03.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Ethereum bloom filter
public struct EthereumBloomFilter {
    /// Bloom data
    public var bytes = Data(count: 256)
    
    /// Init with number
    public init?(_ biguint: BigUInt) {
        guard let data = biguint.serialize().setLengthLeft(256) else { return nil }
        bytes = data
    }

    /// Init with empty data
    public init() {}
    
    /// Init with data
    public init(_ data: Data) {
        let padding = Data(count: 256 - data.count)
        bytes = padding + data
    }
    /// Serialize to uint256
    public func asBigUInt() -> BigUInt {
        return BigUInt(bytes)
    }
    
    static func bloom9(_ biguint: BigUInt) -> BigUInt {
        return EthereumBloomFilter.bloom9(biguint.serialize())
    }

    static func bloom9(_ data: Data) -> BigUInt {
        var b = data.keccak256()
        var r = BigUInt(0)
        let mask = BigUInt(2047)
        for i in stride(from: 0, to: 6, by: 2) {
            var t = BigUInt(1)
            let num = (BigUInt(b[i + 1]) + (BigUInt(b[i]) << 8)) & mask
//            b = num.serialize().setLengthLeft(8)!
            t = t << num
            r = r | t
        }
        return r
    }

    static func logsToBloom(_ logs: [EventLog]) -> BigUInt {
        var bin = BigUInt(0)
        for log in logs {
            bin = bin | bloom9(log.address.addressData)
            for topic in log.topics {
                bin = bin | bloom9(topic)
            }
        }
        return bin
    }

    /// Creates bloom filter for transaction receipts
    public static func createBloom(_ receipts: [TransactionReceipt]) -> EthereumBloomFilter? {
        var bin = BigUInt(0)
        for receipt in receipts {
            bin = bin | EthereumBloomFilter.logsToBloom(receipt.logs)
        }
        return EthereumBloomFilter(bin)
    }
    
    /// Tests topic
    public func test(topic: Data) -> Bool {
        let bin = asBigUInt()
        let comparison = EthereumBloomFilter.bloom9(topic)
        return bin & comparison == comparison
    }
    
    /// Tests topic
    public func test(topic: BigUInt) -> Bool {
        return test(topic: topic.serialize())
    }
    
    /// Adds number to bloom
    public mutating func add(_ biguint: BigUInt) {
        var bin = BigUInt(bytes)
        bin = bin | EthereumBloomFilter.bloom9(biguint)
        setBytes(bin.serialize())
    }
    
    /// Adds data to bloom
    public mutating func add(_ data: Data) {
        var bin = BigUInt(bytes)
        bin = bin | EthereumBloomFilter.bloom9(data)
        setBytes(bin.serialize())
    }
    

    mutating func setBytes(_ data: Data) {
        if bytes.count < data.count {
            fatalError("bloom bytes are too big")
        }
        bytes = bytes[0 ..< data.count] + data
    }
}
