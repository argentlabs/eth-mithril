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
    
    @IBOutlet weak var destinationAddressLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var valueLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var networkLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var statusLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var actionButton: UIButton! { didSet { updateUI() } }
    
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        guard let commitment = commitment else { return }
        if commitment.fundingTxBlockNumber == nil {
            let commitData = CommitmentUpdater.shared.getCommitData(for: commitment)
            NotificationCenter.default.post(name: .segueToMixerAddress, object: [
                "mixerId": commitment.mixerId, "commitData": commitData
            ])
        } else {
            print("Requesting withdrawal")
            actionButton.isHidden = true // temporarily hide the withdraw button to avoid double taps
            CommitmentUpdater.shared.requestWithdrawal(for: commitment)
        }
    }
    
    private func updateUI() {
        destinationAddressLabel?.text = commitment?.to
        valueLabel?.text = ConfigParser.shared.value(for: commitment?.mixerId ?? "")
        networkLabel?.text = ConfigParser.shared.network(for: commitment?.mixerId ?? "")
        actionButton?.isHidden = true
        statusLabel?.text = "Preparing commitment..."
        if commitment != nil { print(commitment!)}
        
        if commitment?.fundingTxBlockNumber == nil {
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
