//
//  BIP39.swift
//  web3swift
//
//  Created by Alexander Vlasov on 11.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

//import Cryptor
import Foundation

/// Mnemonics language
public enum BIP39Language: String {
    /// English word list
    case english
    /// Chinese simplified word list
    case chinese_simplified
    /// Chinese traditional word list
    case chinese_traditional
    /// Japanese word list
    case japanese
    /// Korean word list
    case korean
    /// French word list
    case french
    /// Italian word list
    case italian
    /// Spanish word list
    case spanish
    
    /// Array of words in the language
    public var words: [String] {
        switch self {
        case .english:
            return englishWords
        case .chinese_simplified:
            return simplifiedchineseWords
        case .chinese_traditional:
            return traditionalchineseWords
        case .japanese:
            return japaneseWords
        case .korean:
            return koreanWords
        case .french:
            return frenchWords
        case .italian:
            return italianWords
        case .spanish:
            return spanishWords
        }
    }

    /// Word separator ("\u{3000}") for japanese and " " for anyone else
    public var separator: String {
        switch self {
        case .japanese:
            return "\u{3000}"
        default:
            return " "
        }
    }
}

/// Mnemonics entropy size
public enum EntropySize: Int {
    /// 128 bit entropy
    case b128 = 128
    /// 160 bit entropy
    case b160 = 160
    /// 192 bit entropy
    case b192 = 192
    /// 224 bit entropy
    case b224 = 224
    /// 256 bit entropy
    case b256 = 256
}

/** Mnemonics class. Used to generate/create/import ethereum account
 
 To generate mnemonics use:
 ```
 let mnemonics = Mnemonics()
 print(mnemonics)
 ```
 
 To import mnemonics:
 ```
 let string = "normal dune pole key case cradle unfold require tornado mercy hospital buyer"
 let mnemonics = try Mnemonics(string)
 print(mnemonics)
 ```
 
 To get private key from mnemonics:
 ```
 let mnemonics = Mnemonics()
 let keystore = try BIP32Keystore(mnemonics: mnemonics)
 let address = keystore.addresses[0]
 let privateKey = try keystore.UNSAFE_getPrivateKeyData(password: "", account: address)
 let publicKey = try Web3Utils.privateToPublic(privateKey, compressed: true)
 ```
 In the most cases you don't need to manage your public and private keys. web3swift doing this for you.
 */
