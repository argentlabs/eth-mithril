//
//  TransactionWatcher.swift
//  BitskiSDK
//
//  Created by Josh Pyles on 5/14/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import PromiseKit
import Web3

/// A class that will receive updates about a transaction.
public protocol TransactionWatcherDelegate: class {
    /// Called when the transaction's status changes
    ///
    /// - Parameters:
    ///   - transactionWatcher: the instance of TransactionWatcher that triggered this event
    ///   - status: the new status of the transaction
    func transactionWatcher(_ transactionWatcher: TransactionWatcher, didUpdateStatus status: TransactionWatcher.Status)
    
    /// Called when the transaction receipt is receieved
    ///
    /// - Parameters:
    ///   - transactionWatcher: the instance of TransactionWatcher that triggered this event
    ///   - receipt: the receipt object of the transaction
    func transactionWatcher(_ transactionWatcher: TransactionWatcher, didReceiveReceipt receipt: EthereumTransactionReceiptObject)
    
    /// Called when an instance of an event being watched is received
    ///
    /// - Parameters:
    ///   - transactionWatcher: the instance of TransactionWatcher that triggered this event
    ///   - event: the event that was received
    func transactionWatcher(_ transactionWatcher: TransactionWatcher, didReceiveEvent event: SolidityEmittedEvent)
}

/// A class that allows you to watch a transaction for events and block confirmations.
///
/// ```
/// firstly {
///   web3.sendTransaction(transaction: transaction)
/// }.done { transactionHash in
///   let watcher = TransactionWatcher(hash: transactionHash, web3: web3)
///   watcher.expectedConfirmations = 3
///   watcher.delegate = self
///   self.transactionWatcher = watcher
/// }
/// ```
public class TransactionWatcher {
    
    // MARK: - Notifications
    
    /// Called when the transaction's status changes
    public static let StatusDidChangeNotification = Notification.Name("TransactionStatusDidChange")
    
    /// Called when the TransactionWatcher receives an event
    public static let DidReceiveEvent = Notification.Name("TransactionDidReceiveEvent")
    
    /// The user info key for the received event
    public static let MatchedEventKey = "MatchedEvent"
    
    // MARK: - Errors
    
    enum Error: Swift.Error {
        case receiptNotFound
    }
    
    // MARK: - Status
    
    /// Represents various states of a transaction
    public enum Status: Equatable {
        /// A transaction that has not yet been mined
        case pending
        /// A transaction that has been mined, along with how many blocks have been mined afterwards
        case approved(times: Int)
        /// A transaction deemed successful (enough blocks have been mined that it is not likely to be reverted)
        case successful
        /// A transaction that could not be mined or was reverted
        case failed
        
