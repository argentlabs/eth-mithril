//
//  Config.swift
//  Hopper
//
//  Created by Olivier van den Biggelaar on 11/06/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation

class Config {
    
    static let shared: Config = Config()
    private init() {}

    static let configFilename = "config"
    static let abiFilename = "Mixer"
    
    static var deployments: [String: Any]? {
        return (deserialized?["deployments"] as? [String: [String: Any]])?.mapValues({ cfg -> [String: Any] in
            var cfg = cfg
            if cfg["contractAddress"] == nil, let chainId = cfg["chainId"] as? Int {
                cfg["contractAddress"] = deployedAddressFromAbi(chainId: chainId)
            }
            return cfg
        })
    }
    
    private static var deserialized: [String: Any]? {
        guard
            let url = Bundle.main.url(forResource: configFilename, withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
            else { return nil }
        
        return (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any]
    }
    
    private static func deployedAddressFromAbi(chainId: Int) -> String? {
        guard
            let url = Bundle.main.url(forResource: abiFilename, withExtension: "json"),
            let jsonData = try? Data(contentsOf: url),
            let networks = ((try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any])?["networks"] as? [String: Any]
        else { return nil }
        return (networks[String(chainId)] as? [String: Any])?["address"] as? String
    }
    
}
