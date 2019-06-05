//
//  Guides.swift
//  web3swift
//
//  Created by Dmitry on 16/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

/// # web3swift guides
public class Guide {
    /**
    Here's a few use cases of our library
    
    ### Initializing Ethereum address
    
    ```swift
    let coldWalletAddress: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
    let constractAddress: Address = "0x45245bc59219eeaaf6cd3f382e078a461ff9de7b"
    ```
    Ethereum addresses are checksum checked if they are not lowercased and always length checked
    
    ### Setting options
    
    ```swift
    var options = Web3Options.default
    // public var to: Address? = nil - to what address transaction is aimed
    // public var from: Address? = nil - form what address it should be sent (either signed locally or on the node)
    // public var gasLimit: BigUInt? = BigUInt(90000) - default gas limit
    // public var gasPrice: BigUInt? = BigUInt(5000000000) - default gas price, quite small
    // public var value: BigUInt? = BigUInt(0) - amount of WEI sent along the transaction
    options.gasPrice = gasPrice
    options.gasLimit = gasLimit
    options.from = "0xE6877A4d8806e9A9F12eB2e8561EA6c1db19978d"
    ```
    
    ### Getting ETH balance
    
    ```swift
    let address: Address = "0xE6877A4d8806e9A9F12eB2e8561EA6c1db19978d"
    let web3Main = Web3(infura: .mainnet)
    let balance: BigUInt = try web3Main.eth.getBalance(address)
    ```
    
    ### Getting gas price
    
    ```swift
    let web3Main = Web3(infura: .mainnet)
    let gasPrice: BigUInt = try web3Main.eth.getGasPrice()
    ```
    
    ### Getting ERC20 token balance
    
    ```swift
    let contractAddress: Address = "0x45245bc59219eeaaf6cd3f382e078a461ff9de7b" // BKX token on Ethereum mainnet
    let balance = try ERC20(contractAddress).balance(of: "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8")
    print("BKX token balance = " + String(bal))
    ```
    
    
    
    ### Sending ETH
    
    ```swift
    let mnemonics = Mnemonics()
    let keystore = try BIP32Keystore(mnemonics: mnemonics)
    let keystoreManager = KeystoreManager([keystore])
    let web3Rinkeby = Web3(infura: .rinkeby)
    web3Rinkeby.addKeystoreManager(keystoreManager) // attach a keystore if you want to sign locally. Otherwise unsigned request will be sent to remote node
    var options = Web3Options.default
    options.from = keystore.addresses.first! // specify from what address you want to send it
    let intermediateSend = try web3Rinkeby.contract(Web3Utils.coldWalletABI, at: coldWalletAddress).method(options: options) // an address with a private key attached in not different from any other address, just has very simple ABI
    let sendResultBip32 = try intermediateSend.send(password: "BANKEXFOUNDATION")
    ```
    
    
    
    ### Sending ERC20
    
    ```swift
    let web3 = Web3(infura: .rinkeby)
    let erc20 = ERC20("0xa407dd0cbc9f9d20cdbd557686625e586c85b20a", from: yourAddress)
    let result = try erc20.transfer(to: "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8", amount: NaturalUnits("0.0001"))
    ```
     */
    public struct Usage {}
    
