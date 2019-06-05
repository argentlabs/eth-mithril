//
//  SolidityDataWriter.swift
//  web3swift
//
//  Created by Dmitry on 25/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt

private struct SolidityDataPointer {
    var data: Data
    var position: Int
    var arraySize: Int
}
private extension Data {
    mutating func write(data: Data, at position: Int) {
        replaceSubrange(position..<position+data.count, with: data)
    }
    mutating func extend(to size: Int) {
        if count > size {
            replaceSubrange(size..., with: Data())
        } else if count < size {
            append(Data(count: size-count))
        }
    }
    mutating func append(count: Int) {
        append(Data(count: count))
    }
    mutating func normalizeSize() {
        let expectedSize = (count-1) / 0x20 * 0x20 + 0x20
        guard count < expectedSize else { return }
        append(count: expectedSize - count)
    }
}
class SolidityDataWriter {
    private(set) var data: Data
    private var dynamicData = [SolidityDataPointer]()
    var offset = 0
    init() {
        self.data = Data()
    }
    init(data: Data) {
        self.data = data
    }
    init(count: Int) {
        data = Data(count: count)
    }
    func write(header: Data) {
        data.append(header)
        offset += header.count
    }
    func write(type: SolidityType) {
        var data = type.default
        data.extend(to: type.memoryUsage)
        if !type.isStatic {
            let arraySize = ceil(Double(data.count) / Double(type.memoryUsage))
            let pointer = SolidityDataPointer(data: data, position: self.data.count, arraySize: Int(arraySize))
            self.data.append(count: 32)
            dynamicData.append(pointer)
        } else {
            self.data.append(data)
        }
    }
    func write(value: SolidityDataRepresentable, type: SolidityType) {
        var data = value.solidityData
        if type.memoryUsage > 0 {
            data.extend(to: type.memoryUsage)
        }
        if !type.isStatic {
            let arraySize = value.isSolidityBinaryType ? data.count : data.count / 32
            data.normalizeSize()
            let pointer = SolidityDataPointer(data: data, position: self.data.count, arraySize: Int(arraySize))
            self.data.append(count: 32)
            dynamicData.append(pointer)
        } else {
            self.data.append(data)
        }
    }
    func setLength() {
        data.replaceSubrange(0..<0, with: length(data.count, offset: 0xc0))
    }
    
    private func length(_ l: Int, offset: Int) -> Data {
        func byte(_ value: Int) -> Data { return Data([UInt8(value)]) }
        guard l + offset > 0xf7 else { return byte(l+offset) }
        let serialized = BigUInt(l).serialize()
        return byte(0xf7+serialized.count) + serialized
    }
    
    func done() -> Data {
        guard !dynamicData.isEmpty else { return data }
        for pointer in dynamicData {
            data.write(data: (data.count - offset).solidityData, at: pointer.position)
            if pointer.data.count == 0 {
                data.append(0.solidityData)
            } else {
                data.append(pointer.arraySize.solidityData)
                data.append(pointer.data)
            }
        }
        dynamicData.removeAll()
        return data
    }
}
