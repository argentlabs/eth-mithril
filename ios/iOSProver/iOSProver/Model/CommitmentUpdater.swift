//
//  CommitmentUpdater.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 19/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import CoreData
import Web3

class CommitmentUpdater: NSObject {
    static let shared: CommitmentUpdater = CommitmentUpdater()
    
    private var fetchedResultsController: NSFetchedResultsController<Commitment>?
    
    private override init() {
        super.init()
    }
    
    func start() {
        // fetch request
        let request: NSFetchRequest<Commitment> = Commitment.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: CoreDataManager.shared.viewContext,
            sectionNameKeyPath: nil,//"state",
            cacheName: nil)
        fetchedResultsController?.delegate = self
        do { try fetchedResultsController?.performFetch() }
        catch { NSLog("CommitmentUpdater Error: fetchedResultsController failed to performFetch: \(error.localizedDescription)") }
        
        fetchedResultsController?.fetchedObjects?.forEach { handle($0) }
    }
    
    func requestWithdrawal(for commitment: Commitment) {
        contextDo { [weak self] in
            commitment.withdrawRequested = true
            commitment.withdrawTxHash = nil
            commitment.withdrawTxConfirmedAt = nil
            commitment.withdrawTxRelayFailed = false
            commitment.proofComputed = false
            self?.handle(commitment)
        }
        
    }
    
    func requestCommit(for commitment: Commitment) {
        contextDo { [weak self] in
            commitment.commitRequested = true
            commitment.commitTxHash = nil
            commitment.commitTxBlockNumber = nil
            commitment.commitTxRelayFailed = false
            self?.handle(commitment)
        }
        
    }
    
    private func handle(_ commitment: Commitment) {
        if commitment.commitTxBlockNumber == nil, commitment.commitRequested {
            commit(commitment)
        } else if commitment.fundingTxBlockNumber == nil {
            watchFundingEvent(for: commitment)
        } else if commitment.withdrawTxConfirmedAt == nil, !commitment.withdrawRequested {
            watchAllFundingEvents(afterFundingOf: commitment)
        } else if commitment.withdrawTxConfirmedAt == nil, commitment.withdrawRequested {
            withdraw(commitment)
        }
    }
    
    private func commit(_ commitment: Commitment) {
        guard
            let from = commitment.from,
            let to = commitment.to,
            let fromAddress = EthereumAddress(hexString: from),
            let toAddress = EthereumAddress(hexString: to),
            let secretStr = commitment.secret,
            let secret = BigUInt(secretStr)
        else { return }
        
        MixerManager.shared.commit(
            fundedAddress: toAddress,
            funderAddress: fromAddress,
            secret: secret,
            txWasSubmitted: { [weak self] (txHash, error) in
                self?.contextDo {
                    if let txHash = txHash {
                        commitment.commitTxHash = txHash.hex()
                    } else {
                        commitment.commitRequested = false
                        commitment.commitTxRelayFailed = true
                    }
                }
        }) { [weak self] receipt in
            self?.contextDo {
                if let blockStr = receipt.blockNumber.ethereumValue().string,
                    let block = UInt64(hexString: String(blockStr.dropFirst(2))) {
                    commitment.commitTxBlockNumber = NSNumber(value: block)
                }
                commitment.commitTxSuccesful = receipt.status == 1
                commitment.commitRequested = false
                if receipt.status == 1 { self?.handle(commitment) }
            }
            
        }
    }
    
    private func watchFundingEvent(for commitment: Commitment) {
        guard
            let to = commitment.to,
            let toAddress = EthereumAddress(hexString: to),
            let secretStr = commitment.secret,
            let secret = BigUInt(secretStr),
            let commitmentBlock = commitment.commitTxBlockNumber?.uint64Value
        else { return }
        
        MixerManager.shared.watchFundingEvent(
            fundedAddress: toAddress,
            secret: secret,
            startBlock: commitmentBlock) { [weak self] (result, error) in
                if let blockNum = result?.blockNumber, let leafIndex = result?.leafIndex {
                    self?.contextDo { [weak self] in
                        commitment.fundingTxBlockNumber = NSNumber(value: blockNum)
                        commitment.leafIndex = leafIndex.description
                        self?.handle(commitment)
                    }
                }
            }
    }
    
    private func watchAllFundingEvents(afterFundingOf commitment: Commitment) {
        
        guard let startBlock = (commitment.lastFundingTxBlockNumber ?? commitment.fundingTxBlockNumber)?.uint64Value.advanced(by: 1)
        else { return }
        
        MixerManager.shared.watchAllFundingEvents(startBlock: startBlock) { [weak self] (result, error) in
                if let blockNum = result?.blockNumber, let numDeposits = result?.numDeposits {
                    self?.contextDo { [weak self] in
                        commitment.numSubsequentDeposits += Int64(numDeposits)
                        commitment.lastFundingTxBlockNumber = NSNumber(value: blockNum)
                        self?.handle(commitment)
                    }
                }
        }
    }
    
    private func withdraw(_ commitment: Commitment) {
        guard
            let from = commitment.from,
            let to = commitment.to,
            let fromAddress = EthereumAddress(hexString: from),
            let toAddress = EthereumAddress(hexString: to),
            let secretStr = commitment.secret,
            let secret = BigUInt(secretStr),
            let leafIndexStr = commitment.leafIndex,
            let leafIndex = BigUInt(leafIndexStr)
        else { return }
        
        MixerManager.shared.withdraw(
            fundedAddress: toAddress,
            funderAddress: fromAddress,
            secret: secret,
            leafIndex: leafIndex,
            proofWasComputed: { [weak self] in
                 self?.contextDo { commitment.proofComputed = true }
            },
            txWasSubmitted: { [weak self] (txHash, error) in
                self?.contextDo {
                    if let txHash = txHash {
                       commitment.withdrawTxHash = txHash.hex()
                    } else {
                        commitment.withdrawRequested = false
                        commitment.withdrawTxRelayFailed = true
                    }
                }
            },
            txWasMined: { [weak self] receipt in
                self?.contextDo {
                    commitment.withdrawTxConfirmedAt = Date()
                    commitment.withdrawTxSuccesful = receipt.status == 1
                    commitment.withdrawRequested = false
                }
            }
        )
    }
    
    private func contextDo(andSave save: Bool = true, block: @escaping () -> ()) {
        let context = CoreDataManager.shared.viewContext
        context.perform {
            block()
            if save {
                do { try context.save() }
                catch { NSLog("Error saving context in CommitmentUpdater: \(error.localizedDescription)") }
            }
        }
    }
    
    
}

extension CommitmentUpdater: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let commitment = anObject as? Commitment {
                self.handle(commitment)
            }
        default: break
        }
    }
}