    /**
	## How to use web3swift with ganache node
	
	Im running ganache on port 8545 with default hd path settings.
	
	Connect to your ganache node
     
	```
	Web3.default = try! .local(port: 8545)
	let web3 = Web3.default
	```
	
	Importing account using mnemonics
	
	```
	let mnemonicsString = "nation tornado double since increase orchard tonight left drip talk sand mad"
	let mnemonics = try! Mnemonics(mnemonicsString)
	
	let keystore = try! BIP32Keystore(mnemonics: mnemonics)
	
	// Now set keystore as your Web3.default keystore
	Web3.default.keystoreManager.append(keystore)
	
	// Ganache using hdpath for its accounts. So to load next 9 subaccounts just use:
	for _ in 0..<9 {
		try keystore.createNewChildAccount()
	}
	
	// Now you can print them all:
	print(keystore.addresses.map { $0.description }.joined(separator: "\n"))
	```
	```
	/* prints:
	0xDf2bC70175311A6807F085e54881Fc4931359dBF
	0xA6090DE9BcDcfdF153cDa9c56d3c1b324d9E6c1f
	0xC711490Bca5Bb74218EBf48BbA9Fe46718658eCF
	0x1349D9fFf512F322a1575cE2b2d6C3b4F9D2D4Ee
	0xDbA8EAa24a192dFfBDcdCe8599c3ED9451566572
	0x57034d57b69b2f172814252Df7A54B072cF46104
	0x588F661eF26ff481C580755E1A58029807DE6E73
	0x085fe021f91AA43587f7c18785dd7DC6e938B3a8
	0x2608dAC7b490Fa3A7DC4De38B046Dc3b5CB60910
	0x3868dd20179e53B0449f62Cf4933B359369eA00f
	*/
	```
	
	and get private key and balance
	
	```
	for address in web3.keystoreManager.addresses {
		web3.eth.getBalancePromise(address: address).done { balance in
			let privateKey: Data = try! web3.keystoreManager.UNSAFE_getPrivateKeyData(account: address)
			print("")
			print("Address:", address)
			print("Private key:", privateKey.hex.withHex)
			print("Balance:", balance.string(units: .eth), "ether")
		}.catch { error in
			print("error: \(error)")
		}
	}
	```
	```
	/* prints:
	Address: 0x57034d57b69b2f172814252Df7A54B072cF46104
	Private key: 0x1085338b5ca27ad6e0beee3de9f54fc8afbaf98b1a62d86a2c7b9ea8555aaefd
	Balance: 100 ether
	
	Address: 0xDf2bC70175311A6807F085e54881Fc4931359dBF
	Private key: 0x8e3ed3451ab7058fc15b789d52991b47f2a9e373de9280982ac79244ccceb862
	Balance: 100 ether
	
	Address: 0x085fe021f91AA43587f7c18785dd7DC6e938B3a8
	Private key: 0xa8a454547853ad4acc71dfddc1d9ec279c87c1d8463c9e4c9ae089c9861debf3
	Balance: 100 ether
	
	Address: 0xC711490Bca5Bb74218EBf48BbA9Fe46718658eCF
	Private key: 0x458d2c3daafc6a0ab327e1ee8451a8adeb72f78abeb279d0db05a698889ffd53
	Balance: 100 ether
	
	Address: 0x3868dd20179e53B0449f62Cf4933B359369eA00f
	Private key: 0x7ae211cd18ce0ad2222cf324944861076008f4a4856cd54f0846ed064f88778d
	Balance: 100 ether
	
	Address: 0x2608dAC7b490Fa3A7DC4De38B046Dc3b5CB60910
	Private key: 0x4e4282e6d3e95194260b8bd18e7925f2fc45a7ed7fe20bb9a7b839a915ab1002
	Balance: 100 ether
	
	Address: 0xDbA8EAa24a192dFfBDcdCe8599c3ED9451566572
	Private key: 0xe15befa58edf55c2ac1bc68027d8926be80125da268e2ba86eba7e2815bc709a
	Balance: 100 ether
	
	Address: 0x1349D9fFf512F322a1575cE2b2d6C3b4F9D2D4Ee
	Private key: 0xf277c64480cf53e8eedf8fc30df8aafc13d6a8e3750882efc248ba2ccb8baaa2
	Balance: 100 ether
	
	Address: 0x588F661eF26ff481C580755E1A58029807DE6E73
	Private key: 0x7799fe5004d928282ad997670aa9fc7ac7aaf27d88e6c969761c4b1863df14a2
	Balance: 100 ether
	
	Address: 0xA6090DE9BcDcfdF153cDa9c56d3c1b324d9E6c1f
	Private key: 0x17215215562d34c3a256c255e396135072af433c0a0060d1130fea12d6ea7254
	Balance: 100 ether
	*/
	```
	
	And now you can send some ether from one account to another
	
	```
	var options = Web3Options.default
	options.from = keystore.addresses[0]
	
