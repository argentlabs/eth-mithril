//
//  Bridging.swift
//  web3swift
//
//  Created by Dmitry on 09/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation


// This protocol allows you to init objc class with its original swift class
public protocol SwiftContainer: SwiftBridgeable {
    init(_ swift: SwiftType)
}

public protocol SwiftBridgeable: SwiftBridgeableHack {
    associatedtype SwiftType
    var swift: SwiftType { get }
}

// This protocol allows you to get swift value as Any.
// Without this protocol .toSwift() function cannot convert Any to SwiftBridgeable
// because it contains associatedtype
public protocol SwiftBridgeableHack {
    var __swift: Any { get }
}
extension SwiftBridgeable {
    public var __swift: Any { return swift }
}
func toSwift(_ any: Any) -> Any {
    if let string = any as? String {
        return string
    } else if let objc = any as? SwiftBridgeableHack {
        return objc.__swift
    } else {
        return any
    }
}

extension Array where Element: Any {
    var swift: [Any] {
        return map(toSwift)
    }
}


//public extension _ObjectiveCBridgeable where _ObjectiveCType: SwiftBridgeable, _ObjectiveCType.SwiftType == Self {
//    static func _forceBridgeFromObjectiveC(_ source: _ObjectiveCType, result: inout Self?) {
//        result = source.swift
//    }
//
//    static func _conditionallyBridgeFromObjectiveC(_ source: _ObjectiveCType, result: inout Self?) -> Bool {
//        result = source.swift
//        return true
//    }
//
//    static func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectiveCType?) -> Self {
//        return source!.swift
//    }
//}

//extension _ObjectiveCBridgeable {
//    var objc: _ObjectiveCType {
//        return _bridgeToObjectiveC()
//    }
//}
