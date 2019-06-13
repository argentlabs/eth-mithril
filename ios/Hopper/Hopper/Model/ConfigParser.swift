//
//  Config.swift
//  Hopper
//
//  Created by Olivier van den Biggelaar on 11/06/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation

class ConfigParser {
    
    static let shared: ConfigParser = ConfigParser()
    private init() {}

    let configFilename = "config"
    let abiFilename = "Mixer"
    
    var mixers: [String: Any] {
        return (deserialized?["deployments"] as? [String: [String: Any]])?.mapValues({ cfg -> [String: Any] in
            var cfg = cfg
            if cfg["mixerAddress"] as? String == nil, let chainId = cfg["chainId"] as? Int {
                cfg["mixerAddress"] = deployedAddressFromAbi(chainId: chainId)
            }
            return cfg
        }) ?? [:]
    }
    
    var sortedMixerIds: [String] {
        return mixers.keys.filter {
            (mixers[$0] as? [String: Any])?["legacy"] as? Bool != true
        }.sorted {
            (mixers[$0] as? [String: Any])?["sortKey"] as? Int ?? 0
            <
            (mixers[$1] as? [String: Any])?["sortKey"] as? Int ?? 0
        }
    }
    
    func network(for mixerId: String) -> String? {
        return stringParam(for: mixerId, key: "network")
    }
    func value(for mixerId: String) -> String? {
        return stringParam(for: mixerId, key: "value")
    }
    func rpcUrl(for mixerId: String) -> String? {
        return stringParam(for: mixerId, key: "rpcUrl")
    }
    func relayerEndpoint(for mixerId: String) -> String? {
        return stringParam(for: mixerId, key: "relayerEndpoint")
    }
    func mixerAddress(for mixerId: String) -> String? {
        return stringParam(for: mixerId, key: "mixerAddress")
    }
    
    private func stringParam(for mixerId: String, key: String) -> String? {
        return (mixers[mixerId] as? [String: Any])?[key] as? String
    }
    
     private var deserialized: [String: Any]? {
        guard
            let url = Bundle.main.url(forResource: configFilename, withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
            else { return nil }
        
        return (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any]
    }
    
    private func deployedAddressFromAbi(chainId: Int) -> String? {
        guard
            let url = Bundle.main.url(forResource: abiFilename, withExtension: "json"),
            let jsonData = try? Data(contentsOf: url),
            let networks = ((try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any])?["networks"] as? [String: Any]
        else { return nil }
        return (networks[String(chainId)] as? [String: Any])?["address"] as? String
    }
    
}