	let transaction = try web3.eth.sendETH(to: keystore.addresses[1], amount: BigUInt("10", units: .eth)!).send(options: options)
	print(transaction.hash)
	// prints: 0x6f150015d033de944f17c1e1f63aa798bcbac7b9144f53520f4795596df84852
	```
	
	You can get the transaction any time using transaction hash:
	```
	let details = try Web3.default.eth.getTransactionDetails(transaction.hash)
	print(details)
	```
	```
	/* prints
	TransactionDetails(blockHash: Optional(32 bytes), blockNumber: Optional(1), transactionIndex: Optional(1), transaction: Transaction
	Nonce: 0
	Gas price: 2000000000
	Gas limit: 21000
	To: 0x57034d57b69b2f172814252Df7A54B072cF46104
	Value: 10000000000000000000
	Data: 00
	v: 11590
	r: 75318665125390684876839360987611904628529668743494333300496321819169931926792
	s: 28634163277963307970864505412680829623562938665383387835249573242584919213107
	Intrinsic chainID: Optional()
	Infered chainID: Optional()
	sender: Optional("0x4BFE5EC6182Dd745c3FB3a20A58b69a18013D8e8")
	hash: Optional(32 bytes))
	*/
	```
	*/
    public struct Using_web3swift_with_Ganache {}
    /**
     
    # How to use web3swift with private geth node
    
    > Note: We are recommending you to use web3swift generated accounts or imported from mnemonics or private key.
    
    > Also we recommending to use Ganache instead of geth cause its much easier
    
    [Generate or import your account]()
    
    ```swift
    let mnemonics = Mnemonics()
    print(mnemonics.string, BIP32Keystore(mnemonics: mnemonics).addresses[0])
    ```
    
    #### Save that mnemonics and address
    
    ```swift
    let mnemonicsString = "nation tornado double since increase orchard tonight left drip talk sand mad"
    let address: Address = "0xDf2bC70175311A6807F085e54881Fc4931359dBF"
    ```
    
    ### Starting geth and sending some ether to your account
    
    Start your geth
    
    ```bash
    geth --rpc --rpccorsdomain '*' --rpcapi 'eth,web3,personal,net,miner,admin,debug,txpool' --nodiscover --dev --rpcport 8545 --rpcaddr 0.0.0.0
    ```
    
    Now send some ether to your web3swift account.
    
    To do this run this code in your get console:
    
    ```js
    eth.sendTransaction({from:eth.coinbase, to: "0xDf2bC70175311A6807F085e54881Fc4931359dBF", value: web3.toWei(100, "ether")})
    ```
    > Dont forget to change recipient address
    
    ### Almost done
    now we have some ether in our account. So just lets use it:
    
    ```swift
    let mnemonicsString = "nation tornado double since increase orchard tonight left drip talk sand mad"
    let address: Address = "0xDf2bC70175311A6807F085e54881Fc4931359dBF"
    
    Web3.default = try .local(port: 8545)
    Web3.default.keystoreManager = try KeystoreManager([BIP32Keystore(mnemonics: mnemonics)])
    
    let balance = try Web3.default.eth.getBalance(address: address)
    
    print("you have \(balance.string(units: .eth)) ether")
    // should print "you have 100 ether"
    ```
    
    # Now you ready to send some real transactions!
    */
    public struct Using_web3swift_with_Geth {}
    
    /**
    # How to create or import an account
    
    If you need to get your account from metamask, ganache, EtherWallet or some other wallet, you need to know its mnemonics or private key. Or you can create account in web3swift and export it.
    
    ## Create account
    
    ```swift
    let mnemonics = Mnemonics()
    let keystore = try! BIP32Keystore(mnemonics: mnemonics)
    print(mnemonics.string)
    Web3.default.keystoreManager = KeystoreManager([keystore])
    ```
    > Note: Save your mnemonics if you want to use this mnemonics later. You cannot get them later from the keystore
    
    ## Import account
    
    ```swift
    let mnemonicsString = "nation tornado double since increase orchard tonight left drip talk sand mad"
    let mnemonics = try Mnemonics(mnemonicsString)
    let keystore = try! BIP32Keystore(mnemonics: mnemonics)
    Web3.default.keystoreManager = KeystoreManager([keystore])
    ```
    
    ## Export account
    
    > Note: You cannot get your mnemonics from your private key or keystore
    
    ```swift
    let privateKey: Data = try keystore.UNSAFE_getPrivateKeyData(password: "", account: keystore.addresses[0])
    ```
    
    ## Use your account in web3swift
    Setup your Web3.default manager
    
    Then import your keystoreManger
    
    ```swift
    Web3.default.keystoreManager = KeystoreManager([keystore])
    ```
    
    Now you can send transactions using your account:
    
    ```swift
    let recipient: Address // recipient address
    var options = Web3Options.default
    options.from = Web3.default.keystoreManager!.addresses[0]
    let transaction = try Web3.default.eth.sendETH(to: recipient, amount: BigUInt("0.01", units: .eth)!, options: options)
    ```
     */
    public struct Create_and_import_account {}
	
	/**
	# Calling custom Smart Contract methods guide
	
	## Test contract code
	```
	pragma solidity ^0.4.25;
	
