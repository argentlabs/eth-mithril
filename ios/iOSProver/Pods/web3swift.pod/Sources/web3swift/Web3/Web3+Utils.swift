//
//  web3utils.swift
//  web3swift
//
//  Created by Alexander Vlasov on 18.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/// Namespaced Utils functions. Are not bound to particular web3 instance, so capitalization matters.
public class Web3Utils {

}

/// Various units used in Ethereum ecosystem
public enum Web3Units: Int {
    /// 18 decimals
	case eth = 18
    /// 0 decimals
	case wei = 0
    /// 3 decimals
	case kWei = 3
    /// 6 decimals
	case mWei = 6
    /// 9 decimals
	case gWei = 9
    /// 12 decimals
	case microEther = 12
    /// 15 decimals
	case finney = 15
    /// Returns number of decimals (same as .rawValue)
	public var decimals: Int {
		return rawValue
	}
}

extension Web3Utils {
    /// Calculate address of deployed contract deterministically based on the address of the deploying Ethereum address
    /// and the nonce of this address
    public static func calcualteContractAddress(from: Address, nonce: BigUInt) -> Address? {
        guard let normalizedAddress = from.addressData.setLengthLeft(32) else { return nil }
        guard let data = RLP.encode([normalizedAddress, nonce] as [Any]) else { return nil }
        guard let contractAddressData = Web3Utils.sha3(data)?[12 ..< 32] else { return nil }
        // contractAddressData == 20 so we don't need to check for Address.isValid
        return Address(Data(contractAddressData))
    }

    /// Precoded "cold wallet" (private key controlled) address. Basically - only a payable fallback function.
    public static var coldWalletABI = """
    [{"payable":true,"type":"fallback"}]
    """

    /// Precoded ERC20 contracts ABI. Output parameters are named for ease of use.
    public static var erc20ABI = """
    [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"},{"name":"_extraData","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[{"name":"_initialAmount","type":"uint256"},{"name":"_tokenName","type":"string"},{"name":"_decimalUnits","type":"uint8"},{"name":"_tokenSymbol","type":"string"}],"type":"constructor"},{"payable":false,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"},]
    """
}

/// Errors from Web3Utils
public enum Web3UtilsError: Error {
    /// Cannot convert provided data to ascii string
    case cannotConvertDataToAscii
    /// Invalid signature length: Signature size should be 65 bytes
    case invalidSignatureLength
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case .cannotConvertDataToAscii:
            return "Cannot convert provided data to ascii string"
        case .invalidSignatureLength:
            return "Invalid signature length: Signature size should be 65 bytes"
        }
    }
}

/// Errors for function Web3Utils.publicToAddressData
public enum PublicKeyToAddressError: Error {
    /// Public key should start with 0x04
    case shouldStartWith4
    /// Public key must be 64 bytes long
    case invalidPublicKeySize
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case .shouldStartWith4:
            return "Public key should start with 0x04"
        case .invalidPublicKeySize:
            return "Public key must be 64 bytes long"
        }
    }
}

extension Web3Utils {
    /// Convert the private key (32 bytes of Data) to compressed (33 bytes) or non-compressed (65 bytes) public key.
    public static func privateToPublic(_ privateKey: Data, compressed: Bool = false) throws -> Data {
        return try SECP256K1.privateToPublic(privateKey: privateKey, compressed: compressed)
    }

    /// Convert a public key to the corresponding Address. Accepts public keys in compressed (33 bytes), non-compressed (65 bytes)
    /// or raw concat(X,Y) (64 bytes) format.
    ///
    /// Returns 20 bytes of address data.
    public static func publicToAddressData(_ publicKey: Data) throws -> Data {
        if publicKey.count == 33 {
            let decompressedKey = try SECP256K1.combineSerializedPublicKeys(keys: [publicKey], outputCompressed: false)
            return try publicToAddressData(decompressedKey)
        } else {
            var stipped = publicKey
            if stipped.count == 65 {
                guard stipped[0] == 4 else { throw PublicKeyToAddressError.shouldStartWith4 }
                stipped = stipped[1 ... 64]
            }
            guard stipped.count == 64 else { throw PublicKeyToAddressError.invalidPublicKeySize }
            let sha3 = stipped.keccak256()
            let addressData = sha3[12 ..< 32]
            return addressData
        }
    }

    /// Convert a public key to the corresponding Address. Accepts public keys in compressed (33 bytes), non-compressed (65 bytes)
    /// or raw concat(X,Y) (64 bytes) format.
    ///
    /// Returns the Address object.
    public static func publicToAddress(_ publicKey: Data) throws -> Address {
        let addressData = try Web3Utils.publicToAddressData(publicKey)
        let address = addressData.hex
        return Address(address)
    }

    /// Convert a public key to the corresponding Address. Accepts public keys in compressed (33 bytes), non-compressed (65 bytes)
    /// or raw concat(X,Y) (64 bytes) format.
    ///
    /// Returns a 0x prefixed hex string.
    public static func publicToAddressString(_ publicKey: Data) throws -> String {
        let addressData = try Web3Utils.publicToAddressData(publicKey)
        let address = addressData.hex.withHex.lowercased()
        return address
    }

    /// Converts address data (20 bytes) to the 0x prefixed hex string. Does not perform checksumming.
    public static func addressDataToString(_ addressData: Data) throws -> String {
        return Address(addressData)._address
    }

