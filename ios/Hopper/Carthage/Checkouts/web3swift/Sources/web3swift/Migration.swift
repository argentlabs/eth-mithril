//
//  Merge.swift
//  web3swift-iOS
//
//  Created by Dmitry on 29/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt


/// TIP
/// To quickly fix all renamed functions you can do:
/// 1. (cmd + ') to jump to next issue
/// 2. (ctrl + alt + cmd + f) to fix all issues in current file
/// 3. repeat

// MARK:- web3swift 2.2 changes
public typealias DictionaryReader = AnyReader

// MARK:- web3swift 2.1 changes

extension EthereumBloomFilter {
    @available(*, deprecated: 2.1, renamed: "test(topic:)")
    public func lookup(_ topic: Data) -> Bool {
        return test(topic: topic)
    }
    @available(*, deprecated: 2.1, message: "Use bloom.test(topic:)")
    public static func bloomLookup(_ bloom: EthereumBloomFilter, topic: Data) -> Bool {
        return bloom.test(topic: topic)
    }
    
    @available(*, deprecated: 2.1, message: "Use bloom.test(topic:)")
    public static func bloomLookup(_ bloom: EthereumBloomFilter, topic: BigUInt) -> Bool {
        return bloom.test(topic: topic)
    }
}

extension EthereumKeystoreV3 {
	@available(*,deprecated: 2.1, message: "Use .address instead of .getAddress()")
	public func getAddress() -> Address? {
		return address
	}
}

@available (*,deprecated: 2.1, renamed: "EventParserResult")
public typealias EventParserResultProtocol = EventParserResult

@available (*,deprecated: 2.1, message: "Use JsonRpcRequest(method:parameters:)")
public struct JsonRpcRequestFabric {
	public static func prepareRequest(_ method: JsonRpcMethod, parameters: [Encodable]) -> JsonRpcRequest {
		return JsonRpcRequest(method: method, parametersArray: parameters)
	}
}
@available(*,deprecated: 2.1, renamed: "SolidityDataReader")
public typealias Web3DataResponse = SolidityDataReader

extension Web3Contract {
	public typealias TransactionIntermediate = web3swift.TransactionIntermediate
}

// MARK:- web3swift 2.0 changes

@available (*, deprecated: 2.0, renamed: "JsonRpcRequest")
public typealias JSONRPCrequest = JsonRpcRequest
@available (*, deprecated: 2.0, renamed: "JsonRpcParams")
public typealias JSONRPCparams = JsonRpcParams
@available (*, deprecated: 2.0, renamed: "JsonRpcRequestFabric")
public typealias JSONRPCRequestFabric = JsonRpcRequestFabric
@available (*, deprecated: 2.0, renamed: "JsonRpcResponse")
public typealias JSONRPCresponse = JsonRpcResponse
@available (*, deprecated: 2.0, renamed: "JsonRpcResponseBatch")
public typealias JSONRPCresponseBatch = JsonRpcResponseBatch
@available (*, deprecated: 2.0, renamed: "Address")
public typealias EthereumAddress = Address

public extension Web3 {
    @available (*, deprecated: 2.0, message: "Use Web3Units")
    typealias Units = Web3Units
    // @available (*, deprecated: 2.0, message: "Use Web3Utils")
    // i'll leave it here
    typealias Utils = Web3Utils
    @available (*, deprecated: 2.0, message: "Use Web3Eth")
    typealias Eth = Web3Eth
    @available (*, deprecated: 2.0, message: "Use Web3Eth")
    typealias Personal = Web3Personal
    @available (*, deprecated: 2.0, message: "Use Web3Eth")
    typealias BrowserFunctions = Web3BrowserFunctions
    typealias Web3Wallet = web3swift.Web3Wallet

    @available (*, deprecated: 2.0, message: "use Web3(url: URL)")
    static func new(_ providerURL: URL) -> Web3? {
        guard let provider = Web3HttpProvider(providerURL) else { return nil }
        return Web3(provider: provider)
    }

    /// Initialized Web3 instance bound to Infura's mainnet provider.
    @available (*, deprecated: 2.0, message: "use Web3(infura: .mainnet, accessToken: String?)")
    static func InfuraMainnetWeb3(accessToken: String? = nil) -> Web3 {
        let infura = InfuraProvider(.mainnet, accessToken: accessToken)!
        return Web3(provider: infura)
    }

    /// Initialized Web3 instance bound to Infura's rinkeby provider.
    @available (*, deprecated: 2.0, message: "use Web3(infura: .rinkeby, accessToken: String?)")
    static func InfuraRinkebyWeb3(accessToken: String? = nil) -> Web3 {
        let infura = InfuraProvider(.rinkeby, accessToken: accessToken)!
        return Web3(provider: infura)
    }

    /// Initialized Web3 instance bound to Infura's ropsten provider.
    @available (*, deprecated: 2.0, message: "use Web3(infura: .ropsten, accessToken: String?)")
    static func InfuraRopstenWeb3(accessToken: String? = nil) -> Web3 {
        let infura = InfuraProvider(.ropsten, accessToken: accessToken)!
        return Web3(provider: infura)
    }
}

public extension Web3Eth {
    @available(*, unavailable, message: "Use sendETH with BigUInt(\"1.01\",units: .eth)")
    public func sendETH(to _: Address, amount _: String, units _: Web3Units = .eth, extraData _: Data = Data(), options _: Web3Options? = nil) throws -> TransactionIntermediate { fatalError() }

