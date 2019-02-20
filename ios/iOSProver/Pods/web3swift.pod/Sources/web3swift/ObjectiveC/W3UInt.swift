//
//  W3UInt.swift
//  web3swift
//
//  Created by Dmitry on 11/8/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

//typealias BigUInt = web3swift.BigUInt

extension NSNumber {
	@objc public var bn: W3UInt {
		return W3UInt(value: self)
	}
}
extension BigUInt {
    public var objc: W3UInt {
		return W3UInt(value: self)
	}
}

@objc public class W3UInt: NSObject, SwiftBridgeable {
	public var swift: BigUInt {
		return value
	}
	let value: BigUInt
	init(value: BigUInt) {
		self.value = value
	}
	@objc public init(value: NSNumber) {
		self.value = BigUInt(value.uint64Value)
	}
	@objc public init(string: String, andRadix: NSNumber = 10) {
		self.value = BigUInt(string, radix: andRadix.intValue) ?? 0
	}
	
	@objc public func add(_ number: W3UInt) -> W3UInt {
		return (value + number.value).objc
	}
	@objc public func subtract(_ number: W3UInt) -> W3UInt {
		return (value - number.value).objc
	}
	@objc public func multiply(_ number: W3UInt) -> W3UInt {
		return (value * number.value).objc
	}
	@objc public func divide(_ number: W3UInt) -> W3UInt {
		return (value / number.value).objc
	}
	@objc public func remainder(_ number: W3UInt) -> W3UInt {
		return (value % number.value).objc
	}
	
	@objc public func pow(_ number: W3UInt) -> W3UInt {
		return value.power(Int(number.value)).objc
	}
	@objc public func pow(_ exponent: W3UInt, mod: W3UInt) -> W3UInt {
		return value.power(exponent.value, modulus: mod.value).objc
	}
//	@objc public func abs() -> W3UInt {
//
//	}
//	@objc public func negate() -> W3UInt {
//
//	}
	
	@objc public func bitwiseXor(_ number: W3UInt) -> W3UInt {
		return (value ^ number.value).objc
	}
	@objc public func bitwiseOr(_ number: W3UInt) -> W3UInt {
		return (value | number.value).objc
	}
	@objc public func bitwiseAnd(_ number: W3UInt) -> W3UInt {
		return (value & number.value).objc
	}
	@objc public func shiftLeft(_ number: W3UInt) -> W3UInt {
		return (value << number.value).objc
	}
	@objc public func shiftRight(_ number: W3UInt) -> W3UInt {
		return (value >> number.value).objc
	}
	
	@objc public func compare(_ number: W3UInt) -> ComparisonResult {
		if value < number.value {
			return .orderedAscending
		} else if value == number.value {
			return .orderedSame
		} else {
			return .orderedDescending
		}
	}
	
	@objc public var stringValue: String {
		return value.description
	}
	
	@objc public func stringValue(radix: Int) -> String {
		return String(value, radix: radix)
	}
	
	
	@objc public init?(_ string: String, units: W3Units) {
		guard let value = BigUInt(string, units: units.swift) else { return nil }
		self.value = value
	}
	
	@objc public init?(_ string: String, decimals: Int) {
		guard let value = BigUInt(string, decimals: decimals) else { return nil }
		self.value = value
	}
	
	
	/// Formats a BigUInt object to String. The supplied number is first divided into integer and decimal part based on "toUnits",
	/// then limit the decimal part to "decimals" symbols and uses a "decimalSeparator" as a separator.
	/// default: decimals: 18, decimalSeparator: ".", options: .stripZeroes
	@objc public func string(units: W3Units, decimals: Int = 18, decimalSeparator: String = ".", options: W3StringOptions = .default) -> String {
		return value.string(units: units.swift, decimals: decimals, decimalSeparator: decimalSeparator, options: options.swift)
	}
	
	/// Formats a BigUInt object to String. The supplied number is first divided into integer and decimal part based on "toUnits",
	/// then limit the decimal part to "decimals" symbols and uses a "decimalSeparator" as a separator.
	/// Fallbacks to scientific format if higher precision is required.
	/// default: decimals: 18, decimalSeparator: ".", options: .stripZeroes
	@objc public func string(unitDecimals: Int, decimals: Int = 18, decimalSeparator: String = ".", options: W3StringOptions = .default) -> String {
		return value.string(unitDecimals: unitDecimals, decimals: decimals, decimalSeparator: decimalSeparator, options: options.swift)
	}
    
    public override var description: String {
        return swift.description
    }
}

