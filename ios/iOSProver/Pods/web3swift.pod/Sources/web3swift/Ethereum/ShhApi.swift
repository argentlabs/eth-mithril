//
//  ShhApi.swift
//  web3swift
//
//  Created by Dmitry on 20/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import BigInt

/// Shh ethereum api. Doesn't works on infura networks
public struct ShhApi {
    var parent: EthereumApi
    var network: NetworkProvider { return parent.network }
    init(parent: EthereumApi) {
        self.parent = parent
    }
    
    /// Returns the current whisper protocol version.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_version","params":[],"id":67}'
    ///
    /// // Result
    /// {
    ///  "id":67,
    ///  "jsonrpc": "2.0",
    ///  "result": "2"
    /// }
    /// ```
    ///
    /// - Returns: `String` - The current whisper protocol version
    public func version() -> Promise<String> {
        return network.send("shh_version").string()
    }
    
    /// Sends a whisper message.
    ///
    /// ```js
    /// params: [{
    ///  from: "0x04f96a5e25610293e42a73908e93ccc8c4d4dc0edcfa9fa872f50cb214e08ebf61a03e245533f97284d442460f2998cd41858798ddfd4d661997d3940272b717b1",
    ///  to: "0x3e245533f97284d442460f2998cd41858798ddf04f96a5e25610293e42a73908e93ccc8c4d4dc0edcfa9fa872f50cb214e08ebf61a0d4d661997d3940272b717b1",
    ///  topics: ["0x776869737065722d636861742d636c69656e74", "0x4d5a695276454c39425154466b61693532"],
    ///  payload: "0x7b2274797065223a226d6",
    ///  priority: "0x64",
    ///  ttl: "0x64",
    /// }]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_post","params":[{"from":"0xc931d93e97ab07fe42d923478ba2465f2..","topics": ["0x68656c6c6f20776f726c64"],"payload":"0x68656c6c6f20776f726c64","ttl":0x64,"priority":0x64}],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":"2.0",
    ///  "result": true
    /// }
    /// ```
    ///
    /// - Parameter : `Object` - The whisper post object:
    /// - Parameter from: `DATA`, 60 Bytes - (optional) The identity of the sender.
    /// - Parameter to: `DATA`, 60 Bytes - (optional) The identity of the receiver. When present whisper will encrypt the message so that only the receiver can decrypt it.
    /// - Parameter topics: `Array of DATA` - Array of `DATA` topics, for the receiver to identify messages.
    /// - Parameter payload: `DATA` - The payload of the message.
    /// - Parameter priority: `QUANTITY` - The integer of the priority in a range from ... (?).
    /// - Parameter ttl: `QUANTITY` - integer of the time to live in seconds.
    ///
    /// - Returns: `Boolean` - returns `true` if the message was send, otherwise `false`.
    public func post(from: ShhAddress, to: ShhAddress, topics: [Data], payload: Data, priority: BigUInt, ttl: Int) -> Promise<Bool> {
        let request = JDictionary()
            .set("from", from)
            .set("to", to)
            .set("topics", JArray(topics))
            .set("payload", payload)
            .set("priority", priority)
            .set("ttl", ttl)
        return network.send("shh_post", request).bool()
    }
    
    /// Creates new whisper identity in the client.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_newIdentity","params":[],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xc931d93e97ab07fe42d923478ba2465f283f440fd6cabea4dd7a2c807108f651b7135d1d6ca9007d5b68aa497e4619ac10aa3b27726e1863c1fd9b570d99bbaf"
    /// }
    /// ```
    ///
    /// - Returns: `DATA`, 60 Bytes - the address of the new identiy.
    public func newIdentity() -> Promise<ShhAddress> {
        return network.send("shh_newIdentity").shhAddress()
    }
    
