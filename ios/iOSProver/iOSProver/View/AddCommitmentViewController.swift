//
//  AddCommitmentViewController.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 18/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import UIKit

class AddCommitmentViewController: UITableViewController {
    
    // MARK: - Constants
    
    private struct Storyboard {
        static let commitSegue = "Commit Segue"
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var originAddressField: UITextField!
    @IBOutlet weak var destinationAddressField: UITextField!
    
    // MARK: - Add Commitment
    
    private func isValidAddress(_ addr: String) -> Bool {
        return addr.range(of: "\\A0x[0-9a-fA-F]{40}\\z", options: .regularExpression) != nil
    }
    
    private func addCommitment() {
        if let origin = originAddressField?.text, isValidAddress(origin),
            let destination = destinationAddressField?.text, isValidAddress(destination) {
            _ = Commitment.create(withOrigin: origin, destination: destination, in: CoreDataManager.shared.viewContext)
        }
        do { try CoreDataManager.shared.viewContext.save() }
        catch { NSLog("Error saving context after adding commitment: \(error)") }
    }
    
    
    // MARK: - Navigation
    
    @IBAction func commit(_ sender: UIBarButtonItem) {
        addCommitment()
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.commitSegue {

        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    
}
