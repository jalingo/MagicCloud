//
//  LimitExceeded.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import Foundation
import CloudKit

class LimitExceeded<R: MCMirrorAbstraction>: Operation, MCOperationReplicator {
    
    // MARK: - Properties
    
    fileprivate let receiver: R
    
    fileprivate var cloudError = CKError(_nsError: NSError())
    
    fileprivate var erringOperation = Operation()
    
    fileprivate var recordables = [R.type]()
    
    fileprivate var database: MCDatabase
    
    // MARK: - Functions
    
    override func main() {
        if isCancelled { return }
        
        let halfwayIndex = (recordables.count / 2) - 1
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
            print("Limit Exceeded Error occured and went unhandled: \(cloudError)")
        }
    }
    
    // MARK: - Functions: Constructors
    
    init(error: CKError, occuredIn: Operation, rec: R, instances: [R.type], target: MCDatabase) {
        cloudError = error
        erringOperation = occuredIn
        recordables = instances
        database = target
        receiver = rec
        
        super.init()
    }
}
