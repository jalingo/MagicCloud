//
//  BatchFailed.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/// This operation identifies the type of error thrown by batch and handles it.
class BatchError<R: MCMirrorAbstraction>: Operation, BatchSplitter, PartialErrorResolver {
    
    // MARK: - Properties
    
    /// Not fileprivate so that testing mock can access.
    let error: CKError

    /// !!
    fileprivate let operation: Operation

    // MARK: - Properties: BatchSplitter
    
    /// This receiver contains storage site for batch of instances
    let receiver: R
    
    /// !!
    var recordables = [R.type]()
    
    /// !!
    var database: MCDatabase
    
    // MARK: - Properties: PartialErrorResolver
    
    /// Skips over any error handling for `.unknownItem` errors.
    var ignoreUnknownItem = false
    
    /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
    /// - Caution: Setting this property does not effect `ignoreUnknownItem` property.
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    // MARK: - Functions
    
    override func main() {
        if isCancelled { return }
        
        // !! This notification is required for tests and is in addition to more specific notification
        let name = Notification.Name(MCErrorNotification)
        NotificationCenter.default.post(name: name, object: error)
        
        if isCancelled { return }

        switch error.code {
        case .partialFailure:     resolvePartial(error, in: operation)
        case .limitExceeded:      splitBatch(error: error, in: operation)
        case .batchRequestFailed: break
        default: break
        }
    }
    
    // MARK: - Functions: Constructors
    
    init(error: CKError, occuredIn: Operation, target: MCDatabase, receiver: R, instances: [R.type]) {
        self.error = error
        operation = occuredIn
        recordables = instances
        self.receiver = receiver
        database = target
    }
}

extension BatchError: MCDatabaseModifier {
    
    /// - Warning: This placeholder property is never called, and is only used for `MCDatabaseModifier` conformance.
    var modifyCompletion: ModifyBlock {
        return { _,_,_ in }
    }
}
