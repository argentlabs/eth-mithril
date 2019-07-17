//
//  MixerManager.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 14/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import Web3
import struct web3swift.Swift.EventParserResult

class MixerManager {
    
    enum MixerError: Error {
        case contractCallFailed(String)
        case invalidParams(String)
        case internalError(String)
        case unexpectedDataReceived(String)
    }
    
    static let shared: MixerManager = MixerManager()
    
    private let prover = Prover.shared
    
    private init() {}

    // MARK: - Helper functions to compute call parameters
    
    private func computeLeaf(_ nullifierSecret: BigUInt, _ fundedAddress: EthereumAddress) -> BigUInt? {
        let nullifierSecretData = nullifierSecret.solidityData
        let fundedAddressData = fundedAddress.ethereumValue().ethereumQuantity!.quantity.solidityData
        let digest = (nullifierSecretData+fundedAddressData).sha256.hex
        let digestAfterClearingFirst4Bits = "0" + digest.dropFirst()
        return BigUInt(hexString: digestAfterClearingFirst4Bits)
    }
    
    func getLeaf(nullifierSecret: BigUInt,
                 fundedAddress: EthereumAddress,
                 computeLocally: Bool = true,
                 rpcPath: String? = nil,
                 mixerAddressStr: String? = nil) -> Promise<BigUInt> {
        if(computeLocally) {
            // compute leaf locally
            let leaf = computeLeaf(nullifierSecret, fundedAddress)
            return Promise { $0.resolve(leaf, nil) }
        }
        
        // compute leaf via Infura (unsafe!)
        return Promise { seal in
            MixerFactory.mixer(rpcPath: rpcPath!, mixerAddressStr: mixerAddressStr!)?["makeLeafHash"]?(
                nullifierSecret,
                fundedAddress
            ).call { (result, error) in
                seal.resolve(result?[""] as? BigUInt, error)
            }
        }
    }
    
    func getNullifier(nullifierSecret: BigUInt,
                      computeLocally: Bool = true,
                      rpcPath: String? = nil,
                      mixerAddressStr: String? = nil) -> Promise<BigUInt>  {
        if(computeLocally) {
            // compute nullifier locally
            let nullifier = MiMC.hash(in_msgs: [nullifierSecret, nullifierSecret])
            return Promise { $0.resolve(nullifier, nil) }
        }
        
        // compute nullifier via Infura (unsafe!)
        return Promise { seal in
            MixerFactory.mixer(rpcPath: rpcPath!, mixerAddressStr: mixerAddressStr!)?["makeNullifierHash"]?(
                nullifierSecret
            ).call { (result, error) in
                seal.resolve(result?[""] as? BigUInt, error)
            }
        }
    }
    
    func getMerklePath(leafIndex: BigUInt,
                       rpcPath: String,
                       mixerAddressStr: String) -> Promise<[BigUInt]>  {
        return Promise { seal in
            MixerFactory.mixer(rpcPath: rpcPath, mixerAddressStr: mixerAddressStr)?["getMerklePath"]?(
                leafIndex
            ).call { (result, error) in
                seal.resolve(result?["out_path"] as? [BigUInt], error)
            }
        }
    }
    
    func getRoot(rpcPath: String,
                 mixerAddressStr: String) -> Promise<BigUInt>  {
        return Promise { seal in
            MixerFactory.mixer(rpcPath: rpcPath, mixerAddressStr: mixerAddressStr)?["getRoot"]?(
            ).call { (result, error) in
                seal.resolve(result?[""] as? BigUInt, error)
            }
        }
    }
    
    private var mixerRelayers = [String: MixerRelayer]()
    private func mixerRelayer(for mixerId: String) throws -> MixerRelayer  {
        if mixerRelayers[mixerId] == nil {
            guard
                let rpcUrl = ConfigParser.shared.rpcUrl(for: mixerId),
                let mixerAddressStr = ConfigParser.shared.mixerAddress(for: mixerId),
                let relayerEndpoint = ConfigParser.shared.relayerEndpoint(for: mixerId),
                let mixerContract = MixerFactory.mixer(rpcPath: rpcUrl, mixerAddressStr: mixerAddressStr)
            else { throw MixerError.invalidParams("Invalid mixer config for \"\(mixerId)\"") }
            mixerRelayers[mixerId] = MixerRelayer(rpcPath: rpcUrl, endPoint: relayerEndpoint, mixerContract: mixerContract)
        }
        return mixerRelayers[mixerId]!
    }
    
    // MARK: - Methods used by Views
    
    func getCommitData(for mixerId: String, nullifierSecret: BigUInt, fundedAddress: EthereumAddress) -> String? {
        guard
            let rpcUrl = ConfigParser.shared.rpcUrl(for: mixerId),
            let mixerAddressStr = ConfigParser.shared.mixerAddress(for: mixerId),
            let mixerContract = MixerFactory.mixer(rpcPath: rpcUrl, mixerAddressStr: mixerAddressStr),
            let method = mixerContract["commit"],
            let leaf = computeLeaf(nullifierSecret, fundedAddress),
            let data = try? ABI.encodeFunctionCall(method(leaf))
        else { return nil }
        return data
    }
    
    // MARK: - Contract convenience methods
    
