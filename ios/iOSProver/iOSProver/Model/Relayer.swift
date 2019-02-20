//
//  Relayer.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 12/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import Web3



typealias TransactionSubmittedCallback = (_ txHash: EthereumData?, _ error: Error?) -> ()
typealias TransactionMinedCallback = (_ txReceipt: EthereumTransactionReceiptObject) -> ()

class Relayer {
    
    enum RelayerError : Error {
        case relayerIsUnreachable
        case invalidRelayerParam(String)
        case transactionRevert
    }

    init(web3: Web3, endPoint: String) {
        self.web3 = web3
        self.restClient = RestClient(endPoint: endPoint)
    }
    
    let web3: Web3
    private let restClient: RestClient
    private var txWatchers = [String: (watcher: TransactionWatcher, callback: TransactionMinedCallback)]() // [txHash: (watcher, callback)]
    
    private var requestId = 0
    private func getRequestId() -> Int {
        let thisId = requestId
        requestId += 1
        return thisId
    }
    

    func send(to: String,
              data: String,
              gas: String,
              txWasSubmitted: TransactionSubmittedCallback? = nil,
              txWasMined: TransactionMinedCallback? = nil) {
        let params = ["to": to, "data": data, "gas": gas]
        let payload: [String: Any] = ["jsonrpc": "2.0", "method": "eth_sendTransaction", "id": getRequestId(), "params": [params]]
        let request = restClient.postRequest(forPath: "/", params: payload, headers: nil, contentType: .json)
        
        restClient.query(request) { [weak self] (statusCode, json, error) in
            guard error == nil else {
                NSLog("Relayer Unreachable")
                txWasSubmitted?(nil, RelayerError.relayerIsUnreachable)
                return
            }

            let jsonDict = json as? [String: Any]
            if 200...299 ~= statusCode, let result = jsonDict?["result"] as? String, let txHash = try? EthereumData(ethereumValue: result) {
                if let txWasMined = txWasMined, let this = self {
                    let transactionWatcher = TransactionWatcher(transactionHash: txHash, web3: this.web3)
                    transactionWatcher.delegate = this
                    this.txWatchers[txHash.hex()] = (watcher: transactionWatcher, callback: txWasMined)
                }
                txWasSubmitted?(txHash, nil)
            } else {
                let error = jsonDict?["error"] as? [String: Any]
                NSLog("Relayer Call Failed -- Status: \(statusCode) -- Code: \(error?["code"] ?? "") Message: \(error?["message"] ?? "")")
                let fullErrorMessage = "[\(statusCode)][\(error?["code"] ?? "")]\(error?["message"] ?? "")"
                txWasSubmitted?(nil, RelayerError.invalidRelayerParam(fullErrorMessage))
            }
            
        }
    }
}

extension Relayer: TransactionWatcherDelegate {
    
    func transactionWatcher(_ transactionWatcher: TransactionWatcher, didUpdateStatus status: TransactionWatcher.Status) {}
    func transactionWatcher(_ transactionWatcher: TransactionWatcher, didReceiveEvent event: SolidityEmittedEvent) {}
    
    func transactionWatcher(_ transactionWatcher: TransactionWatcher, didReceiveReceipt receipt: EthereumTransactionReceiptObject) {
        let txHash = receipt.transactionHash
        if receipt.status == 1 {
            print("Relayer TX Mined: \(txHash.hex())")
        } else {
            print("Relayer TX Reverted: \(txHash.hex())")
        }
        transactionWatcher.stop()
        
        txWatchers[txHash.hex()]?.callback(receipt)
        txWatchers[txHash.hex()] = nil
    }
    
    
}
