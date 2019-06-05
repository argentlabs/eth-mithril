//
//  OutputParameters.swift
//  web3swift
//
//  Created by Dmitry on 20/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

public class SyncingStatus {
    public let startingBlock: Int
    public let currentBlock: Int
    public let highestBlock: Int
    public init?(_ data: AnyReader) throws {
        startingBlock = try data.at("startingBlock").int()
        currentBlock = try data.at("currentBlock").int()
        highestBlock = try data.at("highestBlock").int()
    }
}
public class BlockInfo {
    /// null when its pending block.
    public let processed: ProcessedBlockInfo?
    /// parentHash: DATA, 32 Bytes - hash of the parent block.
    public let parentHash: Data
    /// sha3Uncles: DATA, 32 Bytes - SHA3 of the uncles data in the block.
    public let sha3Uncles: Data
    /// transactionsRoot: DATA, 32 Bytes - the root of the transaction trie of the block.
    public let transactionsRoot: Data
    /// stateRoot: DATA, 32 Bytes - the root of the final state trie of the block.
    public let stateRoot: Data
    /// receiptsRoot: DATA, 32 Bytes - the root of the receipts trie of the block.
    public let receiptsRoot: Data
    /// miner: DATA, 20 Bytes - the address of the beneficiary to whom the mining rewards were given.
    public let miner: Address
    /// difficulty: QUANTITY - integer of the difficulty for this block.
    public let difficulty: BigUInt
    /// totalDifficulty: QUANTITY - integer of the total difficulty of the chain until this block.
    public let totalDifficulty: BigUInt
    /// extraData: DATA - the "extra data" field of this block.
    public let extraData: Data
    /// size: QUANTITY - integer the size of this block in bytes.
    public let size: BigUInt
    /// gasLimit: QUANTITY - the maximum gas allowed in this block.
    public let gasLimit: BigUInt
    /// gasUsed: QUANTITY - the total used gas by all transactions in this block.
    public let gasUsed: BigUInt
    /// timestamp: QUANTITY - the unix timestamp for when the block was collated.
    public let timestamp: BigUInt
    /// transactions: Array - Array of transaction objects, or 32 Bytes transaction hashes depending on the last given parameter.
    public let transactions: [TransactionInfo]
    /// uncles: Array - Array of uncle hashes.
    public let uncles: [Data]
    public init(_ json: AnyReader) throws {
        processed = try? ProcessedBlockInfo(json)
        parentHash = try json.at("parentHash").data()
        sha3Uncles = try json.at("sha3Uncles").data()
        transactionsRoot = try json.at("transactionsRoot").data()
        stateRoot = try json.at("stateRoot").data()
        receiptsRoot = try json.at("receiptsRoot").data()
        miner = try json.at("miner").address()
        difficulty = try json.at("difficulty").uint256()
        totalDifficulty = try json.at("totalDifficulty").uint256()
        extraData = try json.at("extraData").data()
        size = try json.at("size").uint256()
        gasLimit = try json.at("gasLimit").uint256()
        gasUsed = try json.at("gasUsed").uint256()
        timestamp = try json.at("timestamp").uint256()
        transactions = try json.at("transactions").array(TransactionInfo.init)
        uncles = try json.at("uncles").array(_data)
    }
}
public class ProcessedBlockInfo {
    /// number: QUANTITY - the block number. null when its pending block.
    public let number: Int
    /// hash: DATA, 32 Bytes - hash of the block. null when its pending block.
    public let hash: Data
    /// nonce: DATA, 8 Bytes - hash of the generated proof-of-work. null when its pending block.
    public let nonce: UInt64
    /// logsBloom: DATA, 256 Bytes - the bloom filter for the logs of the block. null when its pending block.
    public let logsBloom: Data
    public init(_ json: AnyReader) throws {
        number = try json.at("number").int()
        hash = try json.at("hash").data()
        nonce = try json.at("nonce").uint64()
        logsBloom = try json.at("logsBloom").data()
    }
}
public class TransactionInfo {
    /// null when its pending.
    public let processed: ProcessedTransactionInfo?
    
    /// hash: DATA, 32 Bytes - hash of the transaction.
    public let hash: Data
    
