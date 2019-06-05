//
//  ViewController.swift
//  web3swiftExample
//
//  Created by Alexander Vlasov on 22.12.2017.
//  Copyright © 2017 Alexander Vlasov. All rights reserved.
//

import UIKit
import BigInt
import web3swift
import Foundation

extension Web3 {
    @available (*, unavailable, renamed: "contract(_:at:)")
    func contract(_ abiString: String, at: Address? = nil, abiVersion: Int) throws -> Web3Contract {
        return try Web3Contract(web3: self, abiString: abiString, at: at, options: options)
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = OperationQueue()
        queue.addOperation {
            do {
                try self.test()
            } catch {
                print("error:",error)
            }
        }
        queue.addOperation {
            // Generating QR code
            
            var eip67Data = EIP67Code(address: Address("0x6394b37Cf80A7358b38068f0CA4760ad49983a1B"))
            eip67Data.gasLimit = BigUInt(21000)
            eip67Data.amount = BigUInt("1000000000000000000")
            let encoding = eip67Data.toImage(scale: 10)
            let image = UIImage(ciImage: encoding)
            
            DispatchQueue.main.async {
                self.imageView.layer.shouldRasterize = true
                self.imageView.layer.magnificationFilter = .nearest
                self.imageView.layer.minificationFilter = .nearest
                self.imageView.contentMode = .scaleAspectFit
                self.imageView.image = image
            }
        }
    }
    
    func test() throws {
        // create normal keystore
        
        let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore") else { return }
        var ks: EthereumKeystoreV3?
        if (keystoreManager.addresses.count == 0) {
            ks = try! EthereumKeystoreV3(password: "BANKEXFOUNDATION")
            let keydata = try! JSONEncoder().encode(ks!.keystoreParams)
            FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keydata, attributes: nil)
        } else {
            ks = keystoreManager.walletForAddress((keystoreManager.addresses[0])) as? EthereumKeystoreV3
        }
        guard let sender = ks?.addresses.first else { return }
        print(sender)
        
        //create BIP32 keystore
        guard let bip32keystoreManager = KeystoreManager.managerForPath(userDir + "/bip32_keystore", scanForHDwallets: true) else { return }
        var bip32ks: BIP32Keystore!
        if (bip32keystoreManager.addresses.count == 0) {
            let mnemonics = try Mnemonics("normal dune pole key case cradle unfold require tornado mercy hospital buyer")
            bip32ks = try BIP32Keystore(mnemonics: mnemonics, password: "BANKEXFOUNDATION")
            let keydata = try! JSONEncoder().encode(bip32ks!.keystoreParams)
            FileManager.default.createFile(atPath: userDir + "/bip32_keystore"+"/key.json", contents: keydata, attributes: nil)
        } else {
            bip32ks = bip32keystoreManager.walletForAddress((bip32keystoreManager.addresses[0])) as? BIP32Keystore
        }
        guard let bip32sender = bip32ks?.addresses.first else { return }
        print(bip32sender)
        
        
        // BKX TOKEN
        let web3Main = Web3(infura: .mainnet)
        let coldWalletAddress = Address("0x6394b37Cf80A7358b38068f0CA4760ad49983a1B")
        let constractAddress = Address("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
        let gasPrice = try web3Main.eth.getGasPrice()
        var options = Web3Options.default
        options.gasPrice = gasPrice
        options.from = Address("0xE6877A4d8806e9A9F12eB2e8561EA6c1db19978d")
        
        web3Main.keystoreManager = keystoreManager
        let contract = ERC20(constractAddress)
        let tokenName = try contract.name()
        print("BKX token name = \(tokenName)")
        let balance = try contract.balance(of: coldWalletAddress)
        print("BKX token balance = \(balance)")
        
        //Send on Rinkeby using normal keystore
        print("Rinkeby")
        Web3.default = Web3(infura: .rinkeby)
        let web3Rinkeby = Web3.default
        web3Rinkeby.keystoreManager = keystoreManager
        let coldWalletABI = "[{\"payable\":true,\"type\":\"fallback\"}]"
        options = Web3Options.default
        options.gasLimit = BigUInt(21000)
        options.from = ks?.addresses.first!
        options.value = BigUInt(1000000000000000)
        options.from = sender
        let estimatedGas = try web3Rinkeby.contract(coldWalletABI, at: coldWalletAddress).method(options: options).estimateGas(options: nil)
        options.gasLimit = estimatedGas
        var intermediateSend = try web3Rinkeby.contract(coldWalletABI, at: coldWalletAddress).method(options: options)
        let sendingResult = try intermediateSend.send(password: "BANKEXFOUNDATION")
        let txid = sendingResult.hash
        print("On Rinkeby TXid = " + txid)
        
        // Send ETH on Rinkeby using BIP32 keystore. Should fail due to insufficient balance
        web3Rinkeby.keystoreManager = bip32keystoreManager
        options.from = bip32ks?.addresses.first!
        intermediateSend = try web3Rinkeby.contract(coldWalletABI, at: coldWalletAddress).method(options: options)
        let transaction = try intermediateSend.send(password: "BANKEXFOUNDATION")
        print(transaction)
        
        //Send ERC20 token on Rinkeby
        web3Rinkeby.addKeystoreManager(keystoreManager)
        let testToken = ERC20("0xa407dd0cbc9f9d20cdbd557686625e586c85b20a")
        testToken.options.from = ks!.addresses.first!
        
        let transaction1 = try testToken.transfer(to: "0x6394b37Cf80A7358b38068f0CA4760ad49983a1B", amount: 1)
        print(transaction1)
        
        //Send ERC20 on Rinkeby using a convenience function
        let transaction2 = try testToken.approve(to: "0x6394b37Cf80A7358b38068f0CA4760ad49983a1B", amount: NaturalUnits("0.0001"))
        print(transaction2)
        
        //Balance on Rinkeby
        let rinkebyBalance = try web3Rinkeby.eth.getBalance(address: coldWalletAddress)
        print("Balance of \(coldWalletAddress.address) = \(rinkebyBalance)")
        
        let deployedTestAddress = Address("0x1e528b190b6acf2d7c044141df775c7a79d68eba")
        options = Web3Options.default
        options.gasLimit = BigUInt(100000)
        options.value = BigUInt(0)
        options.from = ks?.addresses[0]
        let transaction3 = try deployedTestAddress.send("increaseCounter(uint8)", 1, password: "BANKEXFOUNDATION").wait()
        print(transaction3)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

