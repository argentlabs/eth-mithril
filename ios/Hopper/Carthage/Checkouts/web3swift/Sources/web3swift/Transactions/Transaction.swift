//
//  Transaction.swift
//  web3swift
//
//  Created by Dmitry on 30/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit

//class TransactionBuilder {
//    var nonce: BigUInt?
//    var gasPrice: BigUInt?
//    var gasLimit: BigUInt?
//    var to: Address?
//    var value: BigUInt?
//    var data: Data?
//
//    func complete() -> Promise<Transaction> {
//
//    }
//}

/// Work in progress. Will be released in 2.2 - 2.3
class Transaction {
    var nonce: BigUInt = 0
    var gasPrice: BigUInt
    var gasLimit: BigUInt
    var to: Address
    var value: BigUInt
    var data: Data
    
    init(gasPrice: BigUInt, gasLimit: BigUInt, to: Address, value: BigUInt, data: Data) {
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
    }
    
    func write(to data: TransactionDataWriter) {
        data.append(nonce)
        data.append(gasPrice)
        data.append(gasLimit)
        data.append(to)
        data.append(value)
        data.append(self.data)
    }
    
    func write(networkId: NetworkId, to data: TransactionDataWriter) {
        data.append(networkId.rawValue)
        data.append(0)
        data.append(0)
    }
    
    func sign(using privateKey: PrivateKey, networkId: NetworkId? = nil) throws -> SignedTransaction {
        let data = TransactionDataWriter()
        write(to: data)
        if let networkId = networkId {
            write(networkId: networkId, to: data)
        }
        let hash = data.done().keccak256()
        let signature = try privateKey.sign(hash: hash)
        return SignedTransaction(transaction: self, signature: signature, networkId: networkId)
    }
}

/// Work in progress. Will be released in 2.2
class SignedTransaction {
    let transaction: Transaction
    let signature: Signature
    let networkId: NetworkId?
    init(transaction: Transaction, signature: Signature, networkId: NetworkId?) {
        self.transaction = transaction
        self.signature = signature
        self.networkId = networkId
    }
    
    func data() -> Data {
        let data = TransactionDataWriter()
        transaction.write(to: data)
        if let networkId = networkId?.rawValue {
            data.append(BigUInt(signature.v) + 35 + networkId + networkId)
        } else {
            data.append(BigUInt(signature.v) + 27)
        }
        data.append(signature.r)
        data.append(signature.s)
        return data.done()
    }
}

extension Data {
    private func byte(_ value: Int) -> Data {
        return Data([UInt8(value)])
    }
    func length(offset: Int) -> Data {
        guard !(count == 1 && self[0] < UInt8(offset)) else { return Data() }
        let max = 0x37 + offset
        guard count + offset > max else { return byte(count + offset) }
        let serialized = BigUInt(count).serialize()
        return byte(max + serialized.count) + serialized
    }
}

/// Work in progress. Will be released in 2.2
class TransactionDataWriter {
    private(set) var data: Data
    init() {
        self.data = Data()
    }
    init(data: Data) {
        self.data = data
    }
    
    func append(_ value: BigUInt) {
        _append(value.serialize())
    }
    func append(_ value: Address) {
        _append(value.addressData)
    }
    func _append(_ value: Data) {
        data.append(value.length(offset: 0x80))
        data.append(value)
    }
    func append(_ value: Data) {
        data.append(value.length(offset: 0x80))
        data.append(value)
    }
    
    func done() -> Data {
        data.replaceSubrange(0..<0, with: data.length(offset: 0xc0))
        return data
    }
}