extension BigInt {
    public var objc: W3Int {
		return W3Int(value: self)
	}
}
@objc public class W3Int: NSObject, SwiftBridgeable {
    public var swift: BigInt {
        return value
    }
	let value: BigInt
	init(value: BigInt) {
		self.value = value
	}
	@objc public init(value: NSNumber) {
		self.value = BigInt(value.uint64Value)
	}
	@objc public init(string: String, andRadix: NSNumber = 10) {
		self.value = BigInt(string, radix: andRadix.intValue) ?? 0
	}
	
	@objc public func add(_ number: W3Int) -> W3Int {
		return (value + number.value).objc
	}
	@objc public func subtract(_ number: W3Int) -> W3Int {
		return (value - number.value).objc
	}
	@objc public func multiply(_ number: W3Int) -> W3Int {
		return (value * number.value).objc
	}
	@objc public func divide(_ number: W3Int) -> W3Int {
		return (value / number.value).objc
	}
	@objc public func remainder(_ number: W3Int) -> W3Int {
		return (value % number.value).objc
	}
	
	@objc public func pow(_ number: W3Int) -> W3Int {
		return value.power(Int(number.value)).objc
	}
	@objc public func pow(_ exponent: W3Int, mod: W3Int) -> W3Int {
		return value.power(exponent.value, modulus: mod.value).objc
	}
	@objc public func abs() -> W3Int {
		return Swift.abs(value).objc
	}
	@objc public func negate() -> W3Int {
		var value = self.value
		value.negate()
		return value.objc
	}
	
	@objc public func bitwiseXor(_ number: W3Int) -> W3Int {
		return (value ^ number.value).objc
	}
	@objc public func bitwiseOr(_ number: W3Int) -> W3Int {
		return (value | number.value).objc
	}
	@objc public func bitwiseAnd(_ number: W3Int) -> W3Int {
		return (value & number.value).objc
	}
	@objc public func shiftLeft(_ number: W3Int) -> W3Int {
		return (value << number.value).objc
	}
	@objc public func shiftRight(_ number: W3Int) -> W3Int {
		return (value >> number.value).objc
	}
	
	@objc public func compare(_ number: W3Int) -> ComparisonResult {
		if value < number.value {
			return .orderedAscending
		} else if value == number.value {
			return .orderedSame
		} else {
			return .orderedDescending
		}
	}
	
	@objc public var stringValue: String {
		return value.description
	}
	
	@objc public func stringValue(radix: Int) -> String {
		return String(value, radix: radix)
	}
	
	@objc public func string(unitDecimals: Int, decimals: Int = 18, decimalSeparator: String = ".", options: W3StringOptions = .default) -> String {
		return value.string(unitDecimals: unitDecimals, decimals: decimals, decimalSeparator: decimalSeparator, options: options.swift)
	}
	
	/// Formats a BigInt object to String. The supplied number is first divided into integer and decimal part based on "units",
	/// then limit the decimal part to "decimals" symbols and uses a "decimalSeparator" as a separator.
	/// default: decimals: 18, decimalSeparator: ".", options: .stripZeroes
	@objc public func string(units: W3Units, decimals: Int = 18, decimalSeparator: String = ".", options: W3StringOptions = .default) -> String {
		return value.string(units: units.swift, decimals: decimals, decimalSeparator: decimalSeparator, options: options.swift)
	}
    
    public override var description: String {
        return swift.description
    }
}

extension Web3Units {
    public var objc: W3Units {
		return W3Units(rawValue: rawValue)!
	}
}
@objc public enum W3Units: Int, SwiftBridgeable {
    case eth = 18
    case wei = 0
    case Kwei = 3
    case Mwei = 6
    case Gwei = 9
    case Microether = 12
    case Finney = 15
    public var swift: Web3Units {
        return Web3Units(rawValue: rawValue)!
    }
}

@objc public class W3StringOptions: NSObject, OptionSet {
	@objc public let rawValue: Int
	@objc public required init(rawValue: Int) {
		self.rawValue = rawValue
	}
	@objc public static let fallbackToScientific = W3StringOptions(rawValue: 0b1)
	@objc public static let stripZeroes = W3StringOptions(rawValue: 0b10)
	@objc public static let `default`: W3StringOptions = [.stripZeroes]
	public var swift: BigUInt.StringOptions {
		return BigUInt.StringOptions(rawValue: rawValue)
	}
}


@objc public class W3NaturalUnits: NSObject {
	public var swift: NaturalUnits
	@objc public init(string: String) throws {
		swift = try NaturalUnits(string)
	}
	@objc public init(_ int: Int) {
		swift = NaturalUnits(int)
	}
	public func number(with decimals: Int) -> W3UInt {
		return swift.number(with: decimals).objc
	}
}