        public static func ==(lhs: TransactionWatcher.Status, rhs: TransactionWatcher.Status) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending):
                return true
            case (.successful, .successful):
                return true
            case (.failed, .failed):
                return true
            case (.approved(let a), .approved(let b)):
                return a == b
            default:
                return false
            }
        }
    }
    
    // MARK: - Instance Variables
    
    /// The transaction hash, received from submitting the transaction
    public let transactionHash: EthereumData
    
    /// The receipt object of the transaction
    private(set) public var transactionReceipt: EthereumTransactionReceiptObject?
    
    /// Status of this transaction
    private(set) public var status: Status = .pending {
        didSet {
            if status != oldValue {
                NotificationCenter.default.post(name: TransactionWatcher.StatusDidChangeNotification, object: self)
                delegate?.transactionWatcher(self, didUpdateStatus: status)
            }
        }
    }
    
    /// Block number the transaction was initially confirmed in
    private(set) public var blockNumber: EthereumQuantity?
    
    /// Latest block number we've received
    private(set) public var currentBlock: EthereumQuantity?
    
    /// Number of confirmations to require before marking as successful.
    /// Generally 3 is enough for low value transactions while 6 should be enough for higher values.
    /// The TransactionWatcher will automatically stop once the limit is reached.
    public var expectedConfirmations: Int = 6
    
    /// How often to check for new blocks
    public var pollInterval: TimeInterval = 2.0
    
    /// Class to receive updates
    public weak var delegate: TransactionWatcherDelegate?
    
    /// Events that we are expecting may be returned
    private(set) public var watchedEvents = Set<SolidityEvent>()
    
    private let web3: Web3
    private var timer: Timer?
    
    // MARK: - Initialization
    
    /// Initializes a new instance of TransactionWatcher
    ///
    /// - Parameters:
    ///   - transactionHash: the hash of the transaction to watch (returned from sendTransaction())
    ///   - web3: the Web3 instance to use
    public init(transactionHash: EthereumData, web3: Web3) {
        self.transactionHash = transactionHash
        self.web3 = web3
        getTransactionReceipt()
    }
    
    // MARK: - Instance Methods
    
    /// Stops watching the transaction
    public func stop() {
        resetTimer()
    }
    
    /// Watches for a provided event from the receipt's logs
    ///
    /// - Parameter event: ABIEvent to watch for
    public func startWatching(for event: SolidityEvent) {
        watchedEvents.insert(event)
        if let receipt = transactionReceipt {
            checkForMatchingEvents(logs: receipt.logs)
        }
    }
    
    /// Stops watching for a provided event
    ///
    /// - Parameter event: ABIEvent to stop watching
    public func stopWatching(event: SolidityEvent) {
        watchedEvents.remove(event)
    }
    
    // MARK: - Private Methods
    
    private func getTransactionReceipt() {
        guard self.transactionReceipt == nil else { return }
        firstly {
            return web3.eth.getTransactionReceipt(transactionHash: transactionHash)
        }.done { receipt in
            if let receipt = receipt {
                self.setTransactionReceipt(receipt)
            } else {
                throw Error.receiptNotFound
            }
        }.catch { error in
            // print("Error getting receipt", error)
            after(seconds: self.pollInterval).done {
                self.getTransactionReceipt()
            }
        }
    }
    
    private func setTransactionReceipt(_ receipt: EthereumTransactionReceiptObject) {
        self.transactionReceipt = receipt
        self.blockNumber = receipt.blockNumber
        let timer = Timer(timeInterval: pollInterval, repeats: true, block: { [weak self] _ in
            self?.checkForBlocks()
        })
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        delegate?.transactionWatcher(self, didReceiveReceipt: receipt)
        checkForMatchingEvents(logs: receipt.logs)
    }
    
    private func checkForMatchingEvents(logs: [EthereumLogObject]) {
        for event in watchedEvents {
            if event.anonymous {
                //todo: learn more about how anonymous events are expected to work
                if let log = logs.first {
                    parseEvent(event, from: log)
                }
            } else {
                for log in logs {
                    let hashedSignature = ABI.encodeEventSignature(event)
                    if hashedSignature == log.topics.first?.hex() {
                        parseEvent(event, from: log)
                    }
                }
            }
        }
    }
    
    private func parseEvent(_ event: SolidityEvent, from log: EthereumLogObject) {
        if let values = try? ABI.decodeLog(event: event, from: log) {
            let eventInstance = SolidityEmittedEvent(name: event.name, values: values)
            let userInfo = [TransactionWatcher.MatchedEventKey: eventInstance]
            NotificationCenter.default.post(name: TransactionWatcher.DidReceiveEvent, object: self, userInfo: userInfo)
            delegate?.transactionWatcher(self, didReceiveEvent: eventInstance)
        } else {
            print("Could not parse event \(event) from log \(log)")
        }
    }
    
    private func checkForBlocks() {
        firstly {
            web3.eth.blockNumber()
            }.done { blockNumber in
                self.currentBlock = blockNumber
                firstly {
                    self.web3.eth.getTransactionReceipt(transactionHash: self.transactionHash)
                    }.done { receipt in
                        self.validateLatestReceipt(receipt, blockNumber: blockNumber)
                    }.catch { error in
                        print("Error loading receipt")
                        self.resetTimer()
                }
            }.catch { error in
                self.resetTimer()
                print("Error loading block number", error)
        }
    }
    
    private func validateLatestReceipt(_ receipt: EthereumTransactionReceiptObject?, blockNumber: EthereumQuantity) {
        if let receipt = receipt, receipt.status == 1 {
            guard let receiptBlockNumber = self.blockNumber else {
                return assertionFailure()
            }
            let confirmationCount = blockNumber.quantity - receiptBlockNumber.quantity
            //todo: validate gasUsed
            self.setConfirmationCount(Int(confirmationCount) + 1)
        } else {
            print("Transaction reverted")
            self.status = .failed
            self.resetTimer()
        }
    }
    
    private func setConfirmationCount(_ confirmations: Int) {
        if confirmations < expectedConfirmations {
            status = .approved(times: confirmations)
        } else {
            status = .successful
            resetTimer()
        }
    }
    
    private func resetTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}
