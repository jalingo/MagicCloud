//
//  BatchFailed.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

class BatchError: Operation {
    
    // MARK: - Properties
    
    /// Not fileprivate so that testing mock can access.
    let error: CKError
    
    fileprivate let operation: Operation
    
    fileprivate var recordables = [Recordable]()
    
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
            resolution = LimitExceeded(error: error,
                                       occuredIn: operation,
                                       instances: recordables,
                                       target: database)
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
    }
    
    init(error: CKError, occuredIn: Operation, instances: [Recordable], target: CKDatabase) {
        self.error = error
        operation = occuredIn
        recordables = instances
        database = target
    }
}
