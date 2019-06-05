//
//  SolidityDataReader.swift
//  web3swift
//
//  Created by Dmitry on 11/21/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

private extension Int {
	var solidityFormatted: Int {
		return (self / 32 + 1) * 32
	}
}

/// SolidityDataReader errors
public enum SolidityDataReaderError: Error {
    /// Element not found
	case notFound
    /// Cannot get excepted type
	case wrongType
    /// Not enough data
	case overflows
    
    /// Printable / user displayable description
    public var localizedDescription: String {
        switch self {
        case .notFound:
            return "Smart Contract response error: Element not found"
        case .wrongType:
            return "Smart Contract response error: Cannot get excepted type"
        case .overflows:
            return "Smart Contract response error: Not enough data"
        }
    }
}

/// Solidity data reader
public class SolidityDataReader {
    /// Data
	public let data: Data
    /// Current position in data
	public var position = 0
    /// Header size (in general contains function hash)
    /// Need to ignore header data for array pointers
	public var headerSize = 0
    
    /// Inits with data
	public init(_ data: Data) {
		self.data = data
	}
    
    /// Returns next 32 bytes as BigUInt
	public func uint256() throws -> BigUInt {
		return try BigUInt(next(32))
	}
    /// Skips 12 bytes and returns next 32 bytes as Address
	public func address() throws -> Address {
		try skip(12)
		return try Address(next(20))
	}
    /// Returns next 32 bytes as Bool
	public func bool() throws -> Bool {
		let value = try BigUInt(next(32))
		guard value < 2 else { throw SolidityDataReaderError.wrongType }
		return value == 1
	}
    /// - Returns next 32 bytes as String
    /// - Ignores zeroes
	public func string32() throws -> String {
		var data = try next(32)
		let index = data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Int? in
			for i in 0..<data.count where pointer[i] == 0 {
				return i
			}
			return nil
		}
		if let index = index {
			data = data[0..<index]
		}
		guard let string = String(data: data, encoding: .utf8) else { throw SolidityDataReaderError.wrongType }
		return string
	}
    
    /// - Gets 32 bytes as string pointer
    /// - If pointer == 0 -> Returns 0
    /// - If pointer < Int.max -> tries to get string from pointer, then tries to get string from string32
    /// - If pointer > Int.max -> Returns string32
	public func string() throws -> String {
		let pointer = try view { try uint256() }
		if pointer == 0 {
			// we already checked next 32 bytes so this shouldn't crash
			try! skip(32)
			return ""
		} else if pointer < Int.max {
            if let string = view(block: { try? stringPointer() }) {
                try! skip(32)
                return string
            } else {
                return try string32()
            }
		} else {
			return try string32()
		}
	}
    
    /// - Gets next 32 bytes as pointer for string position.
    /// - Moves to that pointer.
    /// - Gets next 32 bytes as string size
    /// - Gets string size / 32 bytes and returns them as String
	public func stringPointer() throws -> String {
		return try pointer {
			let length = try intCount()
			guard length > 0 else { return "" }
			let data = try self.next(length)
			guard let string = String(data: data, encoding: .utf8) else { throw SolidityDataReaderError.wrongType }
			return string
		}
	}
    
    /// - Gets next 32 bytes as pointer
    /// - Moves to that pointer.
    /// - Returns next 32 bytes
    public func bytes() throws -> Data {
        return try pointer {
            let length = try intCount()
            guard length > 0 else { return Data() }
            return try next(length)
        }
    }
    
    public func bytes32() throws -> Data {
        return try next(32)
    }
    
    /// - Moves to pointer
    /// - Gets number of elements
    /// - Calls builder(self) (number of elements) times
    /// - Returns array
	public func array<T>(builder: (SolidityDataReader)throws->(T)) throws -> [T] {
		return try pointer {
			let count = try intCount()
			var array = [T]()
			array.reserveCapacity(count)
			for _ in 0..<count {
				try array.append(builder(self))
			}
			return array
		}
	}
	
    /// Returns data header and sets header size
	public func header(_ size: Int) throws -> Data {
		let range = position..<position+size
		guard range.upperBound <= data.count else { throw SolidityDataReaderError.notFound }
		position = range.upperBound
		headerSize = size
		return self.data[range]
	}
    
    /// Moves position by (count) bytes
	public func skip(_ count: Int) throws {
		let end = position+count
		guard end <= data.count else { throw SolidityDataReaderError.notFound }
		position = end
	}
    
    /// Returns next data with size.
    /// Position changes
	public func next(_ size: Int) throws -> Data {
		let range = position..<position+size
		guard range.upperBound <= data.count else { throw SolidityDataReaderError.notFound }
		position = range.upperBound
		return self.data[range]
	}
    
    /// Moves position to the pointer, calls block() from it and changes the position back
	public func pointer<T>(at: Int, block: ()throws->T) throws -> T {
		let pos = position
		position = at + headerSize
		defer { position = pos }
		return try block()
	}
    
    /// Gets next 32 bytes as pointer. Moves position to the pointer, calls block() from it and changes the position back
	public func pointer<T>(block: ()throws->T) throws -> T {
		let pointer = try intCount()
		let pos = position
		position = pointer + headerSize
		defer { position = pos }
		return try block()
	}
    /// Used if you want to check next bytes. Without losing the position
    /// Saves current position. Call function block. Then restores saved position.
	public func view<T>(block: ()throws->T) rethrows -> T {
		let pos = position
		defer { position = pos }
		return try block()
	}
}
public extension SolidityDataReader {
	private func unsigned<T: BinaryInteger>(max: BigUInt) throws -> T {
		let number = try uint256()
		guard number <= max else { throw SolidityDataReaderError.overflows }
		return T(number)
	}
	private func signed<T: BinaryInteger>(min: BigInt, max: BigInt) throws -> T {
		let number = try uint256()
		guard number >= min && number <= max else { throw SolidityDataReaderError.overflows }
		return T(number)
	}
    
    /// - Returns: next 32 bytes as UInt8
	func uint8() throws -> UInt8 {
		return try unsigned(max: 0xff)
	}
    /// - Returns: next 32 bytes as UInt16
	func uint16() throws -> UInt16 {
		return try unsigned(max: 0xffff)
	}
    /// - Returns: next 32 bytes as UInt32
	func uint32() throws -> UInt32 {
		return try unsigned(max: 0xffffffff)
	}
    /// - Returns: next 32 bytes as UInt64
	func uint64() throws -> UInt64 {
		return try unsigned(max: 0xffffffffffffffff)
	}
    /// - Returns: next 32 bytes as UInt64
	func uint() throws -> UInt {
		return try unsigned(max: BigUInt(UInt.max))
	}
    /// - Returns: next 32 bytes as Int8
	func int8() throws -> Int8 {
		return try signed(min: -0x80, max: 0x7f)
	}
    /// - Returns: next 32 bytes as Int16
	func int16() throws -> Int16 {
		return try signed(min: -0x8000, max: 0x7fff)
	}
    /// - Returns: next 32 bytes as Int32
	func int32() throws -> Int32 {
		return try signed(min: -0x80000000, max: 0x7fffffff)
	}
    /// - Returns: next 32 bytes as Int64
	func int64() throws -> Int64 {
		return try signed(min: -0x8000000000000000, max: 0x7fffffffffffffff)
	}
    /// - Returns: next 32 bytes as Int
	func int() throws -> Int {
		return try signed(min: BigInt(Int.min), max: BigInt(Int.max))
	}
    /// - Returns: next 32 bytes as Int and checks if int is >= 0
	func intCount() throws -> Int {
		return try signed(min: 0, max: BigInt(Int.max))
	}
}
