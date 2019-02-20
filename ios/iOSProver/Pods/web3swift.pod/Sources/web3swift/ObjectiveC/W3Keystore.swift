//
//  W3Keystore.swift
//  web3swift
//
//  Created by Dmitry on 11/8/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

func objc(_ value: AbstractKeystore) -> W3AbstractKeystore {
	switch value {
	case let keystore as KeystoreManager: return keystore.objc
	case let keystore as PlainKeystore: return keystore.objc
	case let keystore as EthereumKeystoreV3: return keystore.objc
	case let keystore as BIP32Keystore: return keystore.objc
	default: fatalError("\(value) is not convertible to objective-c W3AbstractKeystore")
	}
}

extension BIP39Language {
    public var objc: W3BIP39Language {
		switch self {
		case .english: return .english
		case .chinese_simplified: return .chinese_simplified
		case .chinese_traditional: return .chinese_traditional
		case .japanese: return .japanese
		case .korean: return .korean
		case .french: return .french
		case .italian: return .italian
		case .spanish: return .spanish
		}
	}
}
@objc public enum W3BIP39Language: Int, SwiftBridgeable {
	case english
	case chinese_simplified
	case chinese_traditional
	case japanese
	case korean
	case french
	case italian
	case spanish
	public var swift: BIP39Language {
		switch self {
		case .english: return .english
		case .chinese_simplified: return .chinese_simplified
		case .chinese_traditional: return .chinese_traditional
		case .japanese: return .japanese
		case .korean: return .korean
		case .french: return .french
		case .italian: return .italian
		case .spanish: return .spanish
		}
	}
}

@objc public enum W3EntropySize: Int, SwiftBridgeable {
	case b128 = 128
	case b160 = 160
	case b192 = 192
	case b224 = 224
	case b256 = 256
	public var swift: EntropySize {
		return EntropySize(rawValue: rawValue)!
	}
}

@objc public class W3Mnemonics: NSObject, SwiftContainer {
	public let swift: Mnemonics
	public required init(_ swift: Mnemonics) {
		self.swift = swift
	}
	
	@objc public var string: String {
		return swift.string
	}
	@objc public var language: W3BIP39Language {
		return swift.language.objc
	}
	@objc public var entropy: Data {
		get { return swift.entropy }
		set { swift.entropy = newValue }
	}
	@objc public var password: String {
		get { return swift.password }
		set { swift.password = newValue }
	}
	
	@objc public static func seed(from mnemonics: String, password: String) -> Data {
		return Mnemonics.seed(from: mnemonics, password: password)
	}
	
	@objc public init(_ string: String, language: W3BIP39Language = .english) throws {
		swift = try Mnemonics(string, language: language.swift)
	}
	@objc public init(entropySize: W3EntropySize = .b256, language: W3BIP39Language = .english) {
		swift = Mnemonics(entropySize: entropySize.swift, language: language.swift)
	}
	@objc public init(entropy: Data, language: W3BIP39Language = .english) throws {
		swift = try Mnemonics(entropy: entropy, language: language.swift)
	}
	@objc public func seed() -> Data {
		return swift.seed()
	}
	@objc public override var description: String {
		return string
	}
}

@objc public protocol W3AbstractKeystore {
	var addresses: [W3Address] { get }
	var isHDKeystore: Bool { get }
	func UNSAFE_getPrivateKeyData(password: String, account: W3Address) throws -> Data
}

@objc public class W3HDVersion: NSObject, SwiftContainer {
	public var swift: HDNode.HDversion
	public required init(_ swift: HDNode.HDversion) {
		self.swift = swift
	}
	@objc public override init() {
		self.swift = HDNode.HDversion()
	}
	
	@objc public var privatePrefix: Data {
		get { return swift.privatePrefix }
		set { swift.privatePrefix = newValue }
	}
	@objc public var publicPrefix: Data {
		get { return swift.publicPrefix }
		set { swift.publicPrefix = newValue }
	}
}
extension HDNode {
    public var objc: W3HDNode {
		return W3HDNode(self)
	}
}
@objc public class W3HDNode: NSObject, SwiftContainer {
	public let swift: HDNode
	public required init(_ swift: HDNode) {
		self.swift = swift
	}
	
