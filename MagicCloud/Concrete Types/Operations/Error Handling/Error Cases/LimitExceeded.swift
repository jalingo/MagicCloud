//
//  LimitExceeded.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import Foundation
import CloudKit

class LimitExceeded<R: MCMirrorAbstraction>: Operation, BatchSplitter {
    
    // MARK: - Properties
    
    fileprivate var cloudError = CKError(_nsError: NSError())
    
    fileprivate var erringOperation = Operation()

    // MARK: - Properties: MCDatabaseModifier
    
    let receiver: R

    var recordables = [R.type]()
    
    let database: MCDatabase
    
    // MARK: - Functions
    
    override func main() {
        if isCancelled { return }
        
        splitBatch(error: cloudError, in: erringOperation)
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

// MARK: - Extensions

extension LimitExceeded: MCDatabaseModifier {

    /// - Warning: This placeholder property is never called, and is only used for `MCDatabaseModifier` conformance.
    var modifyCompletion: ModifyBlock {
        return { _,_,_ in }
    }
}
