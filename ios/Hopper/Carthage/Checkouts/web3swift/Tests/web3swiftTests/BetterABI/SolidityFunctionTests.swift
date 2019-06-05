//
//  SolidityFunctionTests.swift
//  web3swift-iOS_Tests
//
//  Created by Dmitry on 25/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import XCTest
import BigInt
@testable import web3swift

private func scan(type: String) throws -> SolidityType {
    return try SolidityType.scan(type: type)
}

class SolidityFunctionTests: XCTestCase {
    func testTypes() {
        try XCTAssertNoThrow(scan(type: "uint256"))
        try XCTAssertNoThrow(scan(type: "uint256"))
        try XCTAssertNoThrow(scan(type: "uint128"))
        try XCTAssertNoThrow(scan(type: "uint64"))
        try XCTAssertNoThrow(scan(type: "uint32"))
        try XCTAssertNoThrow(scan(type: "uint16"))
        try XCTAssertNoThrow(scan(type: "uint8"))
        try XCTAssertNoThrow(scan(type: "uint"))
        try XCTAssertThrowsError(scan(type: "uint0"))
        try XCTAssertThrowsError(scan(type: "uint1"))
        try XCTAssertThrowsError(scan(type: "uint257"))
        try XCTAssertThrowsError(scan(type: "uint512"))
        
        try XCTAssertNoThrow(scan(type: "int256"))
        try XCTAssertNoThrow(scan(type: "int128"))
        try XCTAssertNoThrow(scan(type: "int64"))
        try XCTAssertNoThrow(scan(type: "int32"))
        try XCTAssertNoThrow(scan(type: "int16"))
        try XCTAssertNoThrow(scan(type: "int8"))
        try XCTAssertNoThrow(scan(type: "int"))
        try XCTAssertThrowsError(scan(type: "int0"))
        try XCTAssertThrowsError(scan(type: "int1"))
        try XCTAssertThrowsError(scan(type: "int257"))
        try XCTAssertThrowsError(scan(type: "int512"))
        
        // array
        try XCTAssertNoThrow(scan(type: "uint256[]"))
        try XCTAssertNoThrow(scan(type: "uint256[1]"))
        try XCTAssertNoThrow(scan(type: "uint256[32]"))
        try XCTAssertNoThrow(scan(type: "uint256[33]"))
        try XCTAssertThrowsError(scan(type: "uint256]"))
        try XCTAssertThrowsError(scan(type: "uint256["))
        try XCTAssertThrowsError(scan(type: "uint256[0]"))
        
        
        try XCTAssertNoThrow(scan(type: "function"))
        try XCTAssertNoThrow(scan(type: "address"))
        try XCTAssertNoThrow(scan(type: "bool"))
        try XCTAssertNoThrow(scan(type: "string"))
        try XCTAssertThrowsError(scan(type: "aksjdjalksd"))
        try XCTAssertThrowsError(scan(type: ""))
        try XCTAssertThrowsError(scan(type: "tuple("))
        
        try XCTAssertNoThrow(scan(type: "bytes"))
        try XCTAssertNoThrow(scan(type: "bytes1"))
        try XCTAssertNoThrow(scan(type: "bytes32"))
        try XCTAssertThrowsError(scan(type: "bytes33"))
        try XCTAssertThrowsError(scan(type: "bytes["))
        try XCTAssertThrowsError(scan(type: "bytes]"))
        try XCTAssertThrowsError(scan(type: "bytes[0]"))
        try XCTAssertThrowsError(scan(type: "bytes[33]"))
        
        try XCTAssertNoThrow(scan(type: "tuple(uint256)"))
        try XCTAssertNoThrow(scan(type: "tuple(uint256,uint256)"))
        try XCTAssertNoThrow(scan(type: "tuple(address,string)"))
        try XCTAssertNoThrow(scan(type: "tuple(uint256,address,address,bytes32,uint256[64])"))
        try XCTAssertThrowsError(scan(type: "uint256(uint256,address,tuple(address,bytes32,uint256[64]))"))
        try XCTAssertThrowsError(scan(type: "string(uint256,address,tuple(address,bytes32,uint256[64]))"))
        
        try XCTAssertThrowsError(scan(type: "tuple(tuple))"))
    }
    
    func testAliases() throws {
        let function1 = try SolidityFunction(function: "transfer(address,uint256)")
        let function2 = try SolidityFunction(function: "transfer(address,uint)")
        XCTAssertEqual(function1.hash, function2.hash)
        XCTAssertEqual(function2.function, "transfer(address,uint256)")
    }
    
    func testEncodeAndDecode() throws {
        let user: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
        let function = try SolidityFunction(function: "transfer(address,uint256)")
        let data = function.encode(user, 800)
        
        let reader = SolidityDataReader(data)
        let hash = try reader.header(4)
        let a = try reader.address()
        let b = try reader.uint256()
        XCTAssertEqual(hash, "a9059cbb".hex)
        XCTAssertEqual(a, user)
        XCTAssertEqual(b, 800)
    }
    
    func pr(_ value: BigInt) {
        print(value.solidityData.hex, value)
    }
    
    func testEncodeAndDecodeString() throws {
        let user: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
        
        let function = try SolidityFunction(function: "send(address,string,uint256)")
        let data = function.encode(user, "hello world", 800)
        
        let reader = SolidityDataReader(data)
        let hash = try reader.header(4)
        let a = try reader.address()
        let message = try reader.string()
        let b = try reader.uint256()
        XCTAssertEqual(hash, function.hash)
        XCTAssertEqual(a, user)
        XCTAssertEqual(message, "hello world")
        XCTAssertEqual(b, 800)
    }
    
    
    func testEncodeAndDecodeBigString() throws {
        let user: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
        let bigString = "mfiejrh9183yrnv190y3r0m9x17yc90172ymr093 daosjdokamsfl vopadsjnfmowedfoiwlfknlkvkdmf omfp qejfpiqwejfop[w mfewfm qmef fe"
        
        let function = try SolidityFunction(function: "  send  (  address, string ,uint256 ) ")
        let data = function.encode(user, bigString, 800)
        
        let reader = SolidityDataReader(data)
        let hash = try reader.header(4)
        let a = try reader.address()
        let message = try reader.string()
        let b = try reader.uint256()
        XCTAssertEqual(hash, function.hash)
        XCTAssertEqual(a, user)
        XCTAssertEqual(message, bigString)
        XCTAssertEqual(b, 800)
    }
    
    func testEncode() throws {
        let function = try SolidityFunction(function: "send(uint256,uint256[],string)")
        let data = function.encode(150000,[65535,8191],"abc")
        XCTAssertEqual(data.hex, "602c15e100000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000ffff0000000000000000000000000000000000000000000000000000000000001fff00000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000")
    }
}