    /// from: DATA, 20 Bytes - address of the sender.
    public let from: Address
    /// gas: QUANTITY - gas provided by the sender.
    public let gas: BigUInt
    /// gasPrice: QUANTITY - gas price provided by the sender in Wei.
    public let gasPrice: BigUInt
    /// input: DATA - the data send along with the transaction.
    public let input: Data
    /// nonce: QUANTITY - the number of transactions made by the sender prior to this one.
    public let nonce: BigUInt
    /// to: DATA, 20 Bytes - address of the receiver. null when its a contract creation transaction.
    public let to: Address
    /// value: QUANTITY - value transferred in Wei.
    public let value: BigUInt
    /// v: QUANTITY - ECDSA recovery id
    public let v: BigUInt
    /// r: DATA, 32 Bytes - ECDSA signature r
    public let r: Data
    /// s: DATA, 32 Bytes - ECDSA signature s
    public let s: Data
    
    public init(_ json: AnyReader) throws {
        processed = try? ProcessedTransactionInfo(json)
        from = try json.at("from").address()
        gas = try json.at("gas").uint256()
        gasPrice = try json.at("gasPrice").uint256()
        hash = try json.at("hash").data()
        input = try json.at("input").data()
        nonce = try json.at("nonce").uint256()
        to = try json.at("to").address()
        value = try json.at("value").uint256()
        v = try json.at("v").uint256()
        r = try json.at("r").data()
        s = try json.at("s").data()
    }
}
public class ProcessedTransactionInfo {
    /// blockHash: DATA, 32 Bytes - hash of the block where this transaction was in. null when its pending.
    public let blockHash: Data
    /// blockNumber: QUANTITY - block number where this transaction was in. null when its pending.
    public let blockNumber: BigUInt
    /// transactionIndex: QUANTITY - integer of the transaction's index position in the block. null when its pending.
    public let transactionIndex: BigUInt
    public init(_ json: AnyReader) throws {
        blockHash = try json.at("blockHash").data()
        blockNumber = try json.at("blockNumber").uint256()
        transactionIndex = try json.at("transactionIndex").uint256()
    }
}

public class TransactionReceiptInfo {
    /// transactionHash : DATA, 32 Bytes - hash of the transaction.
    public let transactionHash: Data
    /// transactionIndex: QUANTITY - integer of the transaction's index position in the block.
    public let transactionIndex: BigUInt
    /// blockHash: DATA, 32 Bytes - hash of the block where this transaction was in.
    public let blockHash: Data
    /// blockNumber: QUANTITY - block number where this transaction was in.
    public let blockNumber: BigUInt
    /// from: DATA, 20 Bytes - address of the sender.
    public let from: Address
    /// to: DATA, 20 Bytes - address of the receiver. null when it's a contract creation transaction.
    public let to: Address?
    /// cumulativeGasUsed : QUANTITY - The total amount of gas used when this transaction was executed in the block.
    public let cumulativeGasUsed: BigUInt
    /// gasUsed : QUANTITY - The amount of gas used by this specific transaction alone.
    public let gasUsed: BigUInt
    /// contractAddress : DATA, 20 Bytes - The contract address created, if the transaction was a contract creation, otherwise null.
    public let contractAddress: Address?
    /// logs: Array - Array of log objects, which this transaction generated.
    public let logs: [TransactionLog]
    /// logsBloom: DATA, 256 Bytes - Bloom filter for light clients to quickly retrieve related logs.
    public let logsBloom: Data
    
    /// It also returns either :
    /// root : DATA 32 bytes of post-transaction stateroot (pre Byzantium)
    public let root: Data?
    /// status: QUANTITY either 1 (success) or 0 (failure)
    public let status: Int?
    public init(_ json: AnyReader) throws {
        transactionHash = try json.at("transactionHash").data()
        transactionIndex = try json.at("transactionIndex").uint256()
        blockHash = try json.at("blockHash").data()
        blockNumber = try json.at("blockNumber").uint256()
        from = try json.at("from").address()
        to = try json.optional("to")?.address()
        cumulativeGasUsed = try json.at("cumulativeGasUsed").uint256()
        gasUsed = try json.at("gasUsed").uint256()
        contractAddress = try json.optional("contractAddress")?.address()
        logs = try json.at("logs").array(TransactionLog.init)
        logsBloom = try json.at("logsBloom").data()
        root = try json.optional("root")?.data()
        status = try json.optional("status")?.int()
    }
}

public class TransactionLog {
    public init(_ json: AnyReader) throws {
        
    }
}

public class FilterChanges {
    /// For filters created with eth_newBlockFilter the return are block hashes (DATA, 32 Bytes), e.g. ["0x3454645634534..."].
    public let newBlocks: [Data]
    
    /// For filters created with eth_newPendingTransactionFilter the return are transaction hashes (DATA, 32 Bytes), e.g. ["0x6345343454645..."].
    public let newPendingTransactions: [Data]
    
    /// For filters created with eth_newFilter logs are objects with following params:
    public let newFilter: [FilterChange]
    
