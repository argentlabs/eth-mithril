//
//  EventFiltering.swift
//  web3swift
//
//  Created by Alexander Vlasov on 11.05.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

internal func filterLogs(decodedLogs: [EventParserResult], eventFilter: EventFilter) -> [EventParserResult] {
    let filteredLogs = decodedLogs.filter { (result) -> Bool in
        if eventFilter.addresses == nil {
            return true
        } else {
            if eventFilter.addresses!.contains(result.contractAddress) {
                return true
            } else {
                return false
            }
        }
    }.filter { (result) -> Bool in
        if eventFilter.parameterFilters == nil {
            return true
        } else {
            let keys = result.decodedResult.keys.filter({ (key) -> Bool in
                if let _ = UInt64(key) {
                    return true
                }
                return false
            })
            if keys.count < eventFilter.parameterFilters!.count {
                return false
            }
            for i in 0 ..< eventFilter.parameterFilters!.count {
                let allowedValues = eventFilter.parameterFilters![i]
                let actualValue = result.decodedResult["\(i)"]
                if actualValue == nil {
                    return false
                }
                if allowedValues == nil {
                    continue
                }
                var inAllowed = false
                for value in allowedValues! {
                    if value.isEqualTo(actualValue! as AnyObject) {
                        inAllowed = true
                        break
                    }
                }
                if !inAllowed {
                    return false
                }
            }
            return true
        }
    }
    return filteredLogs
}

internal func encodeTopicToGetLogs(contract: ContractV2, eventName: String?, filter: EventFilter) -> EventFilterParameters? {
    var eventTopic: Data?
    var event: ABIv2.Element.Event?
    if eventName != nil {
        guard let ev = contract.events[eventName!] else { return nil }
        event = ev
        eventTopic = ev.topic
    }
    var topics = [[String?]?]()
    if eventTopic != nil {
        topics.append([eventTopic!.hex.withHex])
    } else {
        topics.append(nil as [String?]?)
    }
    if filter.parameterFilters != nil {
        if event == nil { return nil }
        var lastNonemptyFilter = -1
        for i in 0 ..< filter.parameterFilters!.count {
            let filterValue = filter.parameterFilters![i]
            if filterValue != nil {
                lastNonemptyFilter = i
            }
        }
        if lastNonemptyFilter != -1 {
            guard lastNonemptyFilter <= event!.inputs.count else { return nil }
            for i in 0 ... lastNonemptyFilter {
                let filterValues = filter.parameterFilters![i]
                let input = event!.inputs[i]
                if filterValues != nil && !input.indexed { return nil }
                if filterValues == nil {
                    topics.append(nil as [String?]?)
                    continue
                }
                var encodings = [String]()
                for val in filterValues! {
                    guard let enc = val.eventFilterEncoded() else { return nil }
                    encodings.append(enc)
                }
                topics.append(encodings)
            }
        }
    }
    var preEncoding = filter.rpcPreEncode()
    preEncoding.topics = topics
    return preEncoding
}

internal func parseReceiptForLogs(receipt: TransactionReceipt, contract: ContractProtocol, eventName: String, filter: EventFilter?) -> [EventParserResult]? {
    guard let bloom = receipt.logsBloom else { return nil }
    if contract.address != nil {
        let addressPresent = bloom.test(topic: contract.address!.addressData)
        if addressPresent != true {
            return [EventParserResult]()
        }
    }
    if filter != nil, let filterAddresses = filter?.addresses {
        var oneIsPresent = false
        for addr in filterAddresses {
            let addressPresent = bloom.test(topic: addr.addressData)
            if addressPresent == true {
                oneIsPresent = true
                break
            }
        }
        if oneIsPresent != true {
            return [EventParserResult]()
        }
    }
    guard let eventOfSuchTypeIsPresent = contract.testBloomForEventPrecence(eventName: eventName, bloom: bloom) else { return nil }
    if !eventOfSuchTypeIsPresent {
        return [EventParserResult]()
    }
    var allLogs = receipt.logs
    if contract.address != nil {
        allLogs = receipt.logs.filter({ (log) -> Bool in
            log.address == contract.address
        })
    }
    let decodedLogs = allLogs.compactMap({ (log) -> EventParserResult? in
        let (n, d) = contract.parseEvent(log)
        guard let evName = n, let evData = d else { return nil }
        var result = EventParserResult(eventName: evName, transactionReceipt: receipt, contractAddress: log.address, decodedResult: evData)
        result.eventLog = log
        return result
    }).filter { (res: EventParserResult?) -> Bool in
        return res != nil && res?.eventName == eventName
    }
    var allResults = [EventParserResult]()
    if filter != nil {
        let eventFilter = filter!
        let filteredLogs = filterLogs(decodedLogs: decodedLogs, eventFilter: eventFilter)
        allResults = filteredLogs
    } else {
        allResults = decodedLogs
    }
    return allResults
}
