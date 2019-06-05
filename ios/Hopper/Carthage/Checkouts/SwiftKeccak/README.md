# SwiftKeccak

This is an implementation of Keccak 256 the hash function used in Ethereum as well as the final version of the Sha3 as published by NIST.

It is a wrapper around an older version of the [keccak-tiny](https://github.com/coruus/keccak-tiny) library.

*Important* Ethereum uses the original version of Sha3 which we use here as it's original name "keccak". The final published version of Sha3 had a few minor changes to it, but produce as you would expect different results. In this library we refer to that as "sha3Final".

## Installation

### Carthage

Add the following to your `Cartfile`

```ruby
github "uport-project/SwiftKeccak"
```

## Usage

You can use the `keccak256()` function with both `Data` and `String` inputs.

```swift
import SwiftKeccak

let hash: Data = keccak256("hello")
```

You can also use the `sha3Final256()` function with both `Data` and `String` inputs for the final version of sha3 (see explanation above).

```swift
import SwiftKeccak

let hash: Data = sha3Final256("hello")
```


We also include a handy extension for both `Data` and `String` allowing you to call `keccak()` and `sha3final()` on them.

```swift
import SwiftKeccak

let hash: Data = "hello".keccak()
let hash: Data = "hello".sha3Final()
```
