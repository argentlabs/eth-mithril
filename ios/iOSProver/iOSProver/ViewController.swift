//
//  ViewController.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 31/01/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import UIKit
import Web3
import Foundation // needed for strdup and free

enum ProverError : Error {
    case couldNotGenerateProof
    case couldNotDeserializeProof
    case unexpectedDataReturnedFromContract
    case unexpectedEventEmittedFromContract
}

class ViewController: UIViewController {

    public func withArrayOfCStrings<R>(_ args: [String], _ body: ([UnsafePointer<CChar>?]) -> R) -> R {
        var cStrings = args.map { UnsafePointer(strdup($0)) }
        cStrings.append(nil)
        defer { cStrings.forEach { free(UnsafeMutablePointer(mutating: $0)) } }
        return body(cStrings)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let pkPath = Bundle.main.path(forResource: "mixer.pk", ofType: "raw") else { return }
        
        let web3 = Web3(rpcURL: "http://127.0.0.1:8545")
        let leafAddedEvent = SolidityEvent(name: "LeafAdded", anonymous: false, inputs: [
            SolidityEvent.Parameter(name: "_leaf", type: .uint256, indexed: false),
            SolidityEvent.Parameter(name: "_leafIndex", type: .uint256, indexed: false)
        ])
        guard let mixerAddress = EthereumAddress(hexString: "0xbcc8779dfb182ff88b11c538de068c79b953a57d") else { return }
        guard let committerWallet = try? EthereumPrivateKey(hexPrivateKey: "0x157c4ae11fd6f2c5202ba17d16416db04c3e8cd28ee7c9c6690ab1e2a4bf31d5") else { return }
        guard let funderWallet = try? EthereumPrivateKey(hexPrivateKey: "0x4b871cd582c867e1d90d1de05ad175043178b767bca8b928139a86336cf8d346") else { return }
        let withdrawerWallet = committerWallet // in practice: both are the relayer
        guard let fundedWallet = try? EthereumPrivateKey(hexPrivateKey: "0xecbcf0dc512dcb318e8dccff391c1631661663033e0fa6d51cc266db04f32591") else { return }
        
        guard
            let url = Bundle.main.url(forResource: "Mixer", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url),
            let abi = ((try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any])?["abi"] as? [[String: Any]] else { return }
        let noFallbackAbi = abi.filter { $0["type"] as? String != "fallback"}
        guard
            let abiData = try? JSONSerialization.data(withJSONObject: noFallbackAbi, options: []),
            let mixer = try? web3.eth.Contract(json: abiData, abiKey: nil, address: mixerAddress) else { return }

        let nullifier_secret = BigUInt(123457001)
        var leaf: BigUInt!
        var nullifier: BigUInt!
        var leaf_address: String!
        var merkle_path = [BigUInt]()
        var flat_proof = [BigUInt]()
        
        let bgq = DispatchQueue.global(qos: .userInitiated)
        
        firstly {
            mixer["makeLeafHash"]!(nullifier_secret, fundedWallet.address).call()
        }.then(on: bgq) { outputs -> Promise<[String: Any]> in
            guard let lf = outputs[""] as? BigUInt else { throw ProverError.unexpectedDataReturnedFromContract }
            leaf = lf
            print("leaf:", lf)
            return mixer["makeNullifierHash"]!(nullifier_secret).call()
        }.then(on: bgq) { outputs -> Promise<EthereumQuantity> in
            guard let null = outputs[""] as? BigUInt else { throw ProverError.unexpectedDataReturnedFromContract }
            nullifier = null
            print("nullifier:", null)
            return web3.eth.getTransactionCount(address: committerWallet.address, block: .latest)
        }.then(on: bgq) { nonce -> Promise<EthereumSignedTransaction> in
            let tx = mixer["commit"]!(leaf, funderWallet.address).createTransaction(
                nonce: nonce,
                from: committerWallet.address,
                value: 0,
                gas: 150000,
                gasPrice: EthereumQuantity(quantity: 2.gwei)
            )
            return try tx!.sign(with: committerWallet, chainId: 1).promise
        }.then(on: bgq) { tx -> Promise<EthereumData> in
            return web3.eth.sendRawTransaction(transaction: tx)
        }.then(on: bgq) { txHash -> Promise<EthereumQuantity> in
            print("txHash:", txHash.hex())
            return web3.eth.getTransactionCount(address: funderWallet.address, block: .latest)
        }.then(on: bgq) { nonce -> Promise<EthereumSignedTransaction> in
            return try EthereumTransaction(
                nonce: nonce,
                gasPrice: EthereumQuantity(quantity: 2.gwei),
                gas: 1000000,
                from: funderWallet.address,
                to: mixerAddress,
                value: EthereumQuantity(quantity: 1.eth)
            ).sign(with: funderWallet, chainId: 1).promise
        }.then(on: bgq) { tx -> Promise<EthereumData> in
            web3.eth.sendRawTransaction(transaction: tx)
        }.then(on: bgq) { txHash -> Promise<EthereumTransactionReceiptObject?> in
            print("txHash:", txHash.hex())
            return web3.eth.getTransactionReceipt(transactionHash: txHash)
        }.then(on: bgq) { receipt -> Promise<[String : Any]> in
            guard
                let log = receipt?.logs.first,
                let leaf_index = (try? ABI.decodeLog(event: leafAddedEvent, from: log))?["_leafIndex"] as? BigUInt else {
                throw ProverError.unexpectedEventEmittedFromContract
            }
            leaf_address = String(String(leaf_index, radix: 2).paddingLeft(toLength: 29, withPad: "0").reversed())
            print("leaf_index:", leaf_index, "leaf_addr:", leaf_address!)
            return mixer["getMerklePath"]!(leaf_index).call()
        }.then(on: bgq) { outputs -> Promise<[String : Any]> in
            guard let mpath = outputs["out_path"] as? [BigUInt] else { throw ProverError.unexpectedDataReturnedFromContract }
            merkle_path = mpath
            return mixer["getRoot"]!().call()
        }.then(on: bgq) { outputs -> Promise<EthereumQuantity> in
            guard let root = outputs[""] as? BigUInt else { throw ProverError.unexpectedDataReturnedFromContract }
            print("root:", root)
            
            guard let json_proof = self.withArrayOfCStrings(merkle_path.map { $0.description }, { (mpath: [UnsafePointer<CChar>?]) -> (String?) in
                var in_path = mpath
//                print("mixer_prover params:")
//                print(root.description)
//                print(fundedWallet.address.ethereumValue().ethereumQuantity!.quantity.description)
//                print(nullifier.description)
//                print(nullifier_secret.description)
//                print(leaf_address!)
//                print(merkle_path)
                guard let prf = mixer_prove(pkPath,
                                            root.description,
                                            fundedWallet.address.ethereumValue().ethereumQuantity!.quantity.description,
                                            nullifier.description,
                                            nullifier_secret.description,
                                            leaf_address!,
                                            &in_path) else { return nil }
                return String(cString: prf)
            }) else {
                throw ProverError.couldNotGenerateProof
            }
            
            
            let vk = """
{"alpha": ["0x22df57da9391e5ee1d7a2f2fa7e6f072b2df1cbdf01df8609e330ebb2a49d76e", "0x1ecd108324d48d8ea133714275625c67b86f29e9f817a8c69673247d5a89092a"], "beta": [["0xec5880cbcff288aae7e6cdc5671e4e95b8b24e0df22a5c50fbb199e7a2f923", "0x2a4bf91524ef3b0ed8ad7161426f0d57f93bba250d881b5f5fa97f520cc0ea45"], ["0x10ba9c20f38e72cea844f68c6ed2dd59ddd0e8e0df26932b7640b61bac51979f", "0x7b8a622e6f49eba3d811a0235c966980b3f47d346622ae5dc940ab9d37f97d1"]], "gamma": [["0x2cb0ec6b4c5b32110b74de6e8aa272ac0df66844e5f64706a5e272fae2b5b3a8", "0x1f77fa27405a2dfe41017232784755780b18ed6b94f4150579429fa375ba31cc"], ["0x239dfb41879f16f56d4ec1d5e04934ddf2936e2046e9d4cdef74206b09ce4627", "0x1784bda27ed5eddeb842e6964990f930d7ef6a37606545dc33d05fe2d40c32a3"]], "delta": [["0x2d597f4cd6b6a2883c55619ab27b24808635175675899e15213dae457ba25ad7", "0x28b83ad0b1afee5bb2b6e7c0d8b84104648918b3d9b7a268275130a8a54d4ad6"], ["0x2adfcb75e924e86e9952956b89a5d84f22222f597704a65f1586601791996bba", "0x1043b2fc2c6a9afc64c918a4e81ee5fc5ff1ad3d8790a9ed644673e738ceef2f"]], "gammaABC": [["0x26b970e02b5e2dc0d71f467bed00af884a9bcc1b7942eb2164adfe9333058a32", "0x9aa2bb08920e2aa218166aa1ce3ff568ebc1cef8293c1d40fadd64898e3881c"], ["0xa055b15720ab3e0baa3a393832c2d2b961fe45eb239ab7f05c7279a5daa9790", "0x14dbea96f8f0974e28f84197c357af898fcaf38b2c6f3fc7b7c263b9f89bc06d"], ["0x29f536fe697bdd4240ee72227b9c25ebde75519f6b1045f225d7c5e74fb13108", "0x2cea967b4be4c94f41532245eaecf475db577b0de42abdd4a02ec317ef3b5dc4"], ["0x174c8e7dec312760cd12ee7704d048d3632c9d2481c139bced8f6058ee162171", "0x1bb6905ad4452d745a7309ef224c359fd61d3a4cd1f60bb886c9f4d67e19a2d4"]]}
"""
            let verif = mixer_verify(vk, json_proof)
            print("verif:", verif)
            
            print("proof:", json_proof)
            
            guard
                let pdata = json_proof.data(using: .utf8),
                let pdict = try JSONSerialization.jsonObject(with: pdata) as? [String: Any],
                let a = pdict["A"] as? [String], let b = pdict["B"] as? [[String]], let c = pdict["C"] as? [String] else {
                throw ProverError.couldNotDeserializeProof
            }
            flat_proof = (a + b[0] + b[1] + c).compactMap { BigUInt(hexString: String($0.dropFirst(2))) }
            print("flat_proof:", flat_proof)

            return web3.eth.getTransactionCount(address: committerWallet.address, block: .latest)
        }.then(on: bgq) { nonce -> Promise<EthereumSignedTransaction> in
            let tx = mixer["withdraw"]!(fundedWallet.address, nullifier, flat_proof).createTransaction(
                nonce: nonce,
                from: withdrawerWallet.address,
                value: 0,
                gas: 3000000,
                gasPrice: EthereumQuantity(quantity: 2.gwei)
            )
            return try tx!.sign(with: withdrawerWallet, chainId: 1).promise
        }.then(on: bgq) { tx -> Promise<EthereumData> in
            return web3.eth.sendRawTransaction(transaction: tx)
        }.then(on: bgq) { txHash -> Promise<EthereumQuantity>  in
            print("txHash:", txHash.hex())
            return web3.eth.getBalance(address: fundedWallet.address, block: .latest)
        }.done { balance in
            print("balance of destination wallet:", balance.quantity)
        }.catch { error in
            print(error)
        }
        
    }
    
    
}

