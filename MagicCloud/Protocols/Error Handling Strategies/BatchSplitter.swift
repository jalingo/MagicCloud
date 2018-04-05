//
//  BatchSplitter.swift
//  MagicCloud
//
//  Created by James Lingo on 3/26/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types conforming to this protocol can call the `splitBatch:error:in` method that splits affected batch of records into two equal sub sets and then relaunches an attempt for each sub set.
protocol BatchSplitter: MCOperationReplicator { }

extension BatchSplitter where Self: MCDatabaseModifier {
    
    func splitBatch(error cloudError: CKError, in erringOperation: Operation) {
        let halfwayIndex = (recordables.count / 2) - 1
        
        guard halfwayIndex > 0 else { return }
        
        let firstHalf = recordables[0..<halfwayIndex]
        let secondHalf = recordables[halfwayIndex...recordables.endIndex - 1]
        
        var resolver0: Operation?
        var resolver1: Operation?
        
        if let _ = erringOperation as? MCDelete<R> {
            let first = Array(firstHalf)
            let second = Array(secondHalf)
            
            resolver0 = MCDelete(first, of: receiver, from: database)
            resolver1 = MCDelete(second, of: receiver, from: database)
        }
        
        if let op = erringOperation as? MCDownload<R> {   // <- Is this even possible? Downloads shouldn't get error...
            resolver0 = replicate(op, with: receiver)
            resolver1 = Operation()
            
            if let limit = op.limit {
                (resolver0 as? MCDownload<R>)?.limit = Int(round(Double(limit / 2)))
            } else {
                (resolver0 as? MCDownload<R>)?.limit = 20
            }
        }
        
        if let op0 = resolver0, let op1 = resolver1 {
            op1.addDependency(op0)          // <-- This may not be necessary, but feels nice...
            OperationQueue().addOperation(op1)
            OperationQueue().addOperation(op0)
        } else {
            print(" !E - Limit Exceeded Error occured and went unhandled: \(cloudError)")
        }
    }
}
