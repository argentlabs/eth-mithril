//
//  MixerRelayer.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 12/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import Web3
import struct web3swift.Swift.EventParserResult

class MixerRelayer {
    
    private let mixerContract: DynamicContract
    private let relayer: Relayer
    private let rpcPath: String
    
    init(rpcPath: String,
         endPoint: String,
         mixerContract: DynamicContract) {
        self.rpcPath = rpcPath
        self.relayer = Relayer(rpcPath: rpcPath, endPoint: endPoint)
        self.mixerContract = mixerContract
    }
    
    func withdraw(fundedAddress: EthereumAddress,
                  nullifier: BigUInt,
                  flatProof: [BigUInt],
                  txWasSubmitted: TransactionSubmittedCallback? = nil,
                  txWasMined: TransactionMinedCallback? = nil) {
        
        guard
            let mixerAddr = mixerContract.address?.hex(eip55: true),
            let method = mixerContract["withdraw"],
            let data = try? ABI.encodeFunctionCall(method(fundedAddress, nullifier, flatProof))
        else {
            txWasSubmitted?(nil, Relayer.RelayerError.invalidRelayerParam("Could not encode call"))
            return
        }
        
        var withdrawConfirmed = false
        relayer.send(to: mixerAddr,
                     data: data,
                     gas: "0x0F4240", // using 1_000_000 gas (0x0F4240)
                     txWasSubmitted: { [weak self] (txHash: EthereumData?, error: Error?) in
                        if txHash != nil {
                            self?.watchWithdrawalEvent(nullifier: nullifier,
                                                       pollingPeriod: 2,
                                                       shouldKeepWatching: { !withdrawConfirmed },
                                                       depositWasWithdrawn: { (blockNum, err) in
                                                        if !withdrawConfirmed, blockNum != nil {
                                                            withdrawConfirmed = true
                                                            txWasMined?(true, blockNum)
                                                        }
                            })
                        }
            txWasSubmitted?(txHash, error)
        }, txWasMined: { [weak self] (success: Bool, blockNum: UInt64?) in
            if !withdrawConfirmed {
                if !success {
                    // The withdrawal reverted. Let's look one last time for a DepositWithdrawn event, in case we were frontrun
                    self?.watchWithdrawalEvent(nullifier: nullifier,
                                               pollingPeriod: nil,
                                               depositWasWithdrawn: { (eventBlockNum, err) in
                        withdrawConfirmed = true
                        txWasMined?(eventBlockNum != nil, eventBlockNum ?? blockNum)
                    })
                } else {
                    withdrawConfirmed = true
                    txWasMined?(success, blockNum)
                }
            }
        })
    }
    
    // Private methods
    
    private func watchWithdrawalEvent(nullifier: BigUInt,
                                      startBlock: UInt64 = 5_500_000,
                                      pollingPeriod: TimeInterval?,
                                      shouldKeepWatching: (() -> Bool)? = nil,
                                      depositWasWithdrawn: @escaping (_ blockNumber: UInt64?, _ error: Error?) -> ()) {
        guard let abiData = MixerFactory.abiData else {
            depositWasWithdrawn(nil, Relayer.RelayerError.invalidRelayerParam("Invalid ABI"))
            return
        }
        
        firstly { () -> Promise<[EventParserResult]> in
            guard let mixerAddressStr = mixerContract.address?.hex(eip55: true)
            else { throw Relayer.RelayerError.invalidRelayerParam("Mixer address is nil") }
            
            return EventFetcher.fetchEventsPromise(
                rpcPath: rpcPath,
                name: "DepositWithdrawn",
                abiData: abiData,
                contractAddress: mixerAddressStr,
                startBlock: startBlock,
                pollingPeriod: pollingPeriod,
                shouldKeepWatching: shouldKeepWatching,
                filters: ["_nullifier": nullifier])
            }.done { result in
                guard
                    let last = result.last,
                    let blockStr = last.eventLog?.blockNumber.description,
                    let block = UInt64(blockStr)
                else {
                    throw Relayer.RelayerError.unexpectedDataReceived("No withdrawal found")
                }
                depositWasWithdrawn(block, nil)
            }.catch { error in
                depositWasWithdrawn(nil, error)
        }
    }
    
}


