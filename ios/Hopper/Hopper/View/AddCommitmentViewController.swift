//
//  AddCommitmentViewController.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 18/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import UIKit
import QRCodeReader

class AddCommitmentViewController: UITableViewController {
    
    // MARK: - Constants
    
    private struct Constants {
        static let mixerKey = "AddCommitmentViewController.Mixer"
    }
    
    private struct Storyboard {
        static let selectNetworkSegue = "Select Network"
        static let selectNetworkCellIdentifier = "Network"
        static let selectNetworkUnwindSegue = "Unwind Select Network"
    }

    // MARK: - Outlets
    
    @IBOutlet weak var originAddressField: UITextField!
    @IBOutlet weak var destinationAddressField: UITextField!
    
    @IBOutlet weak var originQRCodeButton: UIButton!
    @IBOutlet weak var destinationQRCodeButton: UIButton!
    
    @IBOutlet weak var networkLabel: UILabel! { didSet { updateUI() } }
    
    // MARK: - UpdateUI
    
    private func updateUI() {
        networkLabel?.text = ConfigParser.shared.network(for: mixerId)
    }
    
    
    // MARK: - Network
    
    var mixerId: String {
        get {
            return UserDefaults.standard.string(forKey: Constants.mixerKey) ?? ConfigParser.shared.sortedMixerIds.first ?? ""
        }
        set {
            if newValue != mixerId { UserDefaults.standard.set(newValue, forKey: Constants.mixerKey) }
        }
    }
    
    // MARK: - Add Commitment
    
    private func isValidAddress(_ addr: String) -> Bool {
        return addr.range(of: "\\A0x[0-9a-fA-F]{40}\\z", options: .regularExpression) != nil
    }
    
    private func addCommitment() {
        if let origin = originAddressField?.text, isValidAddress(origin),
            let destination = destinationAddressField?.text, isValidAddress(destination) {
            _ = Commitment.create(withOrigin: origin,
                                  destination: destination,
                                  mixerId: mixerId,
                                  in: CoreDataManager.shared.viewContext)
        }
        do { try CoreDataManager.shared.viewContext.save() }
        catch { NSLog("Error saving context after adding commitment: \(error)") }
    }
    
    // MARK: - QR Code Reader
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    @IBAction func scanQRCode(_ sender: UIButton) {
        if QRCodeReader.isAvailable() {
            
            readerVC.completionBlock = { [weak self] (result: QRCodeReaderResult?) in
                self?.readerVC.stopScanning()
                self?.dismiss(animated: true)
                if let address = result?.value {
                    let components = address.components(separatedBy: ":")
                    if sender == self?.originQRCodeButton {
                        self?.originAddressField?.text = components.last
                    } else {
                        self?.destinationAddressField?.text = components.last
                    }
                }
            }
            
            readerVC.modalPresentationStyle = .formSheet
            present(readerVC, animated: true)
        }
    }
    
    // MARK: - Navigation: Commit/Cancel
    
    @IBAction func commit(_ sender: UIBarButtonItem) {
        addCommitment()
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    // MARK: - Navigation: Change Network
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectionVC = segue.destination as? SelectionTableViewController {
            if segue.identifier == Storyboard.selectNetworkSegue {
                prepare(selectionVC)
            }
        } else if !([Storyboard.selectNetworkUnwindSegue].contains(segue.identifier ?? "")) {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    private func prepare(_ selectionVC: SelectionTableViewController) {
        selectionVC.cellIdentifier = Storyboard.selectNetworkCellIdentifier
        selectionVC.options = ConfigParser.shared.sortedMixerIds
        selectionVC.isOptionPopular = nil
        selectionVC.selectedOption = mixerId
        selectionVC.oneSectionPerStartingLetter = false
        selectionVC.unwindSegueIdentifier = Storyboard.selectNetworkUnwindSegue
        selectionVC.searchBarPlaceholder = "Search Networks"
        selectionVC.descriptionForOption = { option in
            guard let mixerId = option as? String else { return nil }
            return ConfigParser.shared.network(for: mixerId)
        }
    }
    
    @IBAction func changeNetwork(segue: UIStoryboardSegue) {
        if segue.identifier == Storyboard.selectNetworkUnwindSegue,
            let selectionVC = segue.source as? SelectionTableViewController {
            
            if let selectedMixerId = selectionVC.selectedOption as? String {
                mixerId = selectedMixerId
                updateUI()
            }
        }
    }
    
    
}
