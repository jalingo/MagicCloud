//
//  RetriableErrorOperation.swift
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
class RetriableErrorOperation: Operation {
    
    // MARK: - Properties

    /// This property contains the dispatch queue the timer will use during retry attempt.
    fileprivate let queue = DispatchQueue(label: "RetryAttemptQueue")
    
    /// This property contains the error that generated this retry attempt.
    fileprivate var error: CKError
    /// This property contains the queue in which the operation generated `error`.
    fileprivate var originatingQueue: OperationQueue
    /// This property contains the operation that generated `error`.
    fileprivate var originatingOperation: Operation
    /// This property contains the completion handler that runs after `originatingOperation` is retried.
    fileprivate var completionHandler: OptionalClosure
    
    // MARK: - Functions
    
    /// This method override contains the actual retry attempt, pausing until the apropos duration passes.
    override func main() {
        if isCancelled { return }
        
        guard let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval else { return }
        
        if isCancelled { return }
        
        queue.async { [weak self] in
            Timer.scheduledTimer(withTimeInterval: retryAfterValue, repeats: false) { timer in
                if let me = self {
                    if me.isCancelled { return }
                    
                    if let handler = me.completionHandler {
                        let followUpOperation = Operation()
                        followUpOperation.completionBlock = handler
                        followUpOperation.addDependency(me.originatingOperation)
                        me.originatingQueue.addOperation(followUpOperation)
                    }
    
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
     *
     * - parameter completion: OptionalClosure that will be executed after retry attempt concludes.
     */
    init(error: CKError, originating: Operation, associated: OperationQueue, completion: OptionalClosure = nil) {
        self.error = error
        originatingQueue = associated
        originatingOperation = originating
        
        /**
         * Completion handler is a separate operation (rather than `originatingOperation.completionBlock`)
         * to account for async dispatch of timer.
         */
        completionHandler = completion
        
        super.init()
    }
}