    public init(_ json: AnyReader) throws {
        let array = try json.array()
        if array.isEmpty {
            newBlocks = []
            newPendingTransactions = []
            newFilter = []
        } else if array[0].raw is String {
            newBlocks = try array.map { try $0.data() }
            newPendingTransactions = newBlocks
            newFilter = []
        } else {
            newBlocks = []
            newPendingTransactions = []
            newFilter = try array.map(FilterChange.init)
        }
    }
}

public class FilterChange {
    /// removed: TAG - true when the log was removed, due to a chain reorganization. false if its a valid log.
    public let removed: Bool
    /// logIndex: QUANTITY - integer of the log index position in the block. null when its pending log.
    public let logIndex: BigUInt
    /// transactionIndex: QUANTITY - integer of the transactions index position log was created from. null when its pending log.
    public let transactionIndex: BigUInt
    /// transactionHash: DATA, 32 Bytes - hash of the transactions this log was created from. null when its pending log.
    public let transactionHash: Data
    /// blockHash: DATA, 32 Bytes - hash of the block where this log was in. null when its pending. null when its pending log.
    public let blockHash: Data
    /// blockNumber: QUANTITY - the block number where this log was in. null when its pending. null when its pending log.
    public let blockNumber: BigUInt
    /// address: DATA, 20 Bytes - address from which this log originated.
    public let address: Address
    /// data: DATA - contains the non-indexed arguments of the log.
    public let data: Data
    /// topics: Array of DATA - Array of 0 to 4 32 Bytes DATA of indexed log arguments. (In solidity: The first topic is the hash of the signature of the event (e.g. Deposit(address,bytes32,uint256)), except you declared the event with the anonymous specifier.)
    public let topics: [Data]
    init(_ json: AnyReader) throws {
        removed = try json.at("removed").bool()
        logIndex = try json.at("logIndex").uint256()
        transactionIndex = try json.at("transactionIndex").uint256()
        transactionHash = try json.at("transactionHash").data()
        blockHash = try json.at("blockHash").data()
        blockNumber = try json.at("v").uint256()
        address = try json.at("address").address()
        data = try json.at("data").data()
        topics = try json.at("topics").array(_data)
    }
}

public class WorkInfo {
    /// DATA, 32 Bytes - current block header pow-hash
    public let currentBlockHeader: Data
    /// DATA, 32 Bytes - the seed hash used for the DAG.
    public let seedHash: Data
    /// DATA, 32 Bytes - the boundary condition ("target"), 2^256 / difficulty.
    public let boundaryCondition: Data
    
    public init(_ json: AnyReader) throws {
        let array = try json.array()
        currentBlockHeader = try array.at(0).data()
        seedHash = try array.at(1).data()
        boundaryCondition = try array.at(2).data()
    }
}

public class ProofInfo {
    /// balance: QUANTITY - the balance of the account. See eth_getBalance
    public let balance: BigUInt
    /// codeHash: DATA, 32 Bytes - hash of the code of the account. For a simple Account without code it will return "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    public let codeHash: Data
    
    /// nonce: QUANTITY, - nonce of the account. See eth_getTransactionCount
    public let nonce: BigUInt
    
    /// storageHash: DATA, 32 Bytes - SHA3 of the StorageRoot. All storage will deliver a MerkleProof starting with this rootHash.
    public let storageHash: Data
    
    /// accountProof: ARRAY - Array of rlp-serialized MerkleTree-Nodes, starting with the stateRoot-Node, following the path of the SHA3 (address) as key.
    public let accountProof: [Data]
    
    /// storageProof: ARRAY - Array of storage-entries as requested.
    public let storageProof: [IndexedProof]
    init(_ json: AnyReader) throws {
        balance = try json.at("balance").uint256()
        codeHash = try json.at("codeHash").data()
        nonce = try json.at("nonce").uint256()
        storageHash = try json.at("storageHash").data()
        accountProof = try json.at("accountProof").array(_data)
        storageProof = try json.at("storageProof").array(IndexedProof.init)
    }
}

public class IndexedProof {
    /// key: QUANTITY - the requested storage key
    public let key: BigUInt
    /// value: QUANTITY - the storage value
    public let value: BigUInt
    /// proof: ARRAY - Array of rlp-serialized MerkleTree-Nodes, starting with the storageHash-Node, following the path of the SHA3 (key) as path.
    public let proof: [Data]
    init(_ json: AnyReader) throws {
        key = try json.at("key").uint256()
        value = try json.at("value").uint256()
        proof = try json.at("proof").array(_data)
    }
}