    func watchFundingEvent(mixerId: String,
                           fundedAddress: EthereumAddress,
                           secret: BigUInt,
                           startBlock: UInt64 = 5_500_000,
                           commitmentWasFunded: @escaping (_ result: (blockNumber: UInt64, leafIndex: BigUInt)?, _ error: Error?) -> ()) {
        guard let abiData = MixerFactory.abiData else {
            commitmentWasFunded(nil, MixerError.invalidParams("Invalid ABI"))
            return
        }

        firstly {
            getLeaf(nullifierSecret: secret, fundedAddress: fundedAddress)
        }.then { leaf -> Promise<[EventParserResult]> in
            guard
                let rpcPath = ConfigParser.shared.rpcUrl(for: mixerId),
                let mixerAddressStr = ConfigParser.shared.mixerAddress(for: mixerId)
            else { throw MixerError.invalidParams("Invalid mixer config for \"\(mixerId)\"") }
            
            return EventFetcher.fetchEventsPromise(
                rpcPath: rpcPath,
                name: "LeafAdded",
                abiData: abiData,
                contractAddress: mixerAddressStr,
                startBlock: startBlock,
                pollingPeriod: 5,
                filters: ["_leaf": leaf])
        }.done { result in
            guard
                let last = result.last,
                let leafIdx = last.decodedResult["_leafIndex"] as? BigUInt,
                let blockStr = last.eventLog?.blockNumber.description,
                let block = UInt64(blockStr)
            else {
                throw MixerError.unexpectedDataReceived("Could not parse funding event result")
            }
            commitmentWasFunded((block, leafIdx), nil)
        }.catch { error in
            commitmentWasFunded(nil, error)
        }
    }
    
    func watchAllFundingEvents(mixerId: String,
                               startBlock: UInt64 = 5_500_000,
                               shouldKeepWatching: (() -> Bool)? = nil,
                               commitmentWasFunded: @escaping (_ result: (blockNumber: UInt64, numDeposits: Int)?, _ error: Error?) -> ()) {
        guard let abiData = MixerFactory.abiData else {
            commitmentWasFunded(nil, MixerError.invalidParams("Invalid ABI"))
            return
        }
        
        firstly { () -> Promise<[EventParserResult]> in
            guard
                let rpcPath = ConfigParser.shared.rpcUrl(for: mixerId),
                let mixerAddressStr = ConfigParser.shared.mixerAddress(for: mixerId)
            else { throw MixerError.invalidParams("Invalid mixer config for \"\(mixerId)\"") }
            return EventFetcher.fetchEventsPromise(
                rpcPath: rpcPath,
                name: "LeafAdded",
                abiData: abiData,
                contractAddress: mixerAddressStr,
                startBlock: startBlock,
                pollingPeriod: 5,
                shouldKeepWatching: shouldKeepWatching)
        }.done { result in
            guard
                let blockStr = result.last?.eventLog?.blockNumber.description,
                let block = UInt64(blockStr)
            else {
                throw MixerError.unexpectedDataReceived("Could not parse funding event result")
            }
            commitmentWasFunded((block, result.count), nil)
        }.catch { error in
            commitmentWasFunded(nil, error)
        }
    }
    
    func withdraw(mixerId: String,
                  fundedAddress: EthereumAddress,
                  secret: BigUInt,
                  leafIndex: BigUInt,
                  proofWasComputed: (() -> ())? = nil,
                  txWasSubmitted: TransactionSubmittedCallback? = nil,
                  txWasMined: TransactionMinedCallback? = nil) {
        var nullifier: BigUInt!
        var merklePath = [BigUInt]()
        
        guard
            let rpcPath = ConfigParser.shared.rpcUrl(for: mixerId),
            let mixerAddressStr = ConfigParser.shared.mixerAddress(for: mixerId),
            let mixerRelayer = try? mixerRelayer(for: mixerId)
        else {
            txWasSubmitted?(nil, MixerError.invalidParams("Invalid mixer config for \"\(mixerId)\""))
            return
        }
        
        firstly { () -> Promise<[BigUInt]> in
            return getMerklePath(leafIndex: leafIndex, rpcPath: rpcPath, mixerAddressStr: mixerAddressStr)
        }.then { [weak self] mpath -> Promise<BigUInt> in
            guard let this = self else { throw MixerError.internalError("self is nil") }
            merklePath = mpath
            return this.getNullifier(nullifierSecret: secret)
        }.then { [weak self] null -> Promise<BigUInt> in
            guard let this = self else { throw MixerError.internalError("self is nil") }
            nullifier = null
            return this.getRoot(rpcPath: rpcPath, mixerAddressStr: mixerAddressStr)
        }.then { [weak self] root -> Promise<[BigUInt]> in
            guard let this = self else { throw MixerError.internalError("self is nil") }
            return this.prover.buildFlatProofPromise(root: root,
                                                     fundedAddress: fundedAddress,
                                                     nullifier: nullifier,
                                                     nullifierSecret: secret,
                                                     leafIndex: leafIndex,
                                                     merklePath: merklePath)
        }.done { flatProof in
            proofWasComputed?()
            mixerRelayer.withdraw(fundedAddress: fundedAddress,
                                  nullifier: nullifier,
                                  flatProof: flatProof,
                                  txWasSubmitted: txWasSubmitted,
                                  txWasMined: txWasMined)
        }.catch { error in
            txWasSubmitted?(nil, error)
        }
    }
}