public class Mnemonics {
    /// Mnemonics init with data error
    public enum Error: Swift.Error {
        /// Invalid entropy size. Entropy size should be at least 16 bytes long and a multiple of four
        case invalidEntropySize
        /// Printable / user displayable description
        public var localizedDescription: String {
            return "Invalid entropy size. Entropy size should be greater than 15 and a multiple of four"
        }
    }
    /// Mnemonics init with string error
    public enum EntropyError: Swift.Error {
        /// Not enough words. Your mnemonics should have at least 12 words
        case notEnoughtWords
        /// Invalid number of words. It is necessary that the number of words be a multiple of four
        case invalidNumberOfWords
        /// Cannot find word \"\(string)\" in our dictionary
        case wordNotFound(String)
        /// Invalid words order
        case invalidOrderOfWords
        /// Checksum failed checksum: \(string1). expected: \(string2)
        case checksumFailed(String,String)
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case .notEnoughtWords:
                return "Not enough words. Your mnemonics should have at least 12 words"
            case .invalidNumberOfWords:
                return "Invalid number of words. It is necessary that the number of words be a multiple of four"
            case let .wordNotFound(string):
                return "Cannot find word \"\(string)\" in our dictionary"
            case .invalidOrderOfWords:
                return "Invalid words order"
            case let .checksumFailed(string1,string2):
                return "Checksum failed checksum: \(string1). expected: \(string2)"
            }
        }
    }
    /// Mnemonics string
    public let string: String
    
    /// Language. default: .english
    public let language: BIP39Language
    
    /// Entropy data
    public var entropy: Data
    
    /**
     Mnemonics password
     - Important: Mnemonics password affects on privateKey generation
     - Important: WARNING: User cannot use mnemonics generated with password in metamask or some other services that doesn't support mnemonics password
     - Important: With different password you will generate different address
     */
    public var password: String = ""
    
    /// Generate seed from mnemonics string. This function will ignore dictionary and won't check for mnemonics error
    public static func seed(from mnemonics: String, password: String) -> Data {
        let salt = "mnemonic" + password
        let saltData = Array(salt.decomposedStringWithCompatibilityMapping.utf8)
        
        // PKCS5.PBKDF2 throws only if mnemData.isEmpty
        // or keyLength > variant.digestLength * 256
        // and .calculate() won't throw any errors
        // so i feel free to use "try!"
        let seed = try! PBKDF.deriveKey(fromPassword: mnemonics.decomposedStringWithCompatibilityMapping, salt: saltData, prf: .sha512, rounds: 2048, derivedKeyLength: 64)
        return Data(bytes: seed)
    }
    
    /**
     Init with imported mnemonics string and specific language
     - Throws: An error of type Mnemonics.EntropyError
     - Parameter string: Mnemonics string
     - Parameter language: Mnemonics language. default: .english
     
     Requirements:
     1. Minimum 12 words
     2. Words.count % 4 == 0
     3. Every word must be in [our dictionary](https://github.com/bitcoin/bips/blob/master/bip-0039/bip-0039-wordlists.md)
     4. Words must be in valid order
     5. Checksum bits should match (should never throw on that)
     
     */
    public init(_ string: String, language: BIP39Language = .english) throws {
        // checking entropy
        let wordList = string.components(separatedBy: " ")
        guard wordList.count >= 12 else { throw EntropyError.notEnoughtWords }
        guard wordList.count % 4 == 0 else { throw EntropyError.invalidNumberOfWords }

        var bitString = ""
        for word in wordList {
            guard let idx = language.words.index(of: word) else { throw EntropyError.wordNotFound(word) }
            let idxAsInt = language.words.startIndex.distance(to: idx)
            let stringForm = String(UInt16(idxAsInt), radix: 2).leftPadding(toLength: 11, withPad: "0")
            bitString.append(stringForm)
        }
        let stringCount = bitString.count
        guard stringCount % 33 == 0 else { throw EntropyError.invalidOrderOfWords }
        let position = (bitString.count - bitString.count / 33)
        let entropyBits = bitString[0..<position]
        let checksumBits = bitString[position..<bitString.count]
        let entropy = entropyBits.interpretAsBinaryData()
        let checksum = String(entropy.sha256().bitsInRange(0, checksumBits.count), radix: 2).leftPadding(toLength: checksumBits.count, withPad: "0")
        guard checksum == checksumBits else { throw EntropyError.checksumFailed(checksum, checksumBits) }
        self.string = string
        self.language = language
        self.entropy = entropy
    }
    
    /**
     Generate mnemonics with entropy size and language
     - Parameter entropySize: Mnemonics seed size. default: .b256
     - Parameter language: Mnemonics dictionary language. default: .english
     */
    public init(entropySize: EntropySize = .b256, language: BIP39Language = .english) {
        self.entropy = Data.random(length: entropySize.rawValue / 8)
        let checksum = entropy.sha256()
        let checksumBits = entropy.count * 8 / 32
        var fullEntropy = Data()
        fullEntropy.append(entropy)
        fullEntropy.append(checksum[0 ..< (checksumBits + 7) / 8])
        let separator = language.separator
        let words = language.words
        var indexes = [Int]()
        for i in 0 ..< fullEntropy.count * 8 / 11 {
            let bits = fullEntropy.bitsInRange(i * 11, 11)
            let index = Int(bits)
            indexes.append(index)
        }
        self.string = indexes.map { words[$0] }.joined(separator: separator)
        self.language = language
    }
    
    /**
     Generate mnemonics with pregenerated entropy data
     - Parameter entropy: Seed which generates mnemonics string
     - Parameter language: Mnemonics dictionary language. default: .english
     - Throws: Error.invalidEntropySize if entropy data has invalid size (< 16 || % 4 != 0)
     */
    public init(entropy: Data, language: BIP39Language = .english) throws {
        guard entropy.count >= 16, entropy.count % 4 == 0 else { throw Error.invalidEntropySize }
        let checksum = entropy.sha256()
        let checksumBits = entropy.count * 8 / 32
        var fullEntropy = Data()
        fullEntropy.append(entropy)
        fullEntropy.append(checksum[0 ..< (checksumBits + 7) / 8])
        var wordList = [String]()
        for i in 0 ..< fullEntropy.count * 8 / 11 {
            let bits = fullEntropy.bitsInRange(i * 11, 11)
            let index = Int(bits)
            let word = language.words[index]
            wordList.append(word)
        }
        let separator = language.separator
        self.entropy = entropy
        self.string = wordList.joined(separator: separator)
        self.language = language
    }
    
    /// - Returns: Seed from mnemonics
    public func seed() -> Data {
        return Mnemonics.seed(from: string, password: password)
    }
}

extension Mnemonics: CustomStringConvertible {
    /**
     Mnemonics description
     - Returns: .string
     */
    public var description: String {
        return string
    }
}

