//
//  EthereumApi.swift
//  Tests
//
//  Created by Dmitry on 17/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import BigInt


/// Default provider for all ethereum requests.
public var eth = EthereumApi.infura(.mainnet)
/**
 WIP
 https://github.com/ethereum/wiki/wiki/JSON-RPC
 */
public class EthereumApi {
    /// URL Address to which requests will be sent. default: mainnet.infura.io
    public var network: NetworkProvider
    
    /// Init with network
    public init(network: NetworkProvider) {
        self.network = network
    }
    public static func localhost(port: Int) -> EthereumApi {
        return EthereumApi(network: NetworkProvider(url: URL(string: "http://localhost:\(port)")!))
    }
    public static func infura(_ network: NetworkId) -> EthereumApi {
        return EthereumApi(network: NetworkProvider(url: .infura(network)))
    }
    
    /// Shh api. Doesn't works on infura networks
    public var shh: ShhApi { return ShhApi(parent: self) }
    
    /// Returns the current client version.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":67}'
    ///
    /// // Result
    /// {
    ///   "id":67,
    ///   "jsonrpc":"2.0",
    ///   "result": "Mist/v0.9.3/darwin/go1.4.1"
    /// }
    /// ```
    ///
    /// - Returns: `String` - The current client version.
    public func clientVersion() -> Promise<String> {
        return network.send("web3_clientVersion").string()
    }
    
