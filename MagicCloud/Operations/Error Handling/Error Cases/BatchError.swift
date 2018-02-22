//
//  BatchFailed.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/// This operation identifies the type of error thrown by batch and handles it.
class BatchError<R: MCMirrorAbstraction>: Operation {
    
    // MARK: - Properties
    
    /// Not fileprivate so that testing mock can access.
    let error: CKError

    /// This receiver contains storage site for batch of instances
    let receiver: R
    
    fileprivate let operation: Operation
    
    fileprivate var recordables = [R.type]()
    
    fileprivate var database: MCDatabase
    
    /// Skips over any error handling for `.unknownItem` errors.
    var ignoreUnknownItem = false
    
    /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
    /// - Caution: Setting this property does not effect `ignoreUnknownItem` property.
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    // MARK: - Functions
    
    override func main() {
        
        if isCancelled { return }
        
        var resolution: Operation?

        // This notification is required for tests and is in addition to more specific notification
        let name = Notification.Name(MCErrorNotification)
        NotificationCenter.default.post(name: name, object: error)
        
        switch error.code {
        case .partialFailure:
            resolution = PartialError(error: error,
                                      occuredIn: operation, at: receiver,
                                      instances: recordables,
                                      target: database)
            if let resolverOp = resolution as? PartialError<R> {
                resolverOp.ignoreUnknownItem = self.ignoreUnknownItem
                resolverOp.ignoreUnknownItemCustomAction = self.ignoreUnknownItemCustomAction
            }
        case .limitExceeded:
            resolution = LimitExceeded<R>(error: error,
                                          occuredIn: operation,
                                          rec: receiver, instances: recordables, target: database)
        case .batchRequestFailed: break
        default: break
        }
        
        if isCancelled { return }
        
        if let operation = resolution { OperationQueue().addOperation(operation) }
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