    /// Checks if the client hold the private keys for a given identity.
    ///
    /// ```js
    /// params: [
    ///  "0x04f96a5e25610293e42a73908e93ccc8c4d4dc0edcfa9fa872f50cb214e08ebf61a03e245533f97284d442460f2998cd41858798ddfd4d661997d3940272b717b1"
    /// ]
    /// ```
    ///
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_hasIdentity","params":["0x04f96a5e25610293e42a73908e93ccc8c4d4dc0edcfa9fa872f50cb214e08ebf61a03e245533f97284d442460f2998cd41858798ddfd4d661997d3940272b717b1"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": true
    /// }
    /// ```
    ///
    /// - Parameter id: `DATA`, 60 Bytes - The identity address to check.
    ///
    /// - Returns: `Boolean` - returns `true` if the client holds the privatekey for that identity, otherwise `false`.
    public func hasIdentity(id: ShhAddress) -> Promise<Bool> {
        return network.send("shh_hasIdentity", id).bool()
    }
    
    /// Creates a new group.
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_newGroup","params":[],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": "0xc65f283f440fd6cabea4dd7a2c807108f651b7135d1d6ca90931d93e97ab07fe42d923478ba2407d5b68aa497e4619ac10aa3b27726e1863c1fd9b570d99bbaf"
    /// }
    /// ```
    ///
    /// - Returns: `DATA`, 60 Bytes - the address of the new group.
    public func newGroup() -> Promise<ShhAddress> {
        return network.send("shh_newGroup").shhAddress()
    }
    
    /// Adds a whisper identity to the group.
    ///
    /// ```js
    /// params: [
    ///  "0x04f96a5e25610293e42a73908e93ccc8c4d4dc0edcfa9fa872f50cb214e08ebf61a03e245533f97284d442460f2998cd41858798ddfd4d661997d3940272b717b1"
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_addToGroup","params":["0x04f96a5e25610293e42a73908e93ccc8c4d4dc0edcfa9fa872f50cb214e08ebf61a03e245533f97284d442460f2998cd41858798ddfd4d661997d3940272b717b1"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc": "2.0",
    ///  "result": true
    /// }
    /// ```
    ///
    /// - Parameter : `DATA`, 60 Bytes - The identity address to add to a group.
    ///
    /// - Returns: `Boolean` - returns `true` if the identity was successfully added to the group, otherwise `false`.
    public func addToGroup() -> Promise<Bool> {
        return network.send("shh_addToGroup").bool()
    }
    
    /// Creates filter to notify, when client receives whisper message matching the filter options.
    ///
    ///
    /// ```js
    /// params: [{
    ///   "topics": ['0x12341234bf4b564f'],
    ///   "to": "0x04f96a5e25610293e42a73908e93ccc8c4d4dc0edcfa9fa872f50cb214e08ebf61a03e245533f97284d442460f2998cd41858798ddfd4d661997d3940272b717b1"
    /// }]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_newFilter","params":[{"topics": ['0x12341234bf4b564f'],"to": "0x2341234bf4b2341234bf4b564f..."}],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":"2.0",
    ///  "result": "0x7" // 7
    /// }
    /// ```
    ///
    /// - Parameter to: `DATA`, 60 Bytes - (optional) Identity of the receiver. *When present it will try to decrypt any incoming message if the client holds the private key to this identity.*
    /// - Parameter topics: `Array of DATA` - Array of `DATA` topics which the incoming message's topics should match.  You can use the following combinations:
    ///    - `[A, B] = A && B`
    ///    - `[A, [B, C]] = A && (B || C)`
    ///    - `[null, A, B] = ANYTHING && A && B` `null` works as a wildcard
    ///
    /// - Returns: `QUANTITY` - The newly created filter.
    public func newFilter(to: Data, topics: TopicFilters) -> Promise<BigUInt> {
        return network.send("shh_newFilter").uint256()
    }
    
    /// Uninstalls a filter with given id. Should always be called when watch is no longer needed.
    /// Additonally Filters timeout when they aren't requested with [shh_getFilterChanges](#shh_getfilterchanges) for a period of time.
    ///
    /// ```js
    /// params: [
    ///  "0x7" // 7
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_uninstallFilter","params":["0x7"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":"2.0",
    ///  "result": true
    /// }
    /// ```
    ///
    /// - Parameter id: The filter id.
    ///
    /// - Returns: `Boolean` - `true` if the filter was successfully uninstalled, otherwise `false`.
    public func uninstallFilter(id: BigUInt) -> Promise<Bool> {
        return network.send("shh_uninstallFilter").bool()
    }
    