    /// #### web3_sha3
    ///
    /// Returns Keccak-256 (*not* the standardized SHA3-256) of the given data.
    ///
    /// - Parameter : `DATA` - the data to convert into a SHA3 hash.
    ///
    /// ```js
    /// params: [
    ///  "0x68656c6c6f20776f726c64"
    /// ]
    /// ```
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"web3_sha3","params":["0x68656c6c6f20776f726c64"],"id":64}'
    ///
    /// // Result
    /// {
    ///  "id":64,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    /// }
    /// ```
    ///
    /// - Returns: `DATA` - The SHA3 result of the given string.
    public func sha3(_ data: Data) -> Promise<Data> {
        return network.send("web3_sha3", data).data()
    }
    
    /// Returns the current network id.
    ///
    /// - `"1"`: Ethereum Mainnet
    /// - `"2"`: Morden Testnet  (deprecated)
    /// - `"3"`: Ropsten Testnet
    /// - `"4"`: Rinkeby Testnet
    /// - `"42"`: Kovan Testnet
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":67}'
    ///
    /// // Result
    /// {
    ///  "id":67,
    ///  "jsonrpc": "2.0",
    ///  "result": "3"
    /// }
    /// ```
    ///
    /// - Returns: `String` - The current network id.
    public func version() -> Promise<String> {
        return network.send("net_version").string()
    }
    
    /// Returns `true` if client is actively listening for network connections.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"net_listening","params":[],"id":67}'
    ///
    /// // Result
    /// {
    ///  "id":67,
    ///  "jsonrpc":"2.0",
    ///  "result":true
    /// }
    /// ```
    ///
    /// - Returns: `Boolean` - `true` when listening, otherwise `false`.
    public func listening() -> Promise<Bool> {
        return network.send("net_listening").bool()
    }
    
    /// Returns number of peers currently connected to the client.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":74}'
    ///
    /// // Result
    /// {
    ///  "id":74,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x2" // 2
    /// }
    /// ```
    ///
    /// - Returns: `QUANTITY` - integer of the number of connected peers.
    public func peerCount() -> Promise<Int> {
        return network.send("net_peerCount").int()
    }
    
    /// Returns the current ethereum protocol version.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_protocolVersion","params":[],"id":67}'
    ///
    /// // Result
    /// {
    ///  "id":67,
    ///  "jsonrpc": "2.0",
    ///  "result": "54"
    /// }
    /// ```
    ///
    /// - Returns: `String` - The current ethereum protocol version.
    public func protocolVersion() -> Promise<String> {
        return network.send("eth_protocolVersion").string()
    }
    
    /// Returns an object with data about the sync status or `false`.
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": {
    ///    startingBlock: '0x384',
    ///    currentBlock: '0x386',
    ///    highestBlock: '0x454'
    ///  }
    /// }
    /// // Or when not syncing
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": false
    /// }
    /// ```
    ///
    /// - Returns: `Object|Boolean`, An object with sync status data or `FALSE`, when not syncing:
    public func syncing() -> Promise<SyncingStatus?> {
        return network.send("eth_syncing").map {
            let bool = (try? $0.bool()) ?? true
            guard bool else { return nil }
            return try SyncingStatus($0)
        }
    }
    
    /// Returns the client coinbase address.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":64}'
    ///
    /// // Result
    /// {
    ///  "id":64,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xc94770007dda54cF92009BFF0dE90c06F603a09f"
    /// }
    /// ```
    ///
    /// - Returns: `DATA`, 20 bytes - the current coinbase address.
    public func coinbase() -> Promise<Address> {
        return network.send("eth_coinbase").address()
    }
    
    /// Returns `true` if client is actively mining new blocks.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":71}'
    ///
    /// // Result
    /// {
    ///  "id":71,
    ///  "jsonrpc": "2.0",
    ///  "result": true
    /// }
    ///
    /// ```
    ///
    /// - Returns: `Boolean` - returns `true` of the client is mining, otherwise `false`.
    public func mining() -> Promise<Bool> {
        return network.send("eth_mining").bool()
    }
    
    /// Returns the number of hashes per second that the node is mining with.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_hashrate","params":[],"id":71}'
    ///
    /// // Result
    /// {
    ///  "id":71,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x38a"
    /// }
    ///
    /// ```
    ///
    /// - Returns: `QUANTITY` - number of hashes per second.
    public func hashrate() -> Promise<Int> {
        return network.send("eth_hashrate").int()
    }
    
    /// Returns the current price per gas in wei.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":73,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x09184e72a000" // 10000000000000
    /// }
    /// ```
    ///
    /// - Returns: `QUANTITY` - integer of the current gas price in wei.
    public func gasPrice() -> Promise<BigUInt> {
        return network.send("eth_gasPrice").uint256()
    }
    
    /// Returns a list of addresses owned by client.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": ["0xc94770007dda54cF92009BFF0dE90c06F603a09f"]
    /// }
    /// ```
    ///
    /// - Returns: `Array of DATA`, 20 Bytes - addresses owned by the client.
    public func accounts() -> Promise<[Address]> {
        return network.send("eth_accounts").array(_address)
    }
    
    /// Returns the number of most recent block.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":83,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xc94" // 1207
    /// }
    /// ```
    ///
    /// - Returns: `QUANTITY` - integer of the current block number the client is on.
    public func blockNumber() -> Promise<Int> {
        return network.send("eth_blockNumber").int()
    }
    
    /// Returns the balance of the account of given address.
    ///
    /// ```js
    /// params: [
    ///   '0xc94770007dda54cF92009BFF0dE90c06F603a09f',
    ///   'latest'
    /// ]
    /// ```
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xc94770007dda54cF92009BFF0dE90c06F603a09f", "latest"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x0234c8a3397aab58" // 158972490234375000
    /// }
    /// ```
    ///
    ///
    /// - Parameter address: `DATA`, 20 Bytes - address to check for balance.
    /// - Parameter block: `QUANTITY|TAG` - integer block number, or the string `"latest"`, `"earliest"` or `"pending"`, see the [default block parameter](#the-default-block-parameter)
    /// - Returns: `QUANTITY` - integer of the current balance in wei.
    public func getBalance(address: Address, block: BlockNumber) -> Promise<BigUInt> {
        return network.send("eth_getBalance", address, block).uint256()
    }
    
    /// Returns the value from a storage position at a given address.
    ///
    /// ##### Example
    /// Calculating the correct position depends on the storage to retrieve. Consider the following contract deployed at `0x295a70b2de5e3953354a6a8344e616ed314d7251` by address `0x391694e7e0b0cce554cb130d723a9d27458f9298`.
    ///
    /// ```
    /// contract Storage {
    ///    uint pos0;
    ///    mapping(address => uint) pos1;
    ///
    ///    function Storage() {
    ///        pos0 = 1234;
    ///        pos1[msg.sender] = 5678;
    ///    }
    
    /// }
    /// ```
    ///
    /// Retrieving the value of pos0 is straight forward:
    ///
    /// ```js
    /// curl -X POST --data '{"jsonrpc":"2.0", "method": "eth_getStorageAt", "params": ["0x295a70b2de5e3953354a6a8344e616ed314d7251", "0x0", "latest"], "id": 1}' localhost:8545
    ///
    /// {"jsonrpc":"2.0","id":1,"result":"0x00000000000000000000000000000000000000000000000000000000000004d2"}
    /// ```
    ///
    /// Retrieving an element of the map is harder. The position of an element in the map is calculated with:
    /// ```js
    /// keccack(LeftPad32(key, 0), LeftPad32(map position, 0))
    /// ```
    ///
    /// This means to retrieve the storage on pos1["0x391694e7e0b0cce554cb130d723a9d27458f9298"] we need to calculate the position with:
    /// ```js
    /// keccak(decodeHex("000000000000000000000000391694e7e0b0cce554cb130d723a9d27458f9298" + "0000000000000000000000000000000000000000000000000000000000000001"))
    /// ```
    /// The geth console which comes with the web3 library can be used to make the calculation:
    /// ```js
    /// > var key = "000000000000000000000000391694e7e0b0cce554cb130d723a9d27458f9298" + "0000000000000000000000000000000000000000000000000000000000000001"
    /// undefined
    /// > web3.sha3(key, {"encoding": "hex"})
    /// "0x6661e9d6d8b923d5bbaab1b96e1dd51ff6ea2a93520fdc9eb75d059238b8c5e9"
    /// ```
    /// Now to fetch the storage:
    /// ```js
    /// curl -X POST --data '{"jsonrpc":"2.0", "method": "eth_getStorageAt", "params": ["0x295a70b2de5e3953354a6a8344e616ed314d7251", "0x6661e9d6d8b923d5bbaab1b96e1dd51ff6ea2a93520fdc9eb75d059238b8c5e9", "latest"], "id": 1}' localhost:8545
    ///
    /// {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000000000000000000162e"}
    ///
    /// ```
    ///
    /// - Parameter address: `DATA`, 20 Bytes - address of the storage.
    /// - Parameter position: `QUANTITY` - integer of the position in the storage.
    /// - Parameter block: `QUANTITY|TAG` - integer block number, or the string `"latest"`, `"earliest"` or `"pending"`, see the [default block parameter](#the-default-block-parameter)
    ///
    /// - Returns: `DATA` - the value at this storage position.
    public func getStorageAt(_ address: Address, position: BigUInt, block: BlockNumber) -> Promise<Data> {
        return network.send("eth_getStorageAt", address, position, block).data()
    }
    
    /// Returns the number of transactions *sent* from an address.
    ///
    /// ```js
    /// params: [
    ///   '0xc94770007dda54cF92009BFF0dE90c06F603a09f',
    ///   'latest' // state at the latest block
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["0xc94770007dda54cF92009BFF0dE90c06F603a09f","latest"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x1" // 1
    /// }
    /// ```
    ///
    /// - Parameter : `DATA`, 20 Bytes - address.
    /// - Parameter : `QUANTITY|TAG` - integer block number, or the string `"latest"`, `"earliest"` or `"pending"`, see the [default block parameter](#the-default-block-parameter)
    ///
    /// - Returns: `QUANTITY` - integer of the number of transactions send from this address.
    public func getTransactionCount(_ address: Address, block: BlockNumber) -> Promise<BigUInt> {
        return network.send("eth_getTransactionCount", address, block).uint256()
    }
    
    /// Returns the number of transactions in a block from a block matching the given block hash.
    ///
    /// ```js
    /// params: [
    ///   '0xb903239f8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238'
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockTransactionCountByHash","params":["0xc94770007dda54cF92009BFF0dE90c06F603a09f"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xc" // 11
    /// }
    /// ```
    ///
    /// - Parameter : `DATA`, 32 Bytes - hash of a block.
    /// - Returns: `QUANTITY` - integer of the number of transactions in this block.
    public func getBlockTransactionCountByHash(_ hash: Data) -> Promise<BigUInt> {
        return network.send("eth_getBlockTransactionCountByHash", hash).uint256()
    }
    
    /// Returns the number of transactions in a block matching the given block number.
    ///
    /// ```js
    /// params: [
    ///   '0xe8', // 232
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockTransactionCountByNumber","params":["0xe8"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xa" // 10
    /// }
    /// ```
    ///
    /// - Parameter block: `QUANTITY|TAG` - integer of a block number, or the string `"earliest"`, `"latest"` or `"pending"`, as in the [default block parameter](#the-default-block-parameter).
    ///
    /// - Returns: `QUANTITY` - integer of the number of transactions in this block.
    public func getBlockTransactionCountByNumber(_ block: BlockNumber) -> Promise<BigUInt> {
        return network.send("eth_getBlockTransactionCountByNumber", block).uint256()
    }
    
    /// Returns the number of uncles in a block from a block matching the given block hash.
    ///
    /// ```js
    /// params: [
    ///   '0xc94770007dda54cF92009BFF0dE90c06F603a09f'
    /// ]
    /// ```
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getUncleCountByBlockHash","params":["0xc94770007dda54cF92009BFF0dE90c06F603a09f"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xc" // 1
    /// }
    /// ```
    ///
    /// - Parameter : `DATA`, 32 Bytes - hash of a block.
    ///
    /// - Returns: `QUANTITY` - integer of the number of uncles in this block.
    public func getUncleCountByBlockHash(_ hash: Data) -> Promise<BigUInt> {
        return network.send("eth_getUncleCountByBlockHash", hash).uint256()
    }
    
    /// Returns the number of uncles in a block from a block matching the given block number.
    ///
    ///
    /// ```js
    /// params: [
    ///   '0xe8', // 232
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getUncleCountByBlockNumber","params":["0xe8"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x1" // 1
    /// }
    /// ```
    ///
    /// - Parameter : `QUANTITY|TAG` - integer of a block number, or the string "latest", "earliest" or "pending", see the [default block parameter](#the-default-block-parameter).
    ///
    /// - Returns: `QUANTITY` - integer of the number of uncles in this block.
    public func getUncleCountByBlockNumber(_ block: BlockNumber) -> Promise<BigUInt> {
        return network.send("eth_getUncleCountByBlockNumber", block).uint256()
    }
    
    /// Returns code at a given address.
    ///
    /// ```js
    /// params: [
    ///   '0xa94f5374fce5edbc8e2a8697c15331677e6ebf0b',
    ///   '0x2'  // 2
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getCode","params":["0xa94f5374fce5edbc8e2a8697c15331677e6ebf0b", "0x2"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x600160008035811a818181146012578301005b601b6001356025565b8060005260206000f25b600060078202905091905056"
    /// }
    /// ```
    ///
    /// - Parameter address: `DATA`, 20 Bytes - address.
    /// - Parameter block: `QUANTITY|TAG` - integer block number, or the string `"latest"`, `"earliest"` or `"pending"`, see the [default block parameter](#the-default-block-parameter).
    ///
    /// - Returns: `DATA` - the code from the given address.
    public func getCode(address: Address, block: BlockNumber) -> Promise<Data> {
        return network.send("eth_getCode", address, block).data()
    }
    
    /// The sign method calculates an Ethereum specific signature with: `sign(keccak256("\x19Ethereum Signed Message:\n" + len(message) + message)))`.
    ///
    /// By adding a prefix to the message makes the calculated signature recognisable as an Ethereum specific signature. This prevents misuse where a malicious DApp can sign arbitrary data (e.g. transaction) and use the signature to impersonate the victim.
    ///
    /// - Note: the address to sign with must be unlocked.
    ///
    /// ##### Parameters
    /// account, message
    ///
    /// ##### Example
    ///
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sign","params":["0x9b2055d370f73ec7d8a03e965129118dc8f5bf83", "0xdeadbeaf"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xa3f20717a250c2b0b729b7e5becbff67fdaef7e0699da4de7ca5895b02a170a12d887fd3b17bfdce3481f10bea41f45ba9f709d39ce8325427b57afcfc994cee1b"
    /// }
    /// ```
    ///
    /// An example how to use solidity ecrecover to verify the signature calculated with `eth_sign` can be found [here](https://gist.github.com/bas-vk/d46d83da2b2b4721efb0907aecdb7ebd). The contract is deployed on the testnet Ropsten and Rinkeby.
    ///
    /// - Parameter address: `DATA`, 20 Bytes - address.
    /// - Parameter data: `DATA`, N Bytes - message to sign.
    ///
    /// - Returns: `DATA`: Signature
    public func sign(address: Address, data: Data) -> Promise<Data> {
        return network.send("eth_sign", address, data).data()
    }
    
    /// Creates new message call transaction or a contract creation, if the data field contains code.
    ///
    ///
    /// ```js
    /// params: [{
    ///  "from": "0xb60e8dd61c5d32be8058bb8eb970870f07233155",
    ///  "to": "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
    ///  "gas": "0x76c0", // 30400
    ///  "gasPrice": "0x9184e72a000", // 10000000000000
    ///  "value": "0x9184e72a", // 2441406250
    ///  "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
    /// }]
    /// ```
    ///
    /// Use [eth_getTransactionReceipt](#eth_gettransactionreceipt) to get the contract address, after the transaction was mined, when you created a contract.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{see above}],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
    /// }
    /// ```
    /// - Parameter from: `DATA`, 20 Bytes - The address the transaction is send from.
    /// - Parameter to: `DATA`, 20 Bytes - (optional when creating new contract) The address the transaction is directed to.
    /// - Parameter gas: `QUANTITY`  - (optional, default: 90000) Integer of the gas provided for the transaction execution. It will return unused gas.
    /// - Parameter gasPrice: `QUANTITY`  - (optional, default: To-Be-Determined) Integer of the gasPrice used for each paid gas
    /// - Parameter value: `QUANTITY`  - (optional) Integer of the value sent with this transaction
    /// - Parameter data: `DATA`  - The compiled code of a contract OR the hash of the invoked method signature and encoded parameters. For details see [Ethereum Contract ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI)
    /// - Parameter nonce: `QUANTITY`  - (optional) Integer of a nonce. This allows to overwrite your own pending transactions that use the same nonce.
    ///
    /// - Returns: `DATA`, 32 Bytes - the transaction hash, or the zero hash if the transaction is not yet available.
    public func sendTransaction(from: Address, to: Address, gas: BigUInt?, gasPrice: BigUInt?, value: BigUInt?, data: Data, nonce: BigUInt?) -> Promise<Data> {
        let dictionary = JDictionary()
            .set("from", from)
            .set("to", to)
            .set("gas", gas)
            .set("gasPrice", gasPrice)
            .set("value", value)
            .set("data", data)
            .set("nonce", nonce)
        return network.send("eth_sendTransaction", dictionary).data()
    }
    
    /// Creates new message call transaction or a contract creation for signed transactions.
    ///
    ///
    /// ```js
    /// params: ["0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"]
    /// ```
    ///
    /// Use [eth_getTransactionReceipt](#eth_gettransactionreceipt) to get the contract address, after the transaction was mined, when you created a contract.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":[{see above}],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
    /// }
    /// ```
    ///
    /// - Parameter data: `DATA`, The signed transaction data.
    ///
    /// - Returns: `DATA`, 32 Bytes - the transaction hash, or the zero hash if the transaction is not yet available.
    public func sendRawTransaction(data: Data) -> Promise<Data> {
        return network.send("eth_sendRawTransaction", data).data()
    }
    
    /// Executes a new message call immediately without creating a transaction on the block chain.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_call","params":[{see above}],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x"
    /// }
    /// ```
    ///
    /// - Parameter from: `DATA`, 20 Bytes - (optional) The address the transaction is sent from.
    /// - Parameter to: `DATA`, 20 Bytes  - The address the transaction is directed to.
    /// - Parameter gas: `QUANTITY`  - (optional) Integer of the gas provided for the transaction execution. eth_call consumes zero gas, but this parameter may be needed by some executions.
    /// - Parameter gasPrice: `QUANTITY`  - (optional) Integer of the gasPrice used for each paid gas
    /// - Parameter value: `QUANTITY`  - (optional) Integer of the value sent with this transaction
    /// - Parameter data: `DATA`  - (optional) Hash of the method signature and encoded parameters. For details see [Ethereum Contract ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI)
    /// - Parameter block: `QUANTITY|TAG` - integer block number, or the string `"latest"`, `"earliest"` or `"pending"`, see the [default block parameter](#the-default-block-parameter)
    ///
    /// - Returns: `DATA` - the return value of executed contract.
    public func call(from: Address?, to: Address, gas: BigUInt?, gasPrice: BigUInt?, value: BigUInt?, data: Data?, _ block: BlockNumber) -> Promise<Data> {
        let dictionary = JDictionary()
            .set("from", from)
            .set("to", to)
            .set("gas", gas)
            .set("gasPrice", gasPrice)
            .set("value", value)
            .set("data", data)
        return network.send("eth_call", dictionary, block).data()
    }
    
    /// Generates and returns an estimate of how much gas is necessary to allow the transaction to complete. The transaction will not be added to the blockchain. Note that the estimate may be significantly more than the amount of gas actually used by the transaction, for a variety of reasons including EVM mechanics and node performance.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_estimateGas","params":[{see above}],"id":1}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x5208" // 21000
    /// }
    /// ```
    ///
    /// - Parameter from: `DATA`, 20 Bytes - (optional) The address the transaction is sent from.
    /// - Parameter to: `DATA`, 20 Bytes  - The address the transaction is directed to.
    /// - Parameter gas: `QUANTITY`  - (optional) Integer of the gas provided for the transaction execution. eth_call consumes zero gas, but this parameter may be needed by some executions.
    /// - Parameter gasPrice: `QUANTITY`  - (optional) Integer of the gasPrice used for each paid gas
    /// - Parameter value: `QUANTITY`  - (optional) Integer of the value sent with this transaction
    /// - Parameter data: `DATA`  - (optional) Hash of the method signature and encoded parameters. For details see [Ethereum Contract ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI)
    /// - Parameter block: `QUANTITY|TAG` - integer block number, or the string `"latest"`, `"earliest"` or `"pending"`, see the [default block parameter](#the-default-block-parameter)
    ///
    /// - Returns: `QUANTITY` - the amount of gas used.
    public func estimateGas(from: Address?, to: Address, gas: BigUInt?, gasPrice: BigUInt?, value: BigUInt?, data: Data?) -> Promise<BigUInt> {
        let dictionary = JDictionary()
            .set("from", from)
            .set("to", to)
            .set("gas", gas)
            .set("gasPrice", gasPrice)
            .set("value", value)
            .set("data", data)
        return network.send("eth_estimateGas", dictionary).uint256()
    }
    
    /// Returns information about a block by hash.
    ///
    /// ```js
    /// params: [
    ///   '0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331',
    ///   true
    /// ]
    /// ```
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByHash","params":["0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331", true],"id":1}'
    ///
    /// // Result
    /// {
    /// "id":1,
    /// "jsonrpc":"2.0",
    /// "result": {
    ///    "number": "0x1b4", // 436
    ///    "hash": "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331",
    ///    "parentHash": "0x9646252be9520f6e71339a8df9c55e4d7619deeb018d2a3f2d21fc165dde5eb5",
    ///    "nonce": "0xe04d296d2460cfb8472af2c5fd05b5a214109c25688d3704aed5484f9a7792f2",
    ///    "sha3Uncles": "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
    ///    "logsBloom": "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331",
    ///    "transactionsRoot": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
    ///    "stateRoot": "0xd5855eb08b3387c0af375e9cdb6acfc05eb8f519e419b874b6ff2ffda7ed1dff",
    ///    "miner": "0x4e65fda2159562a496f9f3522f89122a3088497a",
    ///    "difficulty": "0x027f07", // 163591
    ///    "totalDifficulty":  "0x027f07", // 163591
    ///    "extraData": "0x0000000000000000000000000000000000000000000000000000000000000000",
    ///    "size":  "0x027f07", // 163591
    ///    "gasLimit": "0x9f759", // 653145
    ///    "gasUsed": "0x9f759", // 653145
    ///    "timestamp": "0x54e34e8e" // 1424182926
    ///    "transactions": [{...},{ ... }]
    ///    "uncles": ["0x1606e5...", "0xd5145a9..."]
    ///  }
    /// }
    /// ```
    ///
    /// - Parameter hash: `DATA`, 32 Bytes - Hash of a block.
    /// - Parameter fullInformation: `Boolean` - If `true` it returns the full transaction objects, if `false` only the hashes of the transactions.
    ///
    /// - Returns: `Object` - A block object, or `null` when no block was found:
    public func getBlockByHash(_ hash: Data, _ fullInformation: Bool) -> Promise<BlockInfo?> {
        return network.send("eth_getBlockByHash", hash, fullInformation).block()
    }
    
    /// Returns information about a block by block number.
    ///
    /// ```js
    /// params: [
    ///   '0x1b4', // 436
    ///   true
    /// ]
    /// ```
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x1b4", true],"id":1}'
    /// ```
    ///
    /// Result see [eth_getBlockByHash](#eth_getblockbyhash)
    ///
    /// - Parameter number: `QUANTITY|TAG` - integer of a block number, or the string `"earliest"`, `"latest"` or `"pending"`, as in the [default block parameter](#the-default-block-parameter).
    /// - Parameter fullInformation: `Boolean` - If `true` it returns the full transaction objects, if `false` only the hashes of the transactions.
    ///
    /// - Returns: `Object` - A block object, or `null` when no block was found:
    public func getBlockByNumber(_ number: BlockNumber, _ fullInformation: Bool) -> Promise<BlockInfo?> {
        return network.send("eth_getBlockByNumber", number, fullInformation).block()
    }
    
    /// Returns the information about a transaction requested by transaction hash.
    ///
    /// ```js
    /// params: [
    ///   "0x88df016429689c079f3b2f6ad39fa052532c56795b733da78a91ebe6a713944b"
    /// ]
    /// ```
    ///
    ///  - `blockHash`: `DATA`, 32 Bytes - hash of the block where this transaction was in. `null` when its pending.
    ///  - `blockNumber`: `QUANTITY` - block number where this transaction was in. `null` when its pending.
    ///  - `from`: `DATA`, 20 Bytes - address of the sender.
    ///  - `gas`: `QUANTITY` - gas provided by the sender.
    ///  - `gasPrice`: `QUANTITY` - gas price provided by the sender in Wei.
    ///  - `hash`: `DATA`, 32 Bytes - hash of the transaction.
    ///  - `input`: `DATA` - the data send along with the transaction.
    ///  - `nonce`: `QUANTITY` - the number of transactions made by the sender prior to this one.
    ///  - `to`: `DATA`, 20 Bytes - address of the receiver. `null` when its a contract creation transaction.
    ///  - `transactionIndex`: `QUANTITY` - integer of the transaction's index position in the block. `null` when its pending.
    ///  - `value`: `QUANTITY` - value transferred in Wei.
    ///  - `v`: `QUANTITY` - ECDSA recovery id
    ///  - `r`: `DATA`, 32 Bytes - ECDSA signature r
    ///  - `s`: `DATA`, 32 Bytes - ECDSA signature s
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":["0x88df016429689c079f3b2f6ad39fa052532c56795b733da78a91ebe6a713944b"],"id":1}'
    ///
    /// // Result
    /// {
    ///  "jsonrpc":"2.0",
    ///  "id":1,
    ///  "result":{
    ///    "blockHash":"0x1d59ff54b1eb26b013ce3cb5fc9dab3705b415a67127a003c3e61eb445bb8df2",
    ///    "blockNumber":"0x5daf3b", // 6139707
    ///    "from":"0xa7d9ddbe1f17865597fbd27ec712455208b6b76d",
    ///    "gas":"0xc350", // 50000
    ///    "gasPrice":"0x4a817c800", // 20000000000
    ///    "hash":"0x88df016429689c079f3b2f6ad39fa052532c56795b733da78a91ebe6a713944b",
    ///    "input":"0x68656c6c6f21",
    ///    "nonce":"0x15", // 21
    ///    "to":"0xf02c1c8e6114b1dbe8937a39260b5b0a374432bb",
    ///    "transactionIndex":"0x41", // 65
    ///    "value":"0xf3dbb76162000", // 4290000000000000
    ///    "v":"0x25", // 37
    ///    "r":"0x1b5e176d927f8e9ab405058b2d2457392da3e20f328b16ddabcebc33eaac5fea",
    ///    "s":"0x4ba69724e8f69de52f0125ad8b3c5c2cef33019bac3249e2c0a2192766d1721c"
    ///  }
    /// }
    /// ```
    ///
    /// - Parameter hash: `DATA`, 32 Bytes - hash of a transaction
    ///
    /// - Returns: `Object` - A transaction object, or `null` when no transaction was found:
    public func getTransactionByHash(_ hash: Data) -> Promise<TransactionInfo?> {
        return network.send("eth_getTransactionByHash", hash).transaction()
    }
    
    /// Returns information about a transaction by block hash and transaction index position.
    ///
    /// ```js
    /// params: [
    ///   '0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331',
    ///   '0x0' // 0
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionByBlockHashAndIndex","params":["0xc6ef2fc5426d6ad6fd9e2a26abeab0aa2411b7ab17f30a99d3cb96aed1d1055b", "0x0"],"id":1}'
    /// ```
    ///
    /// - Parameter blockHash: `DATA`, 32 Bytes - hash of a block.
    /// - Parameter index: `QUANTITY` - integer of the transaction index position.
    ///
    /// - Returns: `Object` - A transaction object, or `null` when no transaction was found:
    public func getTransactionByBlockHashAndIndex(_ blockHash: Data, _ index: BigUInt) -> Promise<TransactionInfo?> {
        return network.send("eth_getTransactionByBlockHashAndIndex", blockHash, index).transaction()
    }
    
    /// Returns information about a transaction by block number and transaction index position.
    ///
    ///
    /// ```js
    /// params: [
    ///   '0x29c', // 668
    ///   '0x0' // 0
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionByBlockNumberAndIndex","params":["0x29c", "0x0"],"id":1}'
    /// ```
    ///
    /// - Parameter number: `QUANTITY|TAG` - a block number, or the string `"earliest"`, `"latest"` or `"pending"`, as in the [default block parameter](#the-default-block-parameter).
    /// - Parameter index: `QUANTITY` - the transaction index position.
    ///
    /// - Returns: `Object` - A transaction object, or `null` when no transaction was found:
    public func getTransactionByBlockNumberAndIndex(_ number: BlockNumber, _ index: BigUInt) -> Promise<TransactionInfo?> {
        return network.send("eth_getTransactionByBlockNumberAndIndex", number, index).transaction()
    }
    
    /// Returns the receipt of a transaction by transaction hash.
    ///
    /// - Note: That the receipt is not available for pending transactions.
    ///
    /// ```js
    /// params: [
    ///   '0xb903239f8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238'
    /// ]
    /// ```
    ///
    /// It also returns _either_ :
    ///
    ///  - `root` : `DATA` 32 bytes of post-transaction stateroot (pre Byzantium)
    ///  - `status`: `QUANTITY` either `1` (success) or `0` (failure)
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["0xb903239f8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238"],"id":1}'
    ///
    /// // Result
    /// {
    /// "id":1,
    /// "jsonrpc":"2.0",
    /// "result": {
    ///     transactionHash: '0xb903239f8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238',
    ///     transactionIndex:  '0x1', // 1
    ///     blockNumber: '0xb', // 11
    ///     blockHash: '0xc6ef2fc5426d6ad6fd9e2a26abeab0aa2411b7ab17f30a99d3cb96aed1d1055b',
    ///     cumulativeGasUsed: '0x33bc', // 13244
    ///     gasUsed: '0x4dc', // 1244
    ///     contractAddress: '0xb60e8dd61c5d32be8058bb8eb970870f07233155', // or null, if none was created
    ///     logs: [{
    ///         // logs as returned by getFilterLogs, etc.
    ///     }, ...],
    ///     logsBloom: "0x00...0", // 256 byte bloom filter
    ///     status: '0x1'
    ///  }
    /// }
    /// ```
    ///
    /// - Parameter hash: `DATA`, 32 Bytes - hash of a transaction
    ///
    /// - Returns: `Object` - A transaction receipt object, or `null` when no receipt was found:
    public func getTransactionReceipt(_ hash: Data) -> Promise<TransactionReceiptInfo?> {
        return network.send("eth_getTransactionReceipt", hash).transactionReceipt()
    }
    
    /// Returns information about a uncle of a block by hash and uncle index position.
    ///
    /// ```js
    /// params: [
    ///   '0xc6ef2fc5426d6ad6fd9e2a26abeab0aa2411b7ab17f30a99d3cb96aed1d1055b',
    ///   '0x0' // 0
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getUncleByBlockHashAndIndex","params":["0xc6ef2fc5426d6ad6fd9e2a26abeab0aa2411b7ab17f30a99d3cb96aed1d1055b", "0x0"],"id":1}'
    /// ```
    ///
    /// - Note: An uncle doesn't contain individual transactions.
    ///
    /// - Parameter hash: `DATA`, 32 Bytes - hash a block.
    /// - Parameter index: `QUANTITY` - the uncle's index position.
    ///
    /// - Returns: `Object` - A block object, or `null` when no block was found:
    public func getUncleByBlockHashAndIndex(_ hash: Data, _ index: BigUInt) -> Promise<BlockInfo?> {
        return network.send("eth_getUncleByBlockHashAndIndex", hash, index).block()
    }
    
    /// Returns information about a uncle of a block by number and uncle index position.
    ///
    /// ```js
    /// params: [
    ///   '0x29c', // 668
    ///   '0x0' // 0
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getUncleByBlockNumberAndIndex","params":["0x29c", "0x0"],"id":1}'
    /// ```
    ///
    /// - Note: An uncle doesn't contain individual transactions.
    ///
    /// - Parameter number: `QUANTITY|TAG` - a block number, or the string `"earliest"`, `"latest"` or `"pending"`, as in the [default block parameter](#the-default-block-parameter).
    /// - Parameter index: `QUANTITY` - the uncle's index position.
    ///
    /// - Returns: `Object` - A block object, or `null` when no block was found:
    public func getUncleByBlockNumberAndIndex(_ number: BigUInt, _ index: BigUInt) -> Promise<BlockInfo?> {
        return network.send("eth_getUncleByBlockNumberAndIndex", number, index).block()
    }
    
    /// Creates a filter object, based on filter options, to notify when the state changes (logs).
    /// To check if the state has changed, call [eth_getFilterChanges](#eth_getfilterchanges).
    ///
    /// ##### A note on specifying topic filters:
    /// Topics are order-dependent. A transaction with a log with topics [A, B] will be matched by the following topic filters:
    /// * `[]` "anything"
    /// * `[A]` "A in first position (and anything after)"
    /// * `[null, B]` "anything in first position AND B in second position (and anything after)"
    /// * `[A, B]` "A in first position AND B in second position (and anything after)"
    /// * `[[A, B], [A, B]]` "(A OR B) in first position AND (A OR B) in second position (and anything after)"
    ///
    /// The filter options:
    ///  - `fromBlock`: `QUANTITY|TAG` - (optional, default: `"latest"`) Integer block number, or `"latest"` for the last mined block or `"pending"`, `"earliest"` for not yet mined transactions.
    ///  - `toBlock`: `QUANTITY|TAG` - (optional, default: `"latest"`) Integer block number, or `"latest"` for the last mined block or `"pending"`, `"earliest"` for not yet mined transactions.
    ///  - `address`: `DATA|Array`, 20 Bytes - (optional) Contract address or a list of addresses from which logs should originate.
    ///  - `topics`: `Array of DATA`,  - (optional) Array of 32 Bytes `DATA` topics. Topics are order-dependent. Each topic can also be an array of DATA with "or" options.
    ///
    /// ```js
    /// params: [{
    ///  "fromBlock": "0x1",
    ///  "toBlock": "0x2",
    ///  "address": "0x8888f1f195afa192cfee860698584c030f4c9db1",
    ///  "topics": ["0x000000000000000000000000a94f5374fce5edbc8e2a8697c15331677e6ebf0b", null, ["0x000000000000000000000000a94f5374fce5edbc8e2a8697c15331677e6ebf0b", "0x0000000000000000000000000aff3454fce5edbc8cca8697c15331677e6ebccc"]]
    /// }]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_newFilter","params":[{"topics":["0x0000000000000000000000000000000000000000000000000000000012341234"]}],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0x1" // 1
    /// }
    /// ```
    /// - Parameter options: `Object` - The filter options:
    ///
    /// - Returns: `QUANTITY` - A filter id.
    public func newFilter(_ options: FilterOptions) -> Promise<BigUInt> {
        return network.send("eth_newFilter", options).uint256()
    }
    
    /// Creates a filter in the node, to notify when a new block arrives.
    /// To check if the state has changed, call [eth_getFilterChanges](#eth_getfilterchanges).
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_newBlockFilter","params":[],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":  "2.0",
    ///  "result": "0x1" // 1
    /// }
    /// ```
    ///
    /// - Returns: `QUANTITY` - A filter id.
    public func newBlockFilter() -> Promise<BigUInt> {
        return network.send("eth_newBlockFilter").uint256()
    }
    
    /// Creates a filter in the node, to notify when a new block arrives.
    /// To check if the state has changed, call [eth_getFilterChanges](#eth_getfilterchanges).
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_newBlockFilter","params":[],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":  "2.0",
    ///  "result": "0x1" // 1
    /// }
    /// ```
    ///
    /// - Returns: `QUANTITY` - A filter id.
    public func newPendingTransactionFilter() -> Promise<BigUInt> {
        return network.send("eth_newPendingTransactionFilter").uint256()
    }
    
    /// Uninstalls a filter with given id. Should always be called when watch is no longer needed.
    /// Additonally Filters timeout when they aren't requested with [eth_getFilterChanges](#eth_getfilterchanges) for a period of time.
    ///
    /// ```js
    /// params: [
    ///  "0xb" // 11
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_uninstallFilter","params":["0xb"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": true
    /// }
    /// ```
    ///
    /// - Parameter id: `QUANTITY` - The filter id.
    ///
    /// - Returns: `Boolean` - `true` if the filter was successfully uninstalled, otherwise `false`.
    public func uninstallFilter(_ id: BigUInt) -> Promise<Bool> {
        return network.send("eth_uninstallFilter", id).bool()
    }
    
    /// Polling method for a filter, which returns an array of logs which occurred since last poll.
    ///
    /// ```js
    /// params: [
    ///  "0x16" // 22
    /// ]
    /// ```
    ///
    /// - For filters created with `eth_newBlockFilter` the return are block hashes (`DATA`, 32 Bytes), e.g. `["0x3454645634534..."]`.
    /// - For filters created with `eth_newPendingTransactionFilter ` the return are transaction hashes (`DATA`, 32 Bytes), e.g. `["0x6345343454645..."]`.
    /// - For filters created with `eth_newFilter` logs are objects with following params:
    ///
    ///  - `removed`: `TAG` - `true` when the log was removed, due to a chain reorganization. `false` if its a valid log.
    ///  - `logIndex`: `QUANTITY` - integer of the log index position in the block. `null` when its pending log.
    ///  - `transactionIndex`: `QUANTITY` - integer of the transactions index position log was created from. `null` when its pending log.
    ///  - `transactionHash`: `DATA`, 32 Bytes - hash of the transactions this log was created from. `null` when its pending log.
    ///  - `blockHash`: `DATA`, 32 Bytes - hash of the block where this log was in. `null` when its pending. `null` when its pending log.
    ///  - `blockNumber`: `QUANTITY` - the block number where this log was in. `null` when its pending. `null` when its pending log.
    ///  - `address`: `DATA`, 20 Bytes - address from which this log originated.
    ///  - `data`: `DATA` - contains the non-indexed arguments of the log.
    ///  - `topics`: `Array of DATA` - Array of 0 to 4 32 Bytes `DATA` of indexed log arguments. (In *solidity*: The first topic is the *hash* of the signature of the event (e.g. `Deposit(address,bytes32,uint256)`), except you declared the event with the `anonymous` specifier.)
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getFilterChanges","params":["0x16"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":"2.0",
    ///  "result": [{
    ///    "logIndex": "0x1", // 1
    ///    "blockNumber":"0x1b4", // 436
    ///    "blockHash": "0x8216c5785ac562ff41e2dcfdf5785ac562ff41e2dcfdf829c5a142f1fccd7d",
    ///    "transactionHash":  "0xdf829c5a142f1fccd7d8216c5785ac562ff41e2dcfdf5785ac562ff41e2dcf",
    ///    "transactionIndex": "0x0", // 0
    ///    "address": "0x16c5785ac562ff41e2dcfdf829c5a142f1fccd7d",
    ///    "data":"0x0000000000000000000000000000000000000000000000000000000000000000",
    ///    "topics": ["0x59ebeb90bc63057b6515673c3ecf9438e5058bca0f92585014eced636878c9a5"]
    ///    },{
    ///      ...
    ///    }]
    /// }
    /// ```
    ///
    /// - Parameter id: `QUANTITY` - the filter id.
    ///
    /// - Returns: `Array` - Array of log objects, or an empty array if nothing has changed since last poll.
    public func getFilterChanges(_ id: BigUInt) -> Promise<FilterChanges> {
        return network.send("eth_getFilterChanges", id).filterChanges()
    }
    
    /// Returns an array of all logs matching filter with given id.
    ///
    ///
    /// ```js
    /// params: [
    ///  "0x16" // 22
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getFilterLogs","params":["0x16"],"id":74}'
    /// ```
    ///
    /// Result see [eth_getFilterChanges](#eth_getfilterchanges)
    ///
    /// - Parameter id: `QUANTITY` - The filter id.
    ///
    /// - Returns: `Array` - Array of log objects, or an empty array if nothing has changed since last poll.
    public func getFilterLogs(_ id: BigUInt) -> Promise<FilterChanges> {
        return network.send("eth_getFilterLogs", id).filterChanges()
    }
    
    /// Returns an array of all logs matching a given filter object.
    ///
    /// The filter options:
    ///  - `fromBlock`: `QUANTITY|TAG` - (optional, default: `"latest"`) Integer block number, or `"latest"` for the last mined block or `"pending"`, `"earliest"` for not yet mined transactions.
    ///  - `toBlock`: `QUANTITY|TAG` - (optional, default: `"latest"`) Integer block number, or `"latest"` for the last mined block or `"pending"`, `"earliest"` for not yet mined transactions.
    ///  - `address`: `DATA|Array`, 20 Bytes - (optional) Contract address or a list of addresses from which logs should originate.
    ///  - `topics`: `Array of DATA`,  - (optional) Array of 32 Bytes `DATA` topics. Topics are order-dependent. Each topic can also be an array of DATA with "or" options.
    ///  - `blockhash`:  `DATA`, 32 Bytes - (optional) With the addition of EIP-234 (Geth >= v1.8.13 or Parity >= v2.1.0), `blockHash` is a new filter option which restricts the logs returned to the single block with the 32-byte hash `blockHash`.  Using `blockHash` is equivalent to `fromBlock` = `toBlock` = the block number with hash `blockHash`.  If `blockHash` is present in the filter criteria, then neither `fromBlock` nor `toBlock` are allowed.
    ///
    /// ```js
    /// params: [{
    ///  "topics": ["0x000000000000000000000000a94f5374fce5edbc8e2a8697c15331677e6ebf0b"]
    /// }]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getLogs","params":[{"topics":["0x000000000000000000000000a94f5374fce5edbc8e2a8697c15331677e6ebf0b"]}],"id":74}'
    /// ```
    /// - Parameter logs: `Object` - The filter options
    ///
    /// - Returns: `Array` - Array of log objects, or an empty array if nothing has changed since last poll.
    public func getLogs(_ logs: [FilterLogOptions]) -> Promise<FilterChanges> {
        return network.send("eth_getLogs", JArray(logs)).filterChanges()
    }
    
    /// Returns the hash of the current block, the seedHash, and the boundary condition to be met ("target").
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getWork","params":[],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":"2.0",
    ///  "result": [
    ///      "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    ///      "0x5EED00000000000000000000000000005EED0000000000000000000000000000",
    ///      "0xd1ff1c01710000000000000000000000d1ff1c01710000000000000000000000"
    ///    ]
    /// }
    /// ```
    ///
    /// - Returns: Hash of the current block, the seedHash, and the boundary condition to be met ("target").
    public func getWork() -> Promise<WorkInfo> {
        return network.send("eth_getWork").work()
    }
    
    /// Used for submitting a proof-of-work solution.
    ///
    /// ```js
    /// params: [
    ///  "0x0000000000000001",
    ///  "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    ///  "0xD1FE5700000000000000000000000000D1FE5700000000000000000000000000"
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0", "method":"eth_submitWork", "params":["0x0000000000000001", "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef", "0xD1GE5700000000000000000000000000D1GE5700000000000000000000000000"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":73,
    ///  "jsonrpc":"2.0",
    ///  "result": true
    /// }
    /// ```
    ///
    /// - Parameter nonce: `DATA`, 8 Bytes - The nonce found (64 bits)
    /// - Parameter headerPowHash: `DATA`, 32 Bytes - The header's pow-hash (256 bits)
    /// - Parameter mixDigest: `DATA`, 32 Bytes - The mix digest (256 bits)
    ///
    /// - Returns: `Boolean` - returns `true` if the provided solution is valid, otherwise `false`.
    public func submitWork(nonce: UInt64, headerPowHash: Data, mixDigest: Data) -> Promise<Bool> {
        return network.send("eth_submitWork", BigUInt(nonce), headerPowHash, mixDigest).bool()
    }
    
    /// Used for submitting mining hashrate.
    ///
    /// ```js
    /// params: [
    ///  "0x0000000000000000000000000000000000000000000000000000000000500000",
    ///  "0x59daa26581d0acd1fce254fb7e85952f4c09d0915afd33d3886cd914bc7d283c"
    /// ]
    /// ```
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0", "method":"eth_submitHashrate", "params":["0x0000000000000000000000000000000000000000000000000000000000500000", "0x59daa26581d0acd1fce254fb7e85952f4c09d0915afd33d3886cd914bc7d283c"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":73,
    ///  "jsonrpc":"2.0",
    ///  "result": true
    /// }
    /// ```
    ///
    /// - Parameter hashRate: `Hashrate`, a hexadecimal string representation (32 bytes) of the hash rate
    /// - Parameter id: `ID`, String - A random hexadecimal(32 bytes) ID identifying the client
    ///
    /// - Returns: `Boolean` - returns `true` if submitting went through succesfully and `false` otherwise.
    public func submitHashrate(hashRate: Data, id: Data) -> Promise<Bool> {
        return network.send("eth_submitHashrate", hashRate, id).bool()
    }
    
    /// Returns the account- and storage-values of the specified account including the Merkle-proof.
    ///
    /// ```
    /// params: ["0x1234567890123456789012345678901234567890",["0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000001"],"latest"]
    /// ```
    ///
    /// ##### getProof-Example
    /// ```
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getProof","params":["0x1234567890123456789012345678901234567890",["0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000001"],"latest"],"id":1}' -H "Content-type:application/json" http://localhost:8545
    ///
    /// // Result
    /// {
    ///  "jsonrpc": "2.0",
    ///  "id": 1,
    ///  "result": {
    ///    "address": "0x1234567890123456789012345678901234567890",
    ///    "accountProof": [
    ///      "0xf90211a090dcaf88c40c7bbc95a912cbdde67c175767b31173df9ee4b0d733bfdd511c43a0babe369f6b12092f49181ae04ca173fb68d1a5456f18d20fa32cba73954052bda0473ecf8a7e36a829e75039a3b055e51b8332cbf03324ab4af2066bbd6fbf0021a0bbda34753d7aa6c38e603f360244e8f59611921d9e1f128372fec0d586d4f9e0a04e44caecff45c9891f74f6a2156735886eedf6f1a733628ebc802ec79d844648a0a5f3f2f7542148c973977c8a1e154c4300fec92f755f7846f1b734d3ab1d90e7a0e823850f50bf72baae9d1733a36a444ab65d0a6faaba404f0583ce0ca4dad92da0f7a00cbe7d4b30b11faea3ae61b7f1f2b315b61d9f6bd68bfe587ad0eeceb721a07117ef9fc932f1a88e908eaead8565c19b5645dc9e5b1b6e841c5edbdfd71681a069eb2de283f32c11f859d7bcf93da23990d3e662935ed4d6b39ce3673ec84472a0203d26456312bbc4da5cd293b75b840fc5045e493d6f904d180823ec22bfed8ea09287b5c21f2254af4e64fca76acc5cd87399c7f1ede818db4326c98ce2dc2208a06fc2d754e304c48ce6a517753c62b1a9c1d5925b89707486d7fc08919e0a94eca07b1c54f15e299bd58bdfef9741538c7828b5d7d11a489f9c20d052b3471df475a051f9dd3739a927c89e357580a4c97b40234aa01ed3d5e0390dc982a7975880a0a089d613f26159af43616fd9455bb461f4869bfede26f2130835ed067a8b967bfb80",
    ///      "0xf90211a0395d87a95873cd98c21cf1df9421af03f7247880a2554e20738eec2c7507a494a0bcf6546339a1e7e14eb8fb572a968d217d2a0d1f3bc4257b22ef5333e9e4433ca012ae12498af8b2752c99efce07f3feef8ec910493be749acd63822c3558e6671a0dbf51303afdc36fc0c2d68a9bb05dab4f4917e7531e4a37ab0a153472d1b86e2a0ae90b50f067d9a2244e3d975233c0a0558c39ee152969f6678790abf773a9621a01d65cd682cc1be7c5e38d8da5c942e0a73eeaef10f387340a40a106699d494c3a06163b53d956c55544390c13634ea9aa75309f4fd866f312586942daf0f60fb37a058a52c1e858b1382a8893eb9c1f111f266eb9e21e6137aff0dddea243a567000a037b4b100761e02de63ea5f1fcfcf43e81a372dafb4419d126342136d329b7a7ba032472415864b08f808ba4374092003c8d7c40a9f7f9fe9cc8291f62538e1cc14a074e238ff5ec96b810364515551344100138916594d6af966170ff326a092fab0a0d31ac4eef14a79845200a496662e92186ca8b55e29ed0f9f59dbc6b521b116fea090607784fe738458b63c1942bba7c0321ae77e18df4961b2bc66727ea996464ea078f757653c1b63f72aff3dcc3f2a2e4c8cb4a9d36d1117c742833c84e20de994a0f78407de07f4b4cb4f899dfb95eedeb4049aeb5fc1635d65cf2f2f4dfd25d1d7a0862037513ba9d45354dd3e36264aceb2b862ac79d2050f14c95657e43a51b85c80",
    ///      "0xf90171a04ad705ea7bf04339fa36b124fa221379bd5a38ffe9a6112cb2d94be3a437b879a08e45b5f72e8149c01efcb71429841d6a8879d4bbe27335604a5bff8dfdf85dcea00313d9b2f7c03733d6549ea3b810e5262ed844ea12f70993d87d3e0f04e3979ea0b59e3cdd6750fa8b15164612a5cb6567cdfb386d4e0137fccee5f35ab55d0efda0fe6db56e42f2057a071c980a778d9a0b61038f269dd74a0e90155b3f40f14364a08538587f2378a0849f9608942cf481da4120c360f8391bbcc225d811823c6432a026eac94e755534e16f9552e73025d6d9c30d1d7682a4cb5bd7741ddabfd48c50a041557da9a74ca68da793e743e81e2029b2835e1cc16e9e25bd0c1e89d4ccad6980a041dda0a40a21ade3a20fcd1a4abb2a42b74e9a32b02424ff8db4ea708a5e0fb9a09aaf8326a51f613607a8685f57458329b41e938bb761131a5747e066b81a0a16808080a022e6cef138e16d2272ef58434ddf49260dc1de1f8ad6dfca3da5d2a92aaaadc58080",
    ///      "0xf851808080a009833150c367df138f1538689984b8a84fc55692d3d41fe4d1e5720ff5483a6980808080808080808080a0a319c1c415b271afc0adcb664e67738d103ac168e0bc0b7bd2da7966165cb9518080"
    ///    ],
    ///    "balance": "0x0",
    ///    "codeHash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
    ///    "nonce": "0x0",
    ///    "storageHash": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
    ///    "storageProof": [
    ///      {
    ///        "key": "0x0000000000000000000000000000000000000000000000000000000000000000",
    ///        "value": "0x0",
    ///        "proof": []
    ///      },
    ///      {
    ///        "key": "0x0000000000000000000000000000000000000000000000000000000000000001",
    ///        "value": "0x0",
    ///        "proof": []
    ///      }
    
    ///    ]
    ///  }
    /// }
    /// ```
    ///
    /// - Parameter address: `DATA`, 20 bytes - address of the account or contract
    /// - Parameter keys: `ARRAY`, 32 Bytes - array of storage-keys which should be proofed and included. See eth_getStorageAt
    /// - Parameter block: `QUANTITY|TAG` - integer block number, or the string "latest" or "earliest", see the default block parameter
    ///
    /// - Returns: A account object
    public func getProof(address: Address, keys: [Data], block: BlockNumber) -> Promise<ProofInfo> {
        return network.send("eth_getProof", address, JArray(keys), block).proof()
    }
}

