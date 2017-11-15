//
//  PartialError.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/**
 * This class takes partial errors (resulting from batch attempt) and isolates to the failed transactions.
 * After isolation, they can be passed back to through the error handling system individually.
 */
class PartialError<R: ReceivesRecordable>: Operation {
    
    // MARK: - Properties
    
    fileprivate let error: CKError
    
    fileprivate let operation: Operation
    
    fileprivate let queue = ErrorQueue()
    
    fileprivate let receiver: R
    
    var recordables = [R.type]()
    
    var database: DatabaseType
    
    /// Skips over any error handling for `.unknownItem` errors.
    var ignoreUnknownItem = false
    
    /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
    /// - Caution: Setting this property does not effect `ignoreUnknownItem` property.
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    override func main() {
        
        if isCancelled { return }
        
        if let dictionary = error.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
            for entry in dictionary {
                if let partialError = entry.value as? CKError {
                    
                    if ignoreUnknownItem && partialError.code == .unknownItem { return }
                    
                    let errorHandler = MCErrorHandler(error: partialError,
                                                      originating: operation,
                                                      target: database,
                                                      instances: recordables,
                                                      receiver: receiver)
                    errorHandler.ignoreUnknownItem = self.ignoreUnknownItem
                    errorHandler.ignoreUnknownItemCustomAction = self.ignoreUnknownItemCustomAction
                    
                    if isCancelled { return }
                    
                    queue.addOperation(errorHandler)
                }
            }
        }
    }
        
    init(error: CKError, occuredIn: Operation, at rec: R, instances: [R.type], target: DatabaseType) {
        receiver = rec
        self.error = error
        operation = occuredIn
        recordables = instances
        database = target
    }
}
