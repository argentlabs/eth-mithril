//
//  Commitment.swift
//  iOSProver
//
//  Created by Olivier van den Biggelaar on 18/02/2019.
//  Copyright © 2019 Olivier van den Biggelaar. All rights reserved.
//

import Foundation
import CoreData
import BigInt

class Commitment: NSManagedObject {
    
    static func create(withOrigin from: String,
                       destination to: String,
                       network: String,
                       in context: NSManagedObjectContext) -> Commitment {
        
        let result = Commitment(context: context)
        result.secret = generateSecret()
        result.from = from
        result.to = to
        result.network = network
        result.createdAt = Date()
        result.commitRequested = true
        return result
    }
    
    private static func generateSecret() -> String {
        let max = BigUInt(hexString: "20644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001")!
        return BigUInt.randomInteger(lessThan: max).description
    }
    
    override var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM HH:mm:ss"
        guard let createdAt = createdAt else { return "CommitmentWithInvalidCreatedAt" }
        return "Commitment created at \(formatter.string(from: createdAt))"
    }
    
}
