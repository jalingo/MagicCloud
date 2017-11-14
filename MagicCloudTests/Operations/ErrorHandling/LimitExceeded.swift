//
//  LimitExceeded.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import Foundation
import CloudKit

class LimitExceeded: Operation {
    
    // MARK: - Properties
    
    fileprivate var cloudError = CKError(_nsError: NSError())
    
    fileprivate var erringOperation = Operation()
    
    fileprivate var recordables = [Recordable]()
    
    fileprivate var database = CKContainer.default().privateCloudDatabase
    
    // MARK: - Functions
    
    override func main() {
        if isCancelled { return }
        
        let halfwayIndex = (recordables.count / 2) - 1
        let firstHalf = recordables[0..<halfwayIndex]
        let secondHalf = recordables[halfwayIndex...recordables.endIndex - 1]
        
        var resolver0: Operation?
        var resolver1: Operation?
        
        if let _ = erringOperation as? Delete {
            let first = Array(firstHalf)
            let second = Array(secondHalf)
            resolver0 = Delete(first)
            resolver1 = Delete(second)
        }
        
        if let op = erringOperation as? Download {
            resolver0 = duplicate(op)
            resolver1 = Operation()
            
            if let limit = op.limit {
                (resolver0 as? Download)?.limit = Int(round(Double(limit / 2)))
            } else {
                (resolver0 as? Download)?.limit = 20
            }
        }
        
        if let op0 = resolver0, let op1 = resolver1 {
            op1.addDependency(op0)          // <-- This may not be necessary, but feels nice...
            CloudQueue().addOperation(op1)
            CloudQueue().addOperation(op0)
        } else {
            print("Limit Exceeded Error occured and went unhandled: \(cloudError)")
        }
    }
    
    // MARK: - Functions: Constructors
    
    init(error: CKError, occuredIn: Operation, instances: [Recordable], target: CKDatabase) {
        cloudError = error
        erringOperation = occuredIn
        recordables = instances
        database = target
        
        super.init()
    }
    
    /// This overrides ensures that init without parameters is fileprivate.
    fileprivate override init() { }
}
