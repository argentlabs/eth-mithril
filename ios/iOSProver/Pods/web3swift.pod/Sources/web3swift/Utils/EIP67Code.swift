//
//  EIP67CodeGenerator.swift
//  web3swift
//
//  Created by Alexander Vlasov on 09.04.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

#if canImport(CoreImage)
import BigInt
import CoreImage
import Foundation

/// QRCode typealias
public typealias EthereumQRCode = EIP67Code

/**
 QR Code representation of address or blockchain transaction
 */
public struct EIP67Code {
    /// Recipient
    public var address: Address
    /// Gas limit
    public var gasLimit: BigUInt?
    /// Value
    public var amount: BigUInt?
    /// Transaction data
    public var data: DataType?
    
    /// Data type
    public enum DataType {
        /// Data
        case data(Data)
        /// Function
        case function(Function)
    }

    /// Function type
    public struct Function {
        /// Function method
        public var method: String
        /// Function parameters
        public var parameters: [(ABIv2.Element.ParameterType, AnyObject)]
        /// String representation
        public func toString() -> String? {
            let encoding = method + "(" + parameters.map({ (el) -> String in
                if let string = el.1 as? String {
                    return el.0.abiRepresentation + " " + string
                } else if let number = el.1 as? BigUInt {
                    return el.0.abiRepresentation + " " + String(number, radix: 10)
                } else if let number = el.1 as? BigInt {
                    return el.0.abiRepresentation + " " + String(number, radix: 10)
                } else if let data = el.1 as? Data {
                    return el.0.abiRepresentation + " " + data.hex.withHex
                }
                return ""
            }).joined(separator: ", ") + ")"
            return encoding
        }
    }
    /// Init with address
    public init(address: Address) {
        self.address = address
    }
    /// Init with url
    public init?(string: String) {
        guard string.hasPrefix("ethereum:") else { return nil }
        let striped = string.components(separatedBy: "ethereum:")
        guard striped.count == 2 else { return nil }
        guard let encoding = striped[1].removingPercentEncoding else { return nil }
        guard let url = URL(string: encoding) else { return nil }
        address = Address(url.lastPathComponent)
        guard address.isValid else { return nil }
        guard let components = URLComponents(string: encoding)?.queryItems else { return }
        for comp in components {
            switch comp.name {
            case "value":
                guard let value = comp.value else { return nil }
                guard let val = BigUInt(value, radix: 10) else { return nil }
                amount = val
            case "gas":
                guard let value = comp.value else { return nil }
                guard let val = BigUInt(value, radix: 10) else { return nil }
                gasLimit = val
            case "data":
                guard let value = comp.value else { return nil }
                guard let data = Data.fromHex(value) else { return nil }
                self.data = EIP67Code.DataType.data(data)
            case "function":
                continue
            default:
                continue
            }
        }
    }
    
    /// String representation
    public func toString() -> String {
        var urlComponents = URLComponents()
        let mainPart = "ethereum:" + address.address.lowercased()
        var queryItems = [URLQueryItem]()
        if let amount = self.amount {
            queryItems.append(URLQueryItem(name: "value", value: String(amount, radix: 10)))
        }
        if let gasLimit = self.gasLimit {
            queryItems.append(URLQueryItem(name: "gas", value: String(gasLimit, radix: 10)))
        }
        if let data = self.data {
            switch data {
            case let .data(d):
                queryItems.append(URLQueryItem(name: "data", value: d.hex.withHex))
            case let .function(f):
                if let enc = f.toString() {
                    queryItems.append(URLQueryItem(name: "function", value: enc))
                }
            }
        }
        urlComponents.queryItems = queryItems
        if let url = urlComponents.url {
            return mainPart + url.absoluteString
        }
        return mainPart
    }
    
    /// Generates QRCode image. Returns CIImage() if something goes wrong
    public func toImage(scale: Double = 1.0) -> CIImage {
        let from = self
        guard let string = from.toString().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return CIImage() }
        guard let data = string.data(using: .utf8, allowLossyConversion: false) else { return CIImage() }
        let filter = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": data, "inputCorrectionLevel": "L"])
        guard var image = filter?.outputImage else { return CIImage() }
        let transformation = CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale))
        image = image.transformed(by: transformation)
        return image
    }
}

#endif
