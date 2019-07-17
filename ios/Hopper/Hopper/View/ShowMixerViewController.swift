//
//  ShowMixerViewController.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 17/05/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import UIKit

class ShowMixerViewController: UIViewController {
    
    // MARK: - Public API
    
    var mixerAddress: String? { didSet { updateUI() } }
    var mixedValue: String? { didSet { updateUI() } }
    var commitData: String? { didSet { updateUI() } }
    
    // MARK: - UI
    
    struct Constants {
        static let instructions = """
Please send %VALUE to the Mixer address displayed below. Using the Nifty browser plugin, you should set the gas limit to 1,000,000 and the 'data' field as below.
"""
        static let defaultValue = "1 ETH"
    }
    
    @IBOutlet weak var mixerAddressLabel: UILabel!  { didSet { updateUI() } }
    @IBOutlet weak var instructionLabel: UILabel! { didSet { updateUI() } }
    @IBOutlet weak var transactionData: UILabel! { didSet { updateUI() } }
    
    @IBAction func copyData(_ sender: UIButton) {
        copy(commitData, label: "Transaction Data")
    }
    @IBAction func copyAddress(_ sender: UIButton) {
        copy(mixerAddress, label: "Mixer Address")
    }
    
    private func updateUI() {
        guard let mixerAddress = mixerAddress else { return }
        mixerAddressLabel?.text = mixerAddress
        transactionData?.text = (commitData ?? "0x")//.components(withLength: 25).joined(separator: " ")
        instructionLabel?.text = Constants.instructions
            .replacingOccurrences(of: "%VALUE", with: mixedValue ?? Constants.defaultValue)
    }
    
    private func copy(_ source: String?, label: String) {
        UIPasteboard.general.string = source
        
        // Show Alert
        let alert: UIAlertController = UIAlertController(
            title: "\(label) Copied",
            message: "The \(label) has been copied to your clipboard.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Navigation
    
    @IBAction func close(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true)
    }
}


extension String {
    func components(withLength length: Int) -> [String] {
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
}