	@objc public var path: String? {
		get { return swift.path }
		set { swift.path = newValue }
	}
	@objc public var privateKey: Data? {
		get { return swift.privateKey }
		set { swift.privateKey = newValue }
	}
	@objc public var publicKey: Data {
		get { return swift.publicKey }
		set { swift.publicKey = newValue }
	}
	@objc public var chaincode: Data {
		get { return swift.chaincode }
		set { swift.chaincode = newValue }
	}
	@objc public var depth: UInt8 {
		get { return swift.depth }
		set { swift.depth = newValue }
	}
	@objc public var parentFingerprint: Data {
		get { return swift.parentFingerprint }
		set { swift.parentFingerprint = newValue }
	}
	@objc public var childNumber: UInt32 {
		get { return swift.childNumber }
		set { swift.childNumber = newValue }
	}
	@objc public var isHardened: Bool {
		return swift.isHardened
	}
	
	@objc public var index: UInt32 {
		return swift.index
	}
	
	@objc public var hasPrivate: Bool {
		return swift.hasPrivate
	}
	
	@objc public init?(serializedString: String) {
		guard let swift = HDNode(serializedString) else { return nil }
		self.swift = swift
	}
	
	@objc public init?(data: Data) {
		guard let swift = HDNode(data) else { return nil }
		self.swift = swift
	}
	
	@objc public init(seed: Data) throws {
		swift = try HDNode(seed: seed)
	}
	
	@objc public static var defaultPath: String {
		get { return HDNode.defaultPath }
		set { HDNode.defaultPath = newValue }
	}
	@objc public static var defaultPathPrefix: String {
		get { return HDNode.defaultPathPrefix }
		set { HDNode.defaultPathPrefix = newValue }
	}
	@objc public static var defaultPathMetamask: String {
		get { return HDNode.defaultPathMetamask }
		set { HDNode.defaultPathMetamask = newValue }
	}
	@objc public static var defaultPathMetamaskPrefix: String {
		get { return HDNode.defaultPathMetamaskPrefix }
		set { HDNode.defaultPathMetamaskPrefix = newValue }
	}
	@objc public static var hardenedIndexPrefix: UInt32 {
		get { return HDNode.hardenedIndexPrefix }
		set { HDNode.hardenedIndexPrefix = newValue }
	}
	
	
	@objc public func derive(index: UInt32, derivePrivateKey: Bool, hardened: Bool = false) throws -> W3HDNode {
		return try swift.derive(index: index, derivePrivateKey: derivePrivateKey, hardened: hardened).objc
	}
	
	@objc public func derive(path: String, derivePrivateKey: Bool = true) throws -> W3HDNode {
		return try swift.derive(path: path, derivePrivateKey: derivePrivateKey).objc
	}
	
	@objc public func serializeToString(serializePublic: Bool = true, version: W3HDVersion = W3HDVersion()) -> String? {
		return swift.serializeToString(serializePublic: serializePublic, version: version.swift)
	}
	
	@objc public func serialize(serializePublic: Bool = true, version: W3HDVersion = W3HDVersion()) -> Data? {
		return swift.serialize(serializePublic: serializePublic, version: version.swift)
	}
}

extension BIP32Keystore {
    public var objc: W3BIP32Keystore {
		return W3BIP32Keystore(self)
	}
}
@objc public class W3BIP32Keystore: NSObject, W3AbstractKeystore, SwiftContainer {
	public let swift: BIP32Keystore
	public required init(_ swift: BIP32Keystore) {
		self.swift = swift
	}
	@objc public var addresses: [W3Address] {
		return swift.addresses.map { $0.objc }
	}
	@objc public var isHDKeystore: Bool {
		get { return swift.isHDKeystore }
		set { swift.isHDKeystore = newValue }
	}
	
	@objc public func UNSAFE_getPrivateKeyData(password: String, account: W3Address) throws -> Data {
		return try swift.UNSAFE_getPrivateKeyData(password: password, account: account.swift)
	}
	