    /// Hashes a personal message by first padding it with the "\u{19}Ethereum Signed Message:\n" string and message length string.
    /// Should be used if some arbitrary information should be hashed and signed to prevent signing an Ethereum transaction
    /// by accident.
    /// throws Web3UtilsError.cannotConvertDataToAscii
    public static func hashPersonalMessage(_ personalMessage: Data) throws -> Data {
        var prefix = "\u{19}Ethereum Signed Message:\n"
        prefix += String(personalMessage.count)
        guard let prefixData = prefix.data(using: .ascii) else { throw Web3UtilsError.cannotConvertDataToAscii }
        var data = Data()
        if personalMessage.count >= prefixData.count && prefixData == personalMessage[0 ..< prefixData.count] {
            data.append(personalMessage)
        } else {
            data.append(prefixData)
            data.append(personalMessage)
        }
        return data.keccak256()
    }

    /// Parse a user-supplied string using the number of decimals for particular Ethereum unit.
    /// If input is non-numeric or precision is not sufficient - Returns nil.
    /// Allowed decimal separators are ".", ",".
    public static func parseToBigUInt(_ amount: String, units: Web3Units = .eth) -> BigUInt? {
        let unitDecimals = units.decimals
        return parseToBigUInt(amount, decimals: unitDecimals)
    }

    /// Parse a user-supplied string using the number of decimals.
    /// If input is non-numeric or precision is not sufficient - Returns nil.
    /// Allowed decimal separators are ".", ",".
    public static func parseToBigUInt(_ amount: String, decimals: Int = 18) -> BigUInt? {
        let separators = CharacterSet(charactersIn: ".,")
        let components = amount.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: separators)
        guard components.count == 1 || components.count == 2 else { return nil }
        let unitDecimals = decimals
        guard let beforeDecPoint = BigUInt(components[0], radix: 10) else { return nil }
        var mainPart = beforeDecPoint * BigUInt(10).power(unitDecimals)
        if components.count == 2 {
            let numDigits = components[1].count
            guard numDigits <= unitDecimals else { return nil }
            guard let afterDecPoint = BigUInt(components[1], radix: 10) else { return nil }
            let extraPart = afterDecPoint * BigUInt(10).power(unitDecimals - numDigits)
            mainPart = mainPart + extraPart
        }
        return mainPart
    }

    /// Recover the Ethereum address from recoverable secp256k1 signature. Message is first hashed using the "personal hash" protocol.
    /// BE WARNED - changing a message will result in different Ethereum address, but not in error.
    ///
    /// Input parameters should be hex Strings.
    public static func personalECRecover(_ personalMessage: String, signature: String) throws -> Address {
        return try Web3Utils.personalECRecover(personalMessage.dataFromHex(), signature: signature.dataFromHex())
    }

    /// Recover the Ethereum address from recoverable secp256k1 signature. Message is first hashed using the "personal hash" protocol.
    /// BE WARNED - changing a message will result in different Ethereum address, but not in error.
    ///
    /// Input parameters should be Data objects.
    public static func personalECRecover(_ personalMessage: Data, signature: Data) throws -> Address {
        guard signature.count == 65 else { throw Web3UtilsError.invalidSignatureLength }
        let hash = try Web3Utils.hashPersonalMessage(personalMessage)
        let publicKey = try SECP256K1.recoverPublicKey(hash: hash, signature: signature)
        return try Web3Utils.publicToAddress(publicKey)
    }

    /// Recover the Ethereum address from recoverable secp256k1 signature.
    /// Takes a hash of some message. What message is hashed should be checked by user separately.
    ///
    /// Input parameters should be Data objects.
    public static func hashECRecover(hash: Data, signature: Data) throws -> Address {
        try signature.checkSignatureSize()
        let rData = signature[0 ..< 32].bytes
        let sData = signature[32 ..< 64].bytes
        let vData = signature[64]
        let signatureData = try SECP256K1.marshalSignature(v: vData, r: rData, s: sData)
        let publicKey = try SECP256K1.recoverPublicKey(hash: hash, signature: signatureData)
        return try Web3Utils.publicToAddress(publicKey)
    }

    /// returns Ethereum variant of sha3 (keccak256) of data. Returns nil is data is empty
    public static func keccak256(_ data: Data) -> Data? {
        if data.count == 0 { return nil }
        return data.keccak256()
    }

    /// returns Ethereum variant of sha3 (keccak256) of data. Returns nil is data is empty
    public static func sha3(_ data: Data) -> Data? {
        if data.count == 0 { return nil }
        return data.keccak256()
    }

    /// returns sha256 of data. Returns nil is data is empty
    public static func sha256(_ data: Data) -> Data? {
        if data.count == 0 { return nil }
        return data.sha256()
    }

    /// Unmarshals a 65 byte recoverable EC signature into internal structure.
    static func unmarshalSignature(signatureData: Data) -> SECP256K1.UnmarshaledSignature? {
        if signatureData.count != 65 { return nil }
        let bytes = signatureData.bytes
        let r = Array(bytes[0 ..< 32])
        let s = Array(bytes[32 ..< 64])
        return SECP256K1.UnmarshaledSignature(v: bytes[64], r: r, s: s)
    }

    /// Marshals the V, R and S signature parameters into a 65 byte recoverable EC signature.
    static func marshalSignature(v: UInt8, r: [UInt8], s: [UInt8]) -> Data? {
        guard r.count == 32, s.count == 32 else { return nil }
        var completeSignature = Data(bytes: r)
        completeSignature.append(Data(bytes: s))
        completeSignature.append(Data(bytes: [v]))
        return completeSignature
    }

    /// Marshals internal signature structure into a 65 byte recoverable EC signature.
    static func marshalSignature(unmarshalledSignature: SECP256K1.UnmarshaledSignature) -> Data {
        var completeSignature = Data(bytes: unmarshalledSignature.r)
        completeSignature.append(Data(bytes: unmarshalledSignature.s))
        completeSignature.append(Data(bytes: [unmarshalledSignature.v]))
        return completeSignature
    }
}
