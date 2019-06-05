//
//  KeystoreManager.swift
//  web3swift
//
//  Created by Alexander Vlasov on 04.12.2017.
//  Copyright © 2017 Alexander Vlasov. All rights reserved.
//

import Foundation

/**
 Manager for your keystores.
 */
public class KeystoreManager: AbstractKeystore {
    /// Returns true if you don't have any keystores
    public var isEmpty: Bool { return bip32keystores.isEmpty && keystores.isEmpty && plainKeystores.isEmpty }
    /// Returns true if you don't have any bip32 keystores
    public var isHDKeystore: Bool { return !bip32keystores.isEmpty }
    /// Returns all addresses in all keystores
    public var addresses: [Address] {
        var toReturn = [Address]()
        for keystore in keystores {
            guard let key = keystore.addresses.first else { continue }
            if key.isValid {
                toReturn.append(key)
            }
        }
        for keystore in bip32keystores {
            let allAddresses = keystore.addresses
            for addr in allAddresses {
                if addr.isValid {
                    toReturn.append(addr)
                }
            }
        }
        for keystore in plainKeystores {
            guard let key = keystore.addresses.first else { continue }
            if key.isValid {
                toReturn.append(key)
            }
        }
        return toReturn
    }
    
    /// Searches for account in your keystores and decrypts its private key using provided password.
    ///
    /// - Parameters:
    ///   - password: Password that would be used to encrypt private key
    ///   - account: Account for your private key
    /// - Returns: Private key data
    /// - Throws: If cannot find an account or decrypt private key
    public func UNSAFE_getPrivateKeyData(password: String = "BANKEXFOUNDATION", account: Address) throws -> Data {
        guard let keystore = self.walletForAddress(account) else { throw AbstractKeystoreError.invalidAccountError }
        return try keystore.UNSAFE_getPrivateKeyData(password: password, account: account)
    }
    
    /// Returns all your keystore managers
    public static var all = [KeystoreManager]()
    
    /// Returns default keystore manager or nil if don't have any.
    public static var `default`: KeystoreManager? {
        return KeystoreManager.all.safe(0)
    }
    
    /// Returns keystore manager with provided path.
    ///
    /// - Parameters:
    ///   - path: local directory path for scanning
    ///   - scanForHDwallets: Should scan for HD Wallets
    ///   - suffix: File suffix
    /// - Returns: Keystore manager with found keystores
    public static func managerForPath(_ path: String, scanForHDwallets: Bool = false, suffix: String? = nil) -> KeystoreManager? {
        guard let newManager = try? KeystoreManager(path, scanForHDwallets: scanForHDwallets, suffix: suffix), let manager = newManager else { return nil }
        return manager
    }
    
    /// Searches for the keystore that contains provided address
    ///
    /// - Parameter address: Account address
    /// - Returns: Keystore that contains this address.
    /// Returns nil if address is not found in any keystore.
    public func walletForAddress(_ address: Address) -> AbstractKeystore? {
        for keystore in keystores {
            guard let key = keystore.addresses.first else { continue }
            if key == address && key.isValid {
                return keystore as AbstractKeystore?
            }
        }
        for keystore in bip32keystores {
            let allAddresses = keystore.addresses
            for addr in allAddresses {
                if addr == address && addr.isValid {
                    return keystore as AbstractKeystore?
                }
            }
        }
        for keystore in plainKeystores {
            guard let key = keystore.addresses.first else { continue }
            if key == address && key.isValid {
                return keystore as AbstractKeystore?
            }
        }
        return nil
    }

    /// V3 Keystores
    public var keystores = [EthereumKeystoreV3]()
    /// HD Wallets
    public var bip32keystores = [BIP32Keystore]()
    /// Plain Keystores
    public var plainKeystores = [PlainKeystore]()

    /// Init with V3 Keystores
    ///
    /// - Parameter keystores: Keystores that would be stored in .keystores
    public init(_ keystores: [EthereumKeystoreV3]) {
        self.keystores = keystores
    }
    /// Init with HD Wallets
    ///
    /// - Parameter keystores: Keystores that would be stored in .bip32keystores
    public init(_ keystores: [BIP32Keystore]) {
        bip32keystores = keystores
    }
    /// Init with Plain keystores
    ///
    /// - Parameter keystores: Keystores that would be stored in .plainKeystores
    public init(_ keystores: [PlainKeystore]) {
        plainKeystores = keystores
    }
    /// Init with no keystores
    public init() {}
    
    /// Appends keystore
    ///
    /// - Parameter keystore: Keystore to append
    public func append(_ keystore: EthereumKeystoreV3) {
        keystores.append(keystore)
    }
    /// Appends keystore
    ///
    /// - Parameter keystore: Keystore to append
    public func append(_ keystore: BIP32Keystore) {
        bip32keystores.append(keystore)
    }
    /// Appends keystore
    ///
    /// - Parameter keystore: Keystore to append
    public func append(_ keystore: PlainKeystore) {
        plainKeystores.append(keystore)
    }

    private init?(_ path: String, scanForHDwallets: Bool = false, suffix: String? = nil) throws {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        var exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        if !exists && !isDir.boolValue {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        }
        if !isDir.boolValue {
            return nil
        }
        let allFiles = try fileManager.contentsOfDirectory(atPath: path)
        if suffix != nil {
            for file in allFiles where file.hasSuffix(suffix!) {
                var filePath = path
                if !path.hasSuffix("/") {
                    filePath = path + "/"
                }
                filePath = filePath + file
                guard let content = fileManager.contents(atPath: filePath) else { continue }
                if !scanForHDwallets {
                    guard let keystore = EthereumKeystoreV3(content) else { continue }
                    keystores.append(keystore)
                } else {
                    guard let bipkeystore = BIP32Keystore(content) else { continue }
                    bip32keystores.append(bipkeystore)
                }
            }
        } else {
            for file in allFiles {
                var filePath = path
                if !path.hasSuffix("/") {
                    filePath = path + "/"
                }
                filePath = filePath + file
                guard let content = fileManager.contents(atPath: filePath) else { continue }
                if !scanForHDwallets {
                    guard let keystore = EthereumKeystoreV3(content) else { continue }
                    keystores.append(keystore)
                } else {
                    guard let bipkeystore = BIP32Keystore(content) else { continue }
                    bip32keystores.append(bipkeystore)
                }
            }
        }
    }
}
