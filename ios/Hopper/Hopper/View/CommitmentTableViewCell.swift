//
//  CommitmentTableViewCell.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 18/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let segueToMixerAddress = Notification.Name("SegueToMixerAddress")
}

class CommitmentTableViewCell: UITableViewCell {
    
    // MARK: - Public API
    var commitment: Commitment? { didSet { updateUI() } }
    var onFundButtonTapped: ((String) -> ())?
    
    @IBOutlet weak var originAddressLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var destinationAddressLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var statusLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var actionButton: UIButton! { didSet { updateUI() } }
    
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        guard let commitment = commitment else { return }
        if commitment.commitTxRelayFailed
            || (commitment.commitTxBlockNumber != nil && !commitment.commitTxSuccesful) {
            print("Requesting commit")
            CommitmentUpdater.shared.requestCommit(for: commitment)
        } else if commitment.fundingTxBlockNumber == nil {
            print("Show Mixer Address")
            NotificationCenter.default.post(name: .segueToMixerAddress, object: nil)
        } else {
            print("Requesting withdrawal")
            CommitmentUpdater.shared.requestWithdrawal(for: commitment)
        }
    }
    
    private func updateUI() {
        originAddressLabel?.text = commitment?.from
        destinationAddressLabel?.text = commitment?.to
        actionButton?.isHidden = true
        statusLabel?.text = "Preparing commitment..."
        
        if commitment?.commitRequested == true, commitment?.commitTxHash == nil {
            statusLabel?.text = "Sending commitment to relayer..."
        } else if commitment?.commitTxRelayFailed == true, commitment?.commitTxHash == nil {
            statusLabel?.text = "Commitment Relaying Error"
            actionButton?.isHidden = false
            actionButton?.setTitle("Retry", for: .normal)
        } else if let commitTxHash = commitment?.commitTxHash, commitment?.commitTxBlockNumber == nil {
            statusLabel?.text = "Confirming commit... (tx=\(commitTxHash.dropLast(58)))"
        } else if commitment?.commitTxBlockNumber != nil, commitment?.commitTxSuccesful != true {
            statusLabel?.text = "Commit tx reverted. Did relayer send enough gas?"
            actionButton?.isHidden = false
            actionButton?.setTitle("Retry", for: .normal)
        } else if commitment?.fundingTxBlockNumber == nil {
            statusLabel?.text = "Waiting for deposit..."
            actionButton?.isHidden = false
            actionButton?.setTitle("Fund", for: .normal)
        } else if commitment?.withdrawTxRelayFailed == true, commitment?.withdrawTxHash == nil {
            statusLabel?.text = "Withdrawal Relaying Error"
            actionButton?.isHidden = false
            actionButton?.setTitle("Retry", for: .normal)
        } else if commitment?.withdrawTxConfirmedAt == nil, commitment?.withdrawRequested != true {
            statusLabel?.text = "Ready for withdrawal (\(commitment?.numSubsequentDeposits ?? 0) subsequent deposits)"
            actionButton?.isHidden = false
            actionButton?.setTitle("Withdraw", for: .normal)
        } else if commitment?.withdrawRequested == true, commitment?.proofComputed != true {
            statusLabel?.text = "Computing proof..."
        } else if commitment?.withdrawRequested == true, commitment?.withdrawTxHash == nil {
            statusLabel?.text = "Sending proof to relayer..."
        } else if let withdrawTxHash = commitment?.withdrawTxHash, commitment?.withdrawTxConfirmedAt == nil {
            statusLabel?.text = "Confirming withdraw... (tx=\(withdrawTxHash.dropLast(58)))"
        } else if commitment?.withdrawTxConfirmedAt != nil, commitment?.withdrawTxSuccesful != true {
            statusLabel?.text = "Withdraw tx reverted :("
            actionButton?.isHidden = false
            actionButton?.setTitle("Retry", for: .normal)
        } else if let withdrawDate = commitment?.withdrawTxConfirmedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MMM HH:mm:ss"
            statusLabel?.text = "Withdrawn on \(formatter.string(from: withdrawDate))"
        }
    }
}