	contract SomeContract {
		uint256 value;
		function helloWorldMethod () public pure returns (string) {
			return 'helloWorld';
		}
		function setValue (uint256 _value) public returns (bool) {
			value = _value;
			return true;
		}
		function getValue () public view returns (uint256) {
			return value;
		}
		function generateHash(bytes _value) public pure returns (bytes32) {
			return keccak256(_value);
		}
	}
	```
	We deployed this contract at address:
	`0x9eed12f85b8faedc97fc815f874d0f350220b3c7`
	
	## Reading the Smart Contract methods
	```
	let readedValue = try! contractAddress.call("getValue()").wait().uint256()
	```
	
	To read method with some input:
	
	```
	let result = try contractAddress.call("yourMethod(uint256,address,string)", 123, Address("0x9eed12f85b8faedc97fc815f874d0f350220b3c7"), "your string")
	```
	
	if your result is type of uint256 you can read it like that
	
	```
	let value = try result.uint256()
	```
	
	if you have multiple values in your result like `(uint256, string)` you need to get them in the same order:
	
	```
	let value = try result.uint256()
	let string = try result.string()
	```
	
	## Sending transactions
	
	```
	var options = Web3Options.default
	options.from = yourAddress
	let transaction = try! contractAddress.send("setValue(uint256)", 20, options: options).wait()
	```
	
	## Full code
	
	```
	Web3.default = try! .local(port: 8545)
	let mnemonics = try! Mnemonics("figure champion above popular hint clump palace movie false common donate arrive")
	let keystore = try! BIP32Keystore(mnemonics: mnemonics)
	Web3.default.keystoreManager.append(keystore)
	let address = keystore.addresses[0]
	
	let contractAddress: Address = "0x9eed12f85b8faedc97fc815f874d0f350220b3c7"
	
	let helloWorld = try! contractAddress.call("helloWorldMethod()").wait().string()
	print(helloWorld)
	
	let data = "some string".data
	let hash = try! contractAddress.call("generateHash(bytes)", data).wait().uint256()
	print("generated hash: 0x\(hash.solidityData.hex)")
	
	var options = Web3Options.default
	options.from = address
	let transaction = try! contractAddress.send("setValue(uint256)", 20, options: options).wait()
	print("transaction hash:", transaction.hash)
	