	//    @objc public var mnemonics: String?
	@objc public var paths: [String: W3Address] {
		get { return swift.paths.mapValues { $0.objc } }
		set { swift.paths = newValue.mapValues { $0.swift } }
	}
	@objc public var rootPrefix: String {
		get { return swift.rootPrefix }
		set { swift.rootPrefix = newValue }
	}
	@objc public init?(jsonString: String) {
		guard let swift = BIP32Keystore(jsonString) else { return nil }
		self.swift = swift
	}
	
	@objc public init?(jsonData: Data) {
		guard let swift = BIP32Keystore(jsonData) else { return nil }
		self.swift = swift
	}
	
	@objc public init(mnemonics: W3Mnemonics, password: String = "BANKEXFOUNDATION", prefixPath: String = HDNode.defaultPathMetamaskPrefix) throws {
		swift = try BIP32Keystore(mnemonics: mnemonics.swift, password: password, prefixPath: prefixPath)
	}
	
	@objc public init(seed: Data, password: String = "BANKEXFOUNDATION", prefixPath: String = HDNode.defaultPathMetamaskPrefix) throws {
		swift = try BIP32Keystore(seed: seed, password: password, prefixPath: prefixPath)
	}
	
	@objc public func createNewChildAccount(password: String = "BANKEXFOUNDATION") throws {
		try swift.createNewChildAccount()
	}
	
	@objc public func createNewAccount(parentNode: W3HDNode, password: String = "BANKEXFOUNDATION", aesMode: String = "aes-128-cbc") throws {
		try swift.createNewAccount(parentNode: parentNode.swift, password: password, aesMode: aesMode)
	}
	
	@objc public func createNewCustomChildAccount(password: String = "BANKEXFOUNDATION", path: String) throws {
		try swift.createNewCustomChildAccount(password: password, path: path)
	}
	
	@objc public func regenerate(oldPassword: String, newPassword: String, dkLen: Int = 32, N: Int = 4096, R: Int = 6, P: Int = 1) throws {
		try swift.regenerate(oldPassword: oldPassword, newPassword: newPassword, dkLen: dkLen, N: N, R: R, P: P)
	}
	/// also check for empty data
	@objc public func serialize() throws -> Data {
		guard let data = try swift.serialize() else { throw opt }
		return data
	}
	
	@objc public func serializeRootNodeToString(password: String = "BANKEXFOUNDATION") throws -> String {
		return try swift.serializeRootNodeToString(password: password)
	}
}

extension PlainKeystore {
    public var objc: W3PlainKeystore {
		return W3PlainKeystore(self)
	}
}
@objc public class W3PlainKeystore: NSObject, W3AbstractKeystore, SwiftContainer {
	public let swift: PlainKeystore
	public required init(_ swift: PlainKeystore) {
		self.swift = swift
	}
	
	@objc public var addresses: [W3Address] {
		return swift.addresses.map { $0.objc }
	}
	@objc public var isHDKeystore: Bool {
		return swift.isHDKeystore
	}
	@objc public func UNSAFE_getPrivateKeyData(password: String = "", account: W3Address) throws -> Data {
		return try swift.UNSAFE_getPrivateKeyData(password: password, account: account.swift)
	}
	
	@objc public init(privateKey: Data) throws {
		swift = try PlainKeystore(privateKey: privateKey)
	}
}

extension EthereumKeystoreV3 {
    public var objc: W3EthereumKeystoreV3 {
		return W3EthereumKeystoreV3(self)
	}
}
@objc public class W3EthereumKeystoreV3: NSObject, W3AbstractKeystore, SwiftContainer {
	public let swift: EthereumKeystoreV3
	public required init(_ swift: EthereumKeystoreV3) {
		self.swift = swift
	}
	
	@objc public func getAddress() -> W3Address? {
		return swift.address?.objc
	}
	
	@objc public var addresses: [W3Address] {
		return swift.addresses.map { $0.objc }
	}
	@objc public var isHDKeystore: Bool {
		get { return swift.isHDKeystore }
		set { swift.isHDKeystore = newValue }
	}
	
	@objc public func UNSAFE_getPrivateKeyData(password: String, account: W3Address) throws -> Data {
		return try swift.UNSAFE_getPrivateKeyData(password: password, account: account.swift)
	}
	
