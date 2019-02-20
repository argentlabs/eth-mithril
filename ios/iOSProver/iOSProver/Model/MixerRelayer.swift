//
//  MixerRelayer.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 12/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import Web3

class MixerRelayer {
    
    private let mixer: DynamicContract
    private let relayer: Relayer
    
    init(web3: Web3,
         endPoint: String,
         mixer: DynamicContract) {
        self.relayer = Relayer(web3: web3, endPoint: endPoint)
        self.mixer = mixer
    }
    
    func commit(leaf: BigUInt,
                funderAddress: EthereumAddress,
                txWasSubmitted: TransactionSubmittedCallback? = nil,
                txWasMined: TransactionMinedCallback? = nil) {
        
        guard
            let mixerAddr = mixer.address?.hex(eip55: true),
            let method = mixer["commit"],
            let data = try? ABI.encodeFunctionCall(method(leaf, funderAddress))
        else {
            txWasSubmitted?(nil, Relayer.RelayerError.invalidRelayerParam("Could not encode call"))
            return
        }
        
        // using 100_000 gas (0x0186A0)
        relayer.send(to: mixerAddr, data: data, gas: "0x0186A0", txWasSubmitted: txWasSubmitted, txWasMined: txWasMined)
    }
    
    func withdraw(fundedAddress: EthereumAddress,
                  nullifier: BigUInt,
                  flatProof: [BigUInt],
                  txWasSubmitted: TransactionSubmittedCallback? = nil,
                  txWasMined: TransactionMinedCallback? = nil) {
        
        guard
            let mixerAddr = mixer.address?.hex(eip55: true),
            let method = mixer["withdraw"],
            let data = try? ABI.encodeFunctionCall(method(fundedAddress, nullifier, flatProof))
        else {
            txWasSubmitted?(nil, Relayer.RelayerError.invalidRelayerParam("Could not encode call"))
            return
        }
        
        // using 1_000_000 gas (0x0F4240)
        relayer.send(to: mixerAddr, data: data, gas: "0x0F4240", txWasSubmitted: txWasSubmitted, txWasMined: txWasMined)
    }
    
}


