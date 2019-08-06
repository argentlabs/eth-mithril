<p align="center"><img src="https://i.imgur.com/SXJfUWH.png" width="280px"/></p>

[Hopper](https://hoppereth.org) is an Open-Source Mixer for Mobile-friendly private transfers on Ethereum. It allows the private transfer of value from one Ethereum account to another, via an iOS client.

Users can deposit notes of 1 ETH into a mixer smart contract and withdraw them later to a different account by only providing a Zero-Knowledge proof (zkSNARK) that they previously deposited a note into the mixer, without revealing from which account that note was sent.

Relayers are used to post transactions to the blockchain so that the recipient of a private transfer can withdraw a private note from the mixer without needing any prior ether.

This project is based on previous work on trustless Ethereum mixers by [@barryWhiteHat](https://github.com/barryWhiteHat/miximus) and [@HarryR](https://github.com/HarryR/ethsnarks-miximus).

# Perform a private transfer on iOS

⚠️ Please note that Hopper is in alpha state and should be used with caution. It has not been properly audited and may contain bugs that result in the loss of your funds. ⚠️

1. Download the Hopper iOS app from [TestFlight](https://testflight.apple.com/join/cI3fdnQu) or build and run the Xcode project in `./ios/Hopper/Hopper.xcworkspace`
2. In the app, tap the "+" button in the upper-right corner. Enter the destination address (the address that will receive the value transfer). Tap "Commit". A row gets inserted into the app's table to represent your transfer.
3. Tap the "Fund" button on this new table row. Send 1 ETH to the displayed mixer address, using a gas limit of 1,000,000 and using the displayed "transaction data". You can use the [Nifty browser plugin](https://github.com/poanetwork/nifty-wallet) to create that transaction or any other wallet that allows you to specify optional transaction data (note that the latest versions of Metamask no longer let you do that).
4. When your transfer gets mined, it will be detected by the client and the "Fund" button will change into a "Withdraw" button. You can see how many other people have transferred a note to the mixer since you deposited your secret note. Wait for a few deposits to be added to the mixer by others in order to increase your anonymity set. When you're satisfied that you have waited long enough, tap "Withdraw" to generate a Zero-Knowledge proof that you previously sent a deposit to the mixer (without revealing which deposit it was). The proof gets send to the relayer which posts it to the mixer contract. The mixer contract validates the proof, sends 1 ETH to the destination address (minus the gas cost paid by the relayer) and marks the deposit as "withdrawn".

# Technical details

## Deposit

The iOS client forms a commitment by computing the sha256 hash of a randomly generated secret and the destination address. When this commitment is sent to the mixer contract (along with 1 ETH), it is added as the leaf of a merkle tree:

```
leaf_hash = sha256(secret, destination_address)
```

## Withdrawal

To withdraw the commitment, the client must prove to the mixer that it knows the secret behind one of the leaves added to the merkle tree, without revealing that secret. More precisely, it proves that it knows (1) a merkle path from a certain leaf to the root of the merkle tree and (2) the pre-image of that leaf:

```
(1) merkle_root = merkle_verify(leaf_hash, leaf_index, merkle_path)
(2) leaf_hash = sha256(secret, destination_address)
```

In the above constraints, `merkle_root`, and `destination_address` are public inputs that can be read by anyone at the time of withdrawal, whereas `leaf_index`, `merkle_path` and `secret` are private inputs that are not sent to the contract.

In order to prevent double spending, the client must also provide a so-called "nullifier" as public input, which will be stored by the contract to mark the commitment as "withdrawn". The nullifier is computed as the hash of the secret:

```
(3) nullifier = hash(secret)
```

Equations (1), (2) and (3) make up the constraints of the zkSNARK circuit.

## MiMC Hashing

In order to minimize the number of constraints in the zkSNARK circuit and as a result minimize the proving time, equations (1) and (3) use a special type of hash function known as [MiMC](https://eprint.iacr.org/2016/492), that have _Minimal Multiplicative Complexity_. In contrast, because the security properties of this type of hashing function are still being studied, we chose to use the highly reliable sha256 hash method to compute the commitment leaf in equation (2). This is because if MiMC turns out not to be pre-image resistant and we use MiMC instead of sha256 in (2), an attacker could come up with an arbitrary merkle path and withdraw any deposit. Using sha256 in (2) protects us against that as long as the hash function `x -> MiMC(x, R)`, where `R` is a fixed constant, is pre-image resistant.

# Build

## Build the Prover library for macOS

Requires brew.

- Install dependencies:
  ```
  brew install python3 pkg-config boost cmake gmp openssl
  ```
- Build the library:
  ```
  make build
  ```

## Build the Prover library for iOS

Requires brew.

- Install dependencies:
  ```
  brew install python3 pkg-config boost cmake gmp openssl
  ```
- Build the library:
  ```
  make ios-build-universal
  ```

# Run Tests

## Test the zkSNARK Prover (Python)

- Install dependencies:
  ```
  pip3 install py_ecc==1.4.2 bitstring pysha3 coverage pyblake2
  ```
- Run tests:
  ```
  make python-test
  ```

## Test the mixer contract (Solidity)

Requires npm.

- Install dependencies:
  ```
  npm i -g truffle ganache-cli
  ```
- Launch Ganache on port 7545
  ```
  ganache-cli -p 7545
  ```
- Run tests:
  ```
  make solidity-test
  ```
