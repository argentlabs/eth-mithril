//
//  MixerFactory.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 14/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import Web3

class MixerFactory {
    static let abiFilename = "Mixer"
    
    static var abiData: Data? {
        guard
            let url = Bundle.main.url(forResource: abiFilename, withExtension: "json"),
            let jsonData = try? Data(contentsOf: url),
            let abi = ((try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any])?["abi"] as? [[String: Any]]
            else { return nil }
        let noFallbackAbi = abi.filter { $0["type"] as? String != "fallback"}

        return try? JSONSerialization.data(withJSONObject: noFallbackAbi, options: [])
    }
    
    static func mixer(web3: Web3, mixerAddressStr: String) -> DynamicContract? {
        guard
            let abiData = abiData,
            let mixerAddress = EthereumAddress(hexString: mixerAddressStr),
            let mixer = try? web3.eth.Contract(json: abiData, abiKey: nil, address: mixerAddress)
        else { return nil }

        return mixer
    }
}
