//
//  HDPath.swift
//  web3swift
//
//  Created by Dmitry on 29/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

/// Can be used to check if HDPath is valid
public class HDPath: ExpressibleByStringLiteral {
    /// m/44'/60'/0'/0
    public static var `default`: HDPath = "m/44'/60'/0'/0"
    /// m/44'/60'/0'
    public static var defaultPrefix: HDPath = "m/44'/60'/0'"
    /// m/44'/60'/0'/0/
    public static var metamask: HDPath = "m/44'/60'/0'/0/0"
    /// m/44'/60'/0'/0
    public static var metamaskPrefix: HDPath = "m/44'/60'/0'/0"
    /// 1 << 31
    public static var hardenedIndexPrefix: UInt32 = (UInt32(1) << 31)
    
    /// Path error
    public enum Error: Swift.Error {
        /// Invalid hdpath
        case invalidHDPath(String)
        /// Printable / user displayable description
        public var localizedDescription: String {
            switch self {
            case let .invalidHDPath(path):
                return "Invalid hdpath: \(path)"
            }
        }
    }
    
    /// Path component
    public struct Component: CustomStringConvertible {
        /// Path index
        public var index: UInt32
        /// Is index hardened
        public var isHardened: Bool
        /// String representation of the component
        public var description: String {
            return isHardened ? "\(index)'" : "\(index)"
        }
    }
    
    /// Path starts with m/
    public var m: Bool
    /// Array of indexes
    public private(set) var components: [Component]
    /// Parent path
    public var parent: HDPath?
    
    public typealias StringLiteralType = String
    /// Unsafe init with string. this one will crash if something goes wrong
    public required init(stringLiteral value: StringLiteralType) {
        (m,components) = try! HDPath.parse(value)
    }
    
    /// Init with path string
    public init(path: String) throws {
        (m,components) = try HDPath.parse(path)
    }
    
    /// Init with empty path. m = false
    public init() {
        m = false
        components = []
    }
    
    /// Init with m and components
    public init(m: Bool = true, components: [Component]) {
        self.m = m
        self.components = components
    }
    
    /// Appends index to current path
    public func append(index: UInt32, hardened: Bool) {
        let index = hardened ? index % HDPath.hardenedIndexPrefix : index
        self.components.append(Component(index: index, isHardened: hardened))
    }
    /// Returns child path with new index
    public func appending(index: UInt32, hardened: Bool) -> HDPath {
        let index = hardened ? index % HDPath.hardenedIndexPrefix : index
        let component = Component(index: index, isHardened: hardened)
        let path = HDPath(components: [component])
        path.parent = self
        return path
    }
    /// String representation of HDPath
    public var description: String {
        var string = ""
        if let parent = parent {
            string += parent.description
        } else if m {
            string += "m/"
        }
        string += components.map { $0.description }.joined(separator: "/")
        return string
    }
    
    
    
    private static func parse(_ path: String) throws -> (Bool,[Component]) {
        let components = path.components(separatedBy: "/")
        var array = [Component]()
        var m: Bool
        var firstComponent = 0
        if path.hasPrefix("m") {
            m = true
            firstComponent = 1
        } else {
            m = false
        }
        for component in components[firstComponent ..< components.count] {
            var component = component
            let hardened = component.hasSuffix("'")
            if hardened {
                component.removeLast()
            }
            guard let index = UInt32(component) else { throw Error.invalidHDPath(path) }
            array.append(Component(index: index, isHardened: hardened))
        }
        return (m,array)
    }
}
