//
//  BatchFailed.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

class BatchError<R: ReceivesRecordable>: Operation {
    
    // MARK: - Properties
    
    /// Not fileprivate so that testing mock can access.
    let error: CKError

    /// This receiver contains storage site for batch of instances
    let receiver: R
    
    fileprivate let operation: Operation
    
    fileprivate var recordables = [R.type]()
    
    fileprivate var database: DatabaseType
    
    /// Skips over any error handling for `.unknownItem` errors.
    var ignoreUnknownItem = false
    
    /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
    /// - Caution: Setting this property does not effect `ignoreUnknownItem` property.
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    // MARK: - Functions
    
    override func main() {
        
        if isCancelled { return }
        
        var resolution: Operation?

        // !!
        ///#######/// vvvvvvvv FOR TESTING PURPOSES vvvvvvvv ///#######///
        
        let name = Notification.Name(MCNotification.error(error).toString())
        NotificationCenter.default.post(name: name, object: error)
        
        ///#######/// ^^^^^^^^ REMOVE BEFORE SUBMIT ^^^^^^^^ ///#######///
        
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
        
        if let operation = resolution { ErrorQueue().addOperation(operation) }
    }
    
    // MARK: - Functions: Constructors
    
    init(error: CKError, occuredIn: Operation, target: DatabaseType, receiver: R, instances: [R.type]) {
        self.error = error
        operation = occuredIn
        recordables = instances
        self.receiver = receiver
        database = target
    }
}
