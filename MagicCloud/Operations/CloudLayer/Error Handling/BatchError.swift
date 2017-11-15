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
    var receiver: R?
    
    fileprivate let operation: Operation
    
    fileprivate var recordables = [R.type]()
    
    fileprivate var database = CKContainer.default().privateCloudDatabase
    
    /// Skips over any error handling for `.unknownItem` errors.
    var ignoreUnknownItem = false
    
    /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
    /// - Caution: Setting this property does not effect `ignoreUnknownItem` property.
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    // MARK: - Functions
    
    override func main() {
        
        if isCancelled { return }
        
        var resolution: Operation?
        
        switch error.code {
        case .partialFailure:
            NotificationCenter.default.post(name: MCNotification.partialFailure, object: error)
            resolution = PartialError(error: error,
                                      occuredIn: operation,
                                      instances: recordables,
                                      target: database)
            if let resolverOp = resolution as? PartialError {
                resolverOp.ignoreUnknownItem = self.ignoreUnknownItem
                resolverOp.ignoreUnknownItemCustomAction = self.ignoreUnknownItemCustomAction
            }
        case .limitExceeded:
            NotificationCenter.default.post(name: MCNotification.limitExceeded, object: error)
            resolution = LimitExceeded<R>(error: error,
                                          occuredIn: operation,
                                          target: database,
                                          rec: receiver!)
        case .batchRequestFailed:
            NotificationCenter.default.post(name: MCNotification.limitExceeded, object: error)
        default:
            print("undefined failure @ BatchError: \(error.localizedDescription)")
        }
        
        if isCancelled { return }
        
        if let operation = resolution { ErrorQueue().addOperation(operation) }
    }
    
    // MARK: - Functions: Constructors
    
    fileprivate override init() {
        error = CKError(_nsError: NSError())
        operation = Operation()
        receiver = nil
    }
    
    init(error: CKError, occuredIn: Operation, target: CKDatabase, receiver: R) {
        self.error = error
        operation = occuredIn
        recordables = receiver.recordables
        self.receiver = receiver
        database = target
    }
}
