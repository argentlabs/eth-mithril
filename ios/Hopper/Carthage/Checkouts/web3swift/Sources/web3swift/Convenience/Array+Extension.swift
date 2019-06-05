//
//  Array+Extension.swift
//  web3swift
//
//  Created by Alexander Vlasov on 15.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension Array {
    /// Splits array by chunks
    /// - Parameter chunkSize: Size of each subarray
    public func split(intoChunksOf chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: chunkSize).map {
            let endIndex = ($0.advanced(by: chunkSize) > self.count) ? self.count - $0 : chunkSize
            return Array(self[$0 ..< $0.advanced(by: endIndex)])
        }
    }
    func safe(_ index: Int) -> Element? {
        guard (0..<count).contains(index) else { return nil }
        return self[index]
    }
}

