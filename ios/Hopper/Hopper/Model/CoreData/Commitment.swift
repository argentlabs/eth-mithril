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
    
    static func create(withDestination to: String,
                       mixerId: String,
                       in context: NSManagedObjectContext) -> Commitment {
        
        let result = Commitment(context: context)
        result.secret = generateSecret()
        result.to = to
        result.mixerId = mixerId
        result.createdAt = Date()
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
        
        var formattedConfDate = "nil"
        if let confDate = withdrawTxConfirmedAt {
            formattedConfDate = formatter.string(from: confDate)
        }
        return "Comm-\(formatter.string(from: createdAt))--W[R:\(withdrawRequested),M:\(formattedConfDate),H:\(withdrawTxHash ?? "nil"),RF:\(withdrawTxRelayFailed),S:\(withdrawTxSuccesful),P:\(proofComputed),D:\(numSubsequentDeposits)]"
    }
    
}
