
### You can ask for help in our [Discord Channel](https://discord.gg/3ETv2ST)
<p align="right">
<a href="https://bankex.github.io/web3swift/read-documentation-using-xcode.html" target="_blank">
<img src="https://img.shields.io/badge/Documentation-gray.svg" alt="Support">
</a>
<a href="https://stackoverflow.com/questions/tagged/web3swift" target="_blank">
<img src="https://img.shields.io/badge/Stackoverflow-gray.svg" alt="Stackoverflow">
</a>
<a href="https://github.com/BANKEX/web3swift/wiki/Apps-using-web3swift" target="_blank">
<img src="https://img.shields.io/badge/Apps_using_web3swift-gray.svg" alt="Apps using web3swift">
</a>
</p>

![bkx-foundation-github-swift](https://user-images.githubusercontent.com/3356474/34412791-5b58962c-ebf0-11e7-8460-5592b12e6e9d.png)

<p align="center">
<a href="https://developer.apple.com/swift/" target="_blank">
<img src="https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat" alt="Swift 4.2">
</a>
<a target="_blank">
<img src="https://img.shields.io/badge/Supports-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM%20-orange.svg?style=flat" alt="Compatible">
</a>
<a href="https://developer.apple.com/swift/" target="_blank">
<img src="https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms iOS | macOS">
</a>
<a target="_blank">
<img src="https://img.shields.io/badge/Supports-Objective%20C-blue.svg?style=flat" alt="Compatible">
</a>
</p>


# web3swift

- Swift implementation of [web3.js](https://github.com/ethereum/web3.js/) functionality :zap:
- Interaction with remote node via JSON RPC :thought_balloon:
- Smart-contract ABI parsing :book:
- Local keystore management (geth compatible)
- Private key and transaction were created directly on an iOS device and sent directly to [Infura](https://infura.io) node
- Native API
- Security (as cool as a hard wallet! Right out-of-the-box! :box: )
- No unnecessary dependencies
- Possibility to work with all existing smart contracts
- Referencing the newest features introduced in Solidity

### Features
- Create Account
- Import Account
- Sign transactions
- Send transactions, call functions of smart-contracts, estimate gas costs
- Serialize and deserialize transactions and results to native Swift types
- Convenience functions for chain state: block number, gas price
- Check transaction results and get receipt
- Parse event logs for transaction
- Manage user's private keys through encrypted keystore abstractions
- Batched requests in concurrent mode, checks balances of 580 tokens (from the latest MyEtherWallet repo) over 3 seconds
- Literally following the standards:
<p align="left">
	<a href="https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki" target="_blank">
		<img src="https://img.shields.io/badge/BIP32-gray.svg?style=flat" alt="BIP32">
	</a>
	<a href="https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki" target="_blank">
		<img src="https://img.shields.io/badge/BIP39-gray.svg?style=flat" alt="BIP39">
	</a>
	<a href="https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki" target="_blank">
		<img src="https://img.shields.io/badge/BIP44-gray.svg?style=flat" alt="BIP44">
	</a>
	<a href="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md" target="_blank">
		<img src="https://img.shields.io/badge/EIP%2020-gray.svg?style=flat" alt="EIP 20">
	</a>
	<a href="https://github.com/ethereum/EIPs/issues/67" target="_blank">
		<img src="https://img.shields.io/badge/EIP%2067-gray.svg?style=flat" alt="EIP 67">
	</a>
	<a href="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md" target="_blank">
		<img src="https://img.shields.io/badge/EIP%20155-gray.svg?style=flat" alt="EIP 155">
	</a>
	<a href="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md" target="_blank">
		<img src="https://img.shields.io/badge/EIP%20681-gray.svg?style=flat" alt="EIP 681">
	</a>
	<a href="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md" target="_blank">
		<img src="https://img.shields.io/badge/EIP%20721-gray.svg?style=flat" alt="EIP 721">
	</a>
	<a href="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-777.md" target="_blank">
		<img src="https://img.shields.io/badge/EIP%20777-gray.svg?style=flat" alt="EIP 777">
	</a>
	<a href="https://github.com/ethereum/EIPs/issues/888" target="_blank">
		<img src="https://img.shields.io/badge/EIP%20888-gray.svg?style=flat" alt="EIP 888">
	</a>
</p>

## Requirements
Web3swift requires Swift 4.2 and deploys to `macOS 10.10`, `iOS 9`, `watchOS 2` and `tvOS 9` and `linux`.

Don't forget to set the iOS version in a Podfile, otherwise you get an error if the deployment target is less than the latest SDK.

## Installation

- **Swift Package Manager:**
  Although the Package Manager is still in its infancy, web3swift provides full support for it.
  Add this to the dependency section of your `Package.swift` manifest:

    ```Swift
    .package(url: "https://github.com/BANKEX/web3swift.git", from: "2.1.0")
    ```

- **CocoaPods:** Put this in your `Podfile`:

    ```Ruby
    pod 'web3swift.pod'
    ```

- **Carthage:** Put this in your `Cartfile`:

    ```
    github "BANKEX/web3swift" ~> 2.1
    ```


## Documentation

> Hi. We spend a lot of time working on documentation. If you have some questions after reading it just [open an issue](https://github.com/bankex/web3swift/issues) or ask in our [discord channel](https://discord.gg/3ETv2ST). We would be happy to help you.

Most of the classes are documented and have some examples on how to use it.

### [Read documentation in using Xcode](https://bankex.github.io/web3swift/read-documentation-using-xcode.html)
### [Github Pages](https://bankex.github.io/web3swift)

#### We would appreciate it if you translate our documentation into another language, and will be happy to provide you with all the necessary information on how to do this. We will compensate you for translations that will be included in the master branch.

## Design decisions
- Not every JSON RPC function is exposed yet, priority is given to the ones required for mobile devices
- Functionality was focused on serializing and signing transactions locally on the device to send raw transactions to Ethereum network
- Requirements for password input on every transaction are indeed a design decision. Interface designers can save user passwords with the user's consent
- Public function for private key export is exposed for user convenience, but marked as UNSAFE_ :) Normal workflow takes care of EIP155 compatibility and proper clearing of private key data from memory


## Contribution
For the latest version, please check [develop](https://github.com/BANKEX/web3swift/tree/develop) branch.

Changes made to this branch will be merged into the [master](https://github.com/BANKEX/web3swift/tree/master) branch at some point.

- If you want to contribute, submit a [pull request](https://github.com/BANKEX/web3swift/pulls) against a development `develop` branch.
- If you found a bug, [open an issue](https://github.com/BANKEX/web3swift/issues).
- If you have a feature request, [open an issue](https://github.com/BANKEX/web3swift/issues).


## Special thanks to

- Gnosis team and their library [Bivrost-swift](https://github.com/gnosis/bivrost-swift) for inspiration for the ABI decoding approach
- [Trust iOS Wallet](https://github.com/TrustWallet/trust-wallet-ios) for the collaboration and discussion of the initial idea
- Official Ethereum and Solidity docs, everything was written from ground truth standards

## Donate

<a href="https://brianmacdonald.github.io/Ethonate/address/#0x47FC2e245b983A92EB3359F06E31F34B107B6EF6" target="_blank">
<img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=0x47FC2e245b983A92EB3359F06E31F34B107B6EF6" alt="0x47FC2e245b983A92EB3359F06E31F34B107B6EF6">
</a>
