//
//  RetriableError.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/22/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

// MARK: - Class: RetriableErrorOperation

/**
 * Certain cloud errors require a retry attempt (e.g. ZoneBusy), so this operation recovers retry time from
 * userInfo dictionary and then schedules another attempt.
 */
class RetriableError: Operation {
    
    // MARK: - Properties
    
    /// This property contains the dispatch queue the timer will use during retry attempt.
    fileprivate let queue = DispatchQueue(label: "RetryAttemptQueue")
    
    /// This property contains the error that generated this retry attempt.
    fileprivate var error: CKError
    
    /// This property contains the operation that generated `error`.
    fileprivate var originatingOp: Operation
    
    /// The CKDatabase in which CKDatabaseOperations should be retried.
    fileprivate var database = CKContainer.default().privateCloudDatabase
    
    // MARK: - Functions
    
    /// This method override contains the actual retry attempt, pausing until the apropos duration passes.
    override func main() {
        if isCancelled { return }
        
        guard let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval else { return }
        
        if isCancelled { return }

        if let op = duplicate(originatingOp) {
            queue.async {
                let timer = Timer.scheduledTimer(withTimeInterval: retryAfterValue, repeats: false) { timer in
                    if self.isCancelled { return }
                    
                    if let cloudOp = op as? CKDatabaseOperation {
                        self.database.add(cloudOp)
                    } else {
                        ErrorQueue().addOperation(op)
                    }
                }
                
                timer.fire()
            }
        }
    }
    
    /**
     * - parameter error: CKError, not optional to force check for nil / check for success before building
     *      operation.
     *
     * - parameter originating: Operation that triggered error, and should be retried.
     *
     * - parameter completion: OptionalClosure that will be executed after retry attempt concludes.
     *
     * - parameter database: TODO...
     */
    init(error: CKError, originating: Operation, target: CKDatabase, completion: OptionalClosure = nil) {
        self.error = error
        originatingOp = originating
        originatingOp.completionBlock = completion
        database = target
        
        super.init()
    }
}
