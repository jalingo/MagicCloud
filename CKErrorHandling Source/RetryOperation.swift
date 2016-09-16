//
//  RetryOperation.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/15/16.
//
//

import Foundation
import CloudKit

// MARK: - Class:

/**
 * Certain cloud errors require a retry attempt (e.g. ZoneBusy), so this operation recovers retry time from
 * userInfo dictionary and then schedules another attempt.
 */
class RetryOperation: Operation {
    
    // MARK: - Properties

    /// This property contains the error that generated this retry attempt.
    var error: CKError
    /// This property contains the queue in which the operation generated it's error.
    var originatingQueue: OperationQueue
    /// This property contains the operation that generated it's error.
    var originatingOperation: Operation
    
    // MARK: - Functions
    
    /// This method override contains the actual retry attempt, pausing until the apropos duration passes.
    override func main() {
        if isCancelled { return }
        
        guard let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval else { return }
        
        if isCancelled { return }
        
        DispatchQueue.main.async { [weak self] in
            Timer.scheduledTimer(withTimeInterval: retryAfterValue, repeats: false) { timer in
                if let me = self {
                    if me.isCancelled { return }
                    me.originatingQueue.addOperation(me.originatingOperation)
                }
            }
        }
    }
    
    /**
     * - parameter error: CKError, not optional to force check for nil / check for success before building
     *      operation.
     *
     * - parameter originating: Operation that triggered error, and should be retried.
     *
     * - parameter associated: OperationQueue that operation should be retried on.
     */
    init(error: CKError, originating: Operation, associated: OperationQueue) {
        self.error = error
        originatingQueue = associated
        originatingOperation = originating
    }
}

