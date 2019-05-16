//
//  Prover.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 15/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import Web3

class Prover {
    
    enum ProverError : Error {
        case couldNotGenerateProof
        case couldNotDeserializeProof
        case missingVerificationKey
        case missingProvingKey
    }
    
    static let shared = Prover()
    
    private let mixerTreeDepth = mixer_tree_depth();
    private let pkPath = Bundle.main.path(forResource: "mixer.pk", ofType: "raw")
    lazy var vk: String? = {
        guard
            let jsonURL = Bundle.main.url(forResource: "mixer.vk", withExtension: "json"),
            let jsonData = try? Data(contentsOf: jsonURL) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }()
    
    private init() {}
    
    private func withArrayOfCStrings<R>(_ args: [String], _ body: ([UnsafePointer<CChar>?]) -> R) -> R {
        var cStrings = args.map { UnsafePointer(strdup($0)) }
        cStrings.append(nil)
        defer { cStrings.forEach { free(UnsafeMutablePointer(mutating: $0)) } }
        return body(cStrings)
    }
    
    func buildProof(root: BigUInt,
                    fundedAddress: EthereumAddress,
                    nullifier: BigUInt,
                    nullifierSecret: BigUInt,
                    leafIndex: BigUInt,
                    merklePath: [BigUInt]) throws -> String
    {
        guard let pkPath = pkPath else { throw ProverError.missingProvingKey }
        guard let jsonProof = withArrayOfCStrings(merklePath.map { $0.description }, { (mpath: [UnsafePointer<CChar>?]) -> (String?) in
            var in_path = mpath
            let leafAddress = String(String(leafIndex, radix: 2).paddingLeft(toLength: mixerTreeDepth, withPad: "0").reversed())
            guard let prf = mixer_prove(pkPath,
                                        root.description,
                                        fundedAddress.ethereumValue().ethereumQuantity!.quantity.description,
                                        nullifier.description,
                                        nullifierSecret.description,
                                        leafAddress,
                                        &in_path) else { return nil }
            return String(cString: prf)
        }) else {
            throw ProverError.couldNotGenerateProof
        }

        let validProof = try verifyProof(jsonProof: jsonProof)
        assert(validProof, "local proof verification failed")
        return jsonProof
    }
    
    func buildFlatProof(root: BigUInt,
                        fundedAddress: EthereumAddress,
                        nullifier: BigUInt,
                        nullifierSecret: BigUInt,
                        leafIndex: BigUInt,
                        merklePath: [BigUInt]) throws -> [BigUInt]
    {
        let jsonProof = try buildProof(root: root, fundedAddress: fundedAddress, nullifier: nullifier, nullifierSecret: nullifierSecret, leafIndex: leafIndex, merklePath: merklePath)
        guard
            let pdata = jsonProof.data(using: .utf8),
            let pdict = try JSONSerialization.jsonObject(with: pdata) as? [String: Any],
            let a = pdict["A"] as? [String], let b = pdict["B"] as? [[String]], let c = pdict["C"] as? [String] else {
                throw ProverError.couldNotDeserializeProof
        }
        return (a + b[0] + b[1] + c).compactMap { BigUInt(hexString: String($0.dropFirst(2))) }
    }
    
    func buildFlatProofPromise(root: BigUInt,
                               fundedAddress: EthereumAddress,
                               nullifier: BigUInt,
                               nullifierSecret: BigUInt,
                               leafIndex: BigUInt,
                               merklePath: [BigUInt]) -> Promise<[BigUInt]>
    {
        return Promise { seal in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let flatProof = try self.buildFlatProof(root: root,
                                                            fundedAddress: fundedAddress,
                                                            nullifier: nullifier,
                                                            nullifierSecret: nullifierSecret,
                                                            leafIndex: leafIndex,
                                                            merklePath: merklePath)
                    DispatchQueue.main.async {
                        seal.resolve(flatProof, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        seal.resolve(nil, error)
                    }
                }
            }
        }
    }
    
    func verifyProof(jsonProof: String) throws -> Bool {
        guard let vk = vk else { throw ProverError.missingVerificationKey }
        return mixer_verify(vk, jsonProof)
    }
    
}