    @available(*, unavailable, message: "Use sendETH BigUInt(\"some\",units: .eth)")
    public func sendETH(from _: Address, to _: Address, amount _: String, units _: Web3Units = .eth, extraData _: Data = Data(), options _: Web3Options? = nil) -> TransactionIntermediate? { fatalError() }

    @available(*, unavailable, message: "Use ERC20 class instead")
    public func sendERC20tokensWithKnownDecimals(tokenAddress _: Address, from _: Address, to _: Address, amount _: BigUInt, options _: Web3Options? = nil) throws -> TransactionIntermediate {
        fatalError("")
    }

    @available(*, unavailable, message: "Use ERC20 class instead")
    public func sendERC20tokensWithNaturalUnits(tokenAddress _: Address, from _: Address, to _: Address, amount _: String, options _: Web3Options? = nil) throws -> TransactionIntermediate {
        fatalError("")
    }
}

extension Web3Utils {
    @available(*,deprecated: 2.0,message: "Use number.string(units:decimals:decimalSeparator:options:)")
    public static func formatToEthereumUnits(_ bigNumber: BigInt, toUnits: Web3Units = .eth, decimals: Int = 4, decimalSeparator: String = ".") -> String {
        return bigNumber.string(units: toUnits, decimals: decimals, decimalSeparator: decimalSeparator)
    }
    @available(*,deprecated: 2.0,message: "Use number.string(unitDecimals:formattingDecimals:decimalSeparator:options:)")
    public static func formatToPrecision(_ bigNumber: BigInt, numberDecimals: Int = 18, formattingDecimals: Int = 4, decimalSeparator: String = ".", fallbackToScientific: Bool = false) -> String {
        var options = BigUInt.StringOptions.default
        if fallbackToScientific {
            options.insert(.fallbackToScientific)
        }
        return bigNumber.string(unitDecimals: numberDecimals, decimals: formattingDecimals, decimalSeparator: decimalSeparator, options: options)
    }
    @available(*,deprecated: 2.0,message: "Use number.string(units:formattingDecimals:decimalSeparator:options:)")
    public static func formatToEthereumUnits(_ bigNumber: BigUInt, toUnits: Web3Units = .eth, decimals: Int = 4, decimalSeparator: String = ".", fallbackToScientific: Bool = false) -> String {
        var options = BigUInt.StringOptions.default
        if fallbackToScientific {
            options.insert(.fallbackToScientific)
        }
        return bigNumber.string(units: toUnits, decimals: decimals, decimalSeparator: decimalSeparator, options: options)
    }
    @available(*,deprecated: 2.0,message: "Use number.string(unitDecimals:formattingDecimals:decimalSeparator:options:)")
    public static func formatToPrecision(_ bigNumber: BigUInt, numberDecimals: Int = 18, formattingDecimals: Int = 4, decimalSeparator: String = ".", fallbackToScientific: Bool = false) -> String {
        var options = BigUInt.StringOptions.default
        if fallbackToScientific {
            options.insert(.fallbackToScientific)
        }
        return bigNumber.string(unitDecimals: numberDecimals, decimals: formattingDecimals, decimalSeparator: decimalSeparator, options: options)
    }
}

public extension Web3Options {
    @available(*, deprecated: 2.0, message: "renamed to .default")
    public static func defaultOptions() -> Web3Options { return .default }
}


public struct BIP39 {
    @available(*, unavailable, message: "Use try Mnemonics(entropy:language:)")
    public static func generateMnemonicsFromEntropy(entropy: Data, language: BIP39Language = BIP39Language.english) -> String? {
        fatalError()
    }

    @available(*, unavailable, message: "Use Mnemonics(entropySize:language:)")
    public static func generateMnemonics(bitsOfEntropy: Int, language: BIP39Language = BIP39Language.english) -> String? {
        fatalError()
    }

    @available(*,deprecated: 2.0,message: "Use Mnemonics().entropy")
    public static func mnemonicsToEntropy(_ mnemonics: String, language: BIP39Language = BIP39Language.english) -> Data? {
        fatalError()
    }

    @available(*,deprecated: 2.0,message: "Use Mnemonics().seed(password:)")
    public static func seedFromMmemonics(_ mnemonics: String, password: String = "", language: BIP39Language = BIP39Language.english) -> Data? {
        fatalError()
    }
}

extension KeystoreManager {
    @available (*, deprecated: 2.0, renamed: "default")
    static var defaultManager: KeystoreManager? {
        return KeystoreManager.default
    }
}

extension Web3 {
    @available (*, deprecated: 2.0, message: "Renamed Web3.web3contract to Web3Contract")
    typealias web3contract = Web3Contract
}

extension BIP32Keystore {
    @available (*, deprecated: 2.0, message: "Use init with Mnemonics")
    public convenience init(mnemonics: String, password: String = "BANKEXFOUNDATION", mnemonicsPassword: String = "", language: BIP39Language = .english, prefixPath: String = HDNode.defaultPathMetamaskPrefix) throws {
        let mnemonics = try Mnemonics(mnemonics, language: language)
        mnemonics.password = mnemonicsPassword
        try self.init(mnemonics: mnemonics, password: password, prefixPath: prefixPath)
    }
}