	@objc public init?(jsonString: String) {
		guard let swift = EthereumKeystoreV3(jsonString) else { return nil }
		self.swift = swift
	}
	
	@objc public init?(jsonData: Data) {
		guard let swift = EthereumKeystoreV3(jsonData) else { return nil }
		self.swift = swift
	}
	
	@objc public init(password: String = "BANKEXFOUNDATION", aesMode: String = "aes-128-cbc") throws {
		guard let swift = try EthereumKeystoreV3(password: password, aesMode: aesMode) else { throw opt }
		self.swift = swift
	}
	
	@objc public init(privateKey: Data, password: String = "BANKEXFOUNDATION", aesMode: String = "aes-128-cbc") throws {
		guard let swift = try EthereumKeystoreV3(privateKey: privateKey, password: password, aesMode: aesMode) else { throw opt }
		self.swift = swift
	}
	
	@objc public func regenerate(oldPassword: String, newPassword: String, dkLen: Int = 32, N: Int = 4096, R: Int = 6, P: Int = 1) throws {
		try swift.regenerate(oldPassword: oldPassword, newPassword: newPassword, dkLen: dkLen, N: N, R: R, P: P)
	}
	
	@objc public func serialize() throws -> Data {
		guard let data = try swift.serialize() else { throw opt }
		return data
	}
}

extension KeystoreManager {
    public var objc: W3KeystoreManager {
		return W3KeystoreManager(self)
	}
}
@objc public class W3KeystoreManager: NSObject, W3AbstractKeystore, SwiftContainer {
	public let swift: KeystoreManager
	public required init(_ swift: KeystoreManager) {
		self.swift = swift
	}
	@objc public var addresses: [W3Address] {
		return swift.addresses.map { $0.objc }
	}
	@objc public var isHDKeystore: Bool {
		return swift.isHDKeystore
	}
	@objc public func UNSAFE_getPrivateKeyData(password: String = "", account: W3Address) throws -> Data {
		return try swift.UNSAFE_getPrivateKeyData(password: password, account: account.swift)
	}
	
	@objc public static var all: [W3KeystoreManager] {
		get { return KeystoreManager.all.map { $0.objc } }
		set { KeystoreManager.all = newValue.map { $0.swift } }
	}
	@objc public static var `default`: W3KeystoreManager? {
		return KeystoreManager.default?.objc
	}
	@objc public static func managerForPath(_ path: String, scanForHDWallets: Bool = false, suffix: String? = nil) -> W3KeystoreManager? {
		return KeystoreManager.managerForPath(path, scanForHDwallets: scanForHDWallets, suffix: suffix)?.objc
	}
	
	@objc public func walletForAddress(_ address: W3Address) -> W3AbstractKeystore? {
		guard let keystore = swift.walletForAddress(address.swift) else { return nil }
		switch keystore {
		case let keystore as KeystoreManager: return keystore.objc
		case let keystore as PlainKeystore: return keystore.objc
		case let keystore as EthereumKeystoreV3: return keystore.objc
		case let keystore as BIP32Keystore: return keystore.objc
		default: return nil
		}
	}
	
	@objc public var keystores: [W3EthereumKeystoreV3] {
		return swift.keystores.map { $0.objc }
	}
	
	@objc public var bip32keystores: [W3BIP32Keystore] {
		return swift.bip32keystores.map { $0.objc }
	}
	
	@objc public var plainKeystores: [W3PlainKeystore] {
		return swift.plainKeystores.map { $0.objc }
	}
	
	@objc public init(ethereumKeystores: [W3EthereumKeystoreV3]) {
		swift = KeystoreManager(ethereumKeystores.map { $0.swift })
	}
	
	@objc public init(bip32Keystores: [W3BIP32Keystore]) {
		swift = KeystoreManager(bip32Keystores.map { $0.swift })
	}
	
	@objc public init(plainKeystores: [W3PlainKeystore]) {
		swift = KeystoreManager(plainKeystores.map { $0.swift })
	}
    @objc public override init() {
        swift = KeystoreManager()
    }
}