    /// Polling method for whisper filters. Returns new messages since the last call of this method.
    ///
    /// - Note: calling the [shh_getMessages](#shh_getmessages) method, will reset the buffer for this method, so that you won't receive duplicate messages.
    ///
    ///
    ///
    /// ```js
    /// params: [
    ///  "0x7" // 7
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_getFilterChanges","params":["0x7"],"id":73}'
    ///
    /// // Result
    /// {
    ///  "id":1,
    ///  "jsonrpc":"2.0",
    ///  "result": [{
    ///    "hash": "0x33eb2da77bf3527e28f8bf493650b1879b08c4f2a362beae4ba2f71bafcd91f9",
    ///    "from": "0x3ec052fc33..",
    ///    "to": "0x87gdf76g8d7fgdfg...",
    ///    "expiry": "0x54caa50a", // 1422566666
    ///    "sent": "0x54ca9ea2", // 1422565026
    ///    "ttl": "0x64", // 100
    ///    "topics": ["0x6578616d"],
    ///    "payload": "0x7b2274797065223a226d657373616765222c2263686...",
    ///    "workProved": "0x0"
    ///    }]
    /// }
    /// ```
    ///
    /// - Parameter id: `QUANTITY` - The filter id.
    ///
    /// - Returns: `Array` - Array of messages received since last poll
    public func getFilterChanges(id: BigUInt) -> Promise<[ShhMessage]> {
        return network.send("shh_getFilterChanges", id).shhMessages()
    }
    
    /// Get all messages matching a filter. Unlike `shh_getFilterChanges` this returns all messages.
    ///
    /// ```js
    /// params: [
    ///  "0x7" // 7
    /// ]
    /// ```
    ///
    /// ##### Example
    /// ```js
    /// // Request
    /// curl -X POST --data '{"jsonrpc":"2.0","method":"shh_getMessages","params":["0x7"],"id":73}'
    /// ```
    ///
    /// - Parameter id: `QUANTITY` - The filter id.
    ///
    /// - Returns: `Array` - Array of messages received
    public func getMessages(id: BigUInt) -> Promise<[ShhMessage]> {
        return network.send("shh_getMessages").shhMessages()
    }
}

private extension AnyReader {
    func shhAddress() throws -> ShhAddress {
        return try ShhAddress(self)
    }
}

/// 60 bytes address used in shh api
public class ShhAddress: JEncodable {
    /// Address data
    public let data: Data
    /// Init with data
    public init(_ data: Data) {
        self.data = data
    }
    /// Init with AnyReader
    public init(_ json: AnyReader) throws {
        data = try json.data()
    }
    
    public func jsonRpcValue(with network: NetworkProvider) -> Any {
        return data.jsonRpcValue(with: network)
    }
}

public class ShhMessage {
    /// hash: DATA, 32 Bytes (?) - The hash of the message.
    public let hash: Data
    /// from: DATA, 60 Bytes - The sender of the message, if a sender was specified.
    public let from: ShhAddress
    /// to: DATA, 60 Bytes - The receiver of the message, if a receiver was specified.
    public let to: ShhAddress
    /// expiry: QUANTITY - Integer of the time in seconds when this message should expire (?).
    public let expiry: Int
    /// ttl: QUANTITY - Integer of the time the message should float in the system in seconds (?).
    public let ttl: Int
    /// sent: QUANTITY - Integer of the unix timestamp when the message was sent.
    public let sent: Int
    /// topics: Array of DATA - Array of DATA topics the message contained.
    public let topics: [Data]
    /// payload: DATA - The payload of the message.
    public let payload: Data
    /// workProved: QUANTITY - Integer of the work this message required before it was send (?).
    public let workProved: Int
    public init(_ json: AnyReader) throws {
        hash = try json.at("hash").data()
        from = try json.at("from").shhAddress()
        to = try json.at("to").shhAddress()
        expiry = try json.at("expiry").int()
        ttl = try json.at("ttl").int()
        sent = try json.at("sent").int()
        topics = try json.at("topics").array(_data)
        payload = try json.at("payload").data()
        workProved = try json.at("workProved").int()
    }
}