private func _bool(_ data: AnyReader) throws -> Bool {
    return try data.bool()
}
func _data(_ data: AnyReader) throws -> Data {
    return try data.data()
}
private func _string(_ data: AnyReader) throws -> String {
    return try data.string()
}
private func _int(_ data: AnyReader) throws -> Int {
    return try data.int()
}
private func _uint256(_ data: AnyReader) throws -> BigUInt {
    return try data.uint256()
}
private func _address(_ data: AnyReader) throws -> Address {
    return try data.address()
}
private func _block(_ data: AnyReader) throws -> BlockInfo? {
    guard !data.isNull() else { return nil }
    return try BlockInfo(data)
}
private func _transaction(_ data: AnyReader) throws -> TransactionInfo? {
    guard !data.isNull() else { return nil }
    return try TransactionInfo(data)
}
private func _transactionReceipt(_ data: AnyReader) throws -> TransactionReceiptInfo? {
    guard !data.isNull() else { return nil }
    return try TransactionReceiptInfo(data)
}
private func _filterChanges(_ data: AnyReader) throws -> FilterChanges {
    return try FilterChanges(data)
}
private func _work(_ data: AnyReader) throws -> WorkInfo {
    return try WorkInfo(data)
}
private func _proof(_ data: AnyReader) throws -> ProofInfo {
    return try ProofInfo(data)
}
private func _shhMessage(_ data: AnyReader) throws -> ShhMessage {
    return try ShhMessage(data)
}
private func _shhAddress(_ data: AnyReader) throws -> ShhAddress {
    return try ShhAddress(data)
}
extension Promise where T == AnyReader {
    func bool() -> Promise<Bool> {
        return map(on: .web3, _bool)
    }
    func data() -> Promise<Data> {
        return map(on: .web3, _data)
    }
    func string() -> Promise<String> {
        return map(on: .web3, _string)
    }
    func int() -> Promise<Int> {
        return map(on: .web3, _int)
    }
    func uint256() -> Promise<BigUInt> {
        return map(on: .web3, _uint256)
    }
    func address() -> Promise<Address> {
        return map(on: .web3, _address)
    }
    func block() -> Promise<BlockInfo?> {
        return map(on: .web3, _block)
    }
    func transaction() -> Promise<TransactionInfo?> {
        return map(on: .web3, _transaction)
    }
    func transactionReceipt() -> Promise<TransactionReceiptInfo?> {
        return map(on: .web3, _transactionReceipt)
    }
    func filterChanges() -> Promise<FilterChanges> {
        return map(on: .web3, _filterChanges)
    }
    func work() -> Promise<WorkInfo> {
        return map(on: .web3, _work)
    }
    func proof() -> Promise<ProofInfo> {
        return map(on: .web3, _proof)
    }
    func shhAddress() -> Promise<ShhAddress> {
        return map(on: .web3, _shhAddress)
    }
    func shhMessages() -> Promise<[ShhMessage]> {
        return array(_shhMessage)
    }
    func array<T>(_ convert: @escaping (AnyReader)throws->(T)) -> Promise<[T]> {
        return map(on: .web3) { try $0.array().map(convert) }
    }
}
