//
//  IBAN.swift
//  web3swift
//
//  Created by Alexander Vlasov on 25.05.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import Foundation

/**
 Interexchange Client Address Protocol, an IBAN-compatible system for referencing and transacting to client accounts aimed to streamline the process of transferring funds, worry-free between exchanges and, ultimately, making KYC and AML concerns a thing of the past.
 */
public struct ICAP {
    /// Asset
    public var asset: String
    /// Institution
    public var institution: String
    /// Client
    public var client: String
}

/// [International Bank Account Number](https://en.wikipedia.org/wiki/International_Bank_Account_Number)
public struct IBAN {
    /// Iban string
    public var iban: String

    /// Iban isDirect iban.count == 32 || iban.count == 35
    public var isDirect: Bool {
        return iban.count == 34 || iban.count == 35
    }

    /// Iban isIndirect iban.count == 2
    public var isIndirect: Bool {
        return iban.count == 20
    }
    
    /// Iban checksum iban[2..<2+2]
    public var checksum: String {
        return iban[2 ..< 4]
    }

    /// Iban asset iban[4..<4+3]
    public var asset: String {
        if isIndirect {
            return iban[4 ..< 7]
        } else {
            return ""
        }
    }
    
    /// IBan insitution iban(7..<7+4)
    public var institution: String {
        if isIndirect {
            return iban[7 ..< 11]
        } else {
            return ""
        }
    }

    /// Iban client
    public var client: String {
        if isIndirect {
            return iban[11...]
        } else {
            return ""
        }
    }
    
    /// Converts iban string to address
    public func toAddress() -> Address? {
        if isDirect {
            let base36 = iban[4...]
            guard let asBigNumber = BigUInt(base36, radix: 36) else { return nil }
            let addressString = String(asBigNumber, radix: 16).leftPadding(toLength: 40, withPad: "0")
            return Address(addressString.withHex)
        } else {
            return nil
        }
    }

    internal static func decodeToInts(_ iban: String) -> String {
//        let codePointForA = "A".asciiValue
//        let codePointForZ = "Z".asciiValue

        let uppercasedIBAN = iban.replacingOccurrences(of: " ", with: "").uppercased()
        let begining = String(uppercasedIBAN[0 ..< 4])
        let end = String(uppercasedIBAN[4...])
        let IBAN = end + begining
        var arrayOfInts = [Int]()
        for ch in IBAN {
            guard let dataPoint = String(ch).data(using: .ascii) else { return "" }
            guard dataPoint.count == 1 else { return "" }
            let code = Int(dataPoint[0])
            if code >= 65 && code <= 90 {
                arrayOfInts.append(code - 65 + 10)
            } else {
                arrayOfInts.append(code - 48)
            }
        }
        let joinedString = arrayOfInts.map({ (intCh) -> String in
            String(intCh)
        }).joined()
        return joinedString
    }

    internal static func calculateChecksumMod97(_ preparedString: String) -> Int {
        var m = 0
        for digit in preparedString.split(intoChunksOf: 1) {
            m = m * 10
            m = m + Int(digit)!
            m = m % 97
        }
        return m
    }

    /// Checks if string is iban address
    public static func isValidIBANaddress(_ iban: String, noValidityCheck: Bool = false) -> Bool {
        let regex = "^XE[0-9]{2}(ETH[0-9A-Z]{13}|[0-9A-Z]{30,31})$"
        let matcher = try! NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.dotMatchesLineSeparators)
        let match = matcher.matches(in: iban, options: NSRegularExpression.MatchingOptions.anchored, range: iban.fullNSRange)
        guard match.count == 1 else {
            return false
        }
        if iban.hasPrefix("XE") && !noValidityCheck {
            let remainder = calculateChecksumMod97(decodeToInts(iban))
            return remainder == 1
        } else {
            return true
        }
    }

    /**
    init with iban string
    - Parameter ibanString: iban string like
    - Returns: nil if invalid address is not convertible to iban
    To skip check for invalid address, just init it with Address.
     ```
     let iban = IBAN("XE7338O073KYGTWWZN0F2WZ0R8PX5ZPPZS")
     ```
    */
    public init?(_ ibanString: String) {
        let matched = ibanString.replacingOccurrences(of: " ", with: "").uppercased()
        guard IBAN.isValidIBANaddress(matched) else { return nil }
        iban = matched
    }
    /// Checks if address.base36.count <= 30
    public static func check(_ address: Address) -> Bool {
        return address.addressData.base36.count <= 30
    }
    /// Init with address
    /// - Important: [Not every address is IBAN compatible](https://github.com/BANKEX/web3swift/issues/137)
    public init(_ address: Address) {
        let padded = address.addressData.base36.leftPadding(toLength: 30, withPad: "0")
        let prefix = "XE"
        let remainder = IBAN.calculateChecksumMod97(IBAN.decodeToInts(prefix + "00" + padded))
        let checkDigits = "0" + String(98 - remainder)
        let twoDigits = checkDigits[checkDigits.count - 2 ..< checkDigits.count]
        let fullIban = prefix + twoDigits + padded
        iban = fullIban.uppercased()
    }
}

private extension Data {
    var base36: String {
        let bigNumber = BigUInt(self)
        return String(bigNumber, radix: 36)
    }
}
