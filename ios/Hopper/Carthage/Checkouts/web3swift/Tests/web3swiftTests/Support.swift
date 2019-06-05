//
//  File.swift
//  web3swift
//
//  Created by Dmitry on 15/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension String {
    var data: Data {
        return Data(utf8)
    }
    func json<T: Decodable>(_ type: T.Type) throws -> T {
        return try JSONDecoder().decode(type, from: data)
    }
}