	let readedValue = try! contractAddress.call("getValue()").wait().uint256()
	print(readedValue)
	// should return 20 if previous transaction was completed
	```
	
	Logs should look like:
	
	```
	helloWorld
	generated hash: 0x83c737ad570e9f3e71e0d2800958e44770d812e92db2c1758626613d1e6ba514
	transaction hash: 0x02c68664c813ded03666e5a9edd19db508e4259d9a153bf3b838b51936a10ab7
	20
	```
	*/
	public struct Calling_custom_smart_contrct_methods {}

	/**
	# ERC20 Guide
	
	## Before we start
	
	As token address we will use BKX Token:
	`0x45245bc59219eeaaf6cd3f382e078a461ff9de7b`
	
	And we have some token holder:
	`0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8 `
	
	## Getting token name and symbol
	
	```
	let token = ERC20("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
	let name = try token.name()
	let symbol = try token.symbol()
	```
	
	## Getting someones balance
	```
	let address: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
	let token = ERC20("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
	let symbol = try token.symbol()
	let balance = try token.balance(of: address)
	let naturalBalance = try token.naturalBalance(of: address)
	
	// balance in wei
	print(balance, "wei")
	// prints: 39824500000000000000000000 wei
	
	// human readable balance
	print(naturalBalance, symbol)
	// prints: 39824500 BKX
	```
	
	## Sending some tokens
	To send tokens you need to have some ether balance on your account.
	
	```
	let address: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
	let token = ERC20("0x45245bc59219eeaaf6cd3f382e078a461ff9de7b")
	let from: Address = Web3.default.keystoreManager.addresses[0]
	let to: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
	
	// Sending 0.05 BKX
	let amount = NaturalUnits("0.05")
	
	token.options.from = from
	let transaction = try token.transfer(to: to, amount: amount)
	print(transaction.hash)
	```
	> Note: this example will not work if you don't have enough token and ether balance
	
	If you set amount as `BigUInt` it will send it as wei
	> In BKX token: 1000000000000000000 wei == 1 BKX
	
	## List of tokens
	You can check them [here](https://raw.githubusercontent.com/kvhnuke/etherwallet/mercury/app/scripts/tokens/ethTokens.json) or [here](https://github.com/ethereum-lists/tokens/tree/master/tokens/eth).
	
	## Token icons
	Token doesn't have images or urls but you can use some other services like [this repository](https://github.com/MyEtherWallet/ethereum-lists) to check for more token information.
	
	[Here is our token](https://github.com/MyEtherWallet/ethereum-lists/blob/8a687d403155103f7739d503e8919758e1d5f47c/src/tokens/eth/0x45245bc59219eeaaf6cd3f382e078a461ff9de7b.json) where you can get its icon url
	*/
	public struct ERC20_token_guide {}
	
	/**
	 # Using web3swift with remix
	 ## Setting the private node
	 Best private node for testing is ganache its easy to setup and gives you mnemonics for all accounts.
	
	 ![](https://raw.githubusercontent.com/BANKEX/web3swift/gh-pages/Resources/Remix1.png)
	
	 ## Connecting
	
	 Now [open remix](http://remix.ethereum.org) and change address from https to http:
	
	 ![](https://raw.githubusercontent.com/BANKEX/web3swift/gh-pages/Resources/Remix2.png)
	
	 Open `Run` tab and change Environment to `Web3 Provider`
	
	 ![](https://raw.githubusercontent.com/BANKEX/web3swift/gh-pages/Resources/Remix3.png)
	
	 ## Deploying contract
	
	
	 Here is our code that we use for testing:
	
	 ```
	 pragma solidity ^0.4.25;
	
	 contract SomeContract {
	     uint256 value;
	     function helloWorldMethod () public pure returns (string) {
	         return 'helloWorld';
	     }
	     function setValue (uint256 _value) public returns (bool) {
	         value = _value;
	         return true;
	     }
	     function getValue () public view returns (uint256) {
	         return value;
	     }
	     function generateHash(bytes _value) public pure returns (bytes32) {
	         return keccak256(_value);
	     }
	 }
	 ```
	
	 Now deploy contract and copy its address:
	
	 ![](https://raw.githubusercontent.com/BANKEX/web3swift/gh-pages/Resources/Remix4.png)
	
	 And here is our swift code:
	
	 ```
	 // Set your contract address and ganache mnemonics
	 let contractAddress: Address = "0x2f6e1f8f7d528d45d564123282d3fe107b466339"
	 let mnemonics = try! Mnemonics("figure champion above popular hint clump palace movie false common donate arrive")
	
	 // Connecting to your ganache node
	 Web3.default = try! .local(port: 8545)
	
	 // Creating account with your mnemonics
	 let keystore = try! BIP32Keystore(mnemonics: mnemonics)
	 Web3.default.keystoreManager.append(keystore)
	 let address = keystore.addresses[0]
	
	 // Calling helloWorldMethod()
	 let helloWorld = try! contractAddress.call("helloWorldMethod()").wait().string()
	 print(helloWorld)
	
	 // Generating hash
	 let data = "some string".data
	 let hash = try! contractAddress.call("generateHash(bytes)", data).wait().uint256()
	 print("generated hash: 0x\(hash.solidityData.hex)")
	
	 // Sending transaction (setValue)
	 var options = Web3Options.default
	 options.from = address
	 let transaction = try! contractAddress.send("setValue(uint256)", 20, options: options).wait()
	 print("transaction hash:", transaction.hash)
	
	 // Calling getValue
	 let readedValue = try! contractAddress.call("getValue()").wait().uint256()
	 print(readedValue)
	 // should return 20 if previous transaction was completed
	 ```
	 And it prints:
	
	 ```
	 helloWorld
	 generated hash: 0x83c737ad570e9f3e71e0d2800958e44770d812e92db2c1758626613d1e6ba514
	 transaction hash: 0x09c49d00e7f387a48ac48b0074b1f91721e81fb308038e6aa8b2a483140c7946
	 20
	 ```
	*/
	public struct Using_web3swift_with_Remix {}
	
	/**
	# Security tips
	
	## Keeping sensitive information
	
	You can store passwords, mnemonics and private keys in your keychain
	
	To securely store data on your drive use:
	
	```
	try data.write(to: url, options: .completeFileProtection)
	```
	> Note: Data Protection should be enabled in your project
	
	![](/Users/dimas/Desktop/web3swift/Documentation/Resources/Security1.png)
	
	#### This is not a good idea to send mnemonics or private keys to your server.
	
	## Jailbroken device
	For jailbroken devices there is no place to hide. Virus can read data from your keystore, sandbox directory, core data and app memory. And they also can call and edit your functions. But hacker needs a lot of time to do that.
	
	You don't really need to care about jailbroken devices.
	*/
	public struct Security_tips {}
}


