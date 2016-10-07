//
//  CloudErrorOperation.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/21/16.
//
//

import Foundation
import CloudKit

/**
 * This class handles the various possible CKErrors in a uniform and thorough way. Must create a new
 * instance for each error resolution to ensure property 'executableBlock' doesn't get overwritten before
 * func 'executeBlock' is called.
 *
 * If unique / non-standard error handling is required for a given situation, implementation should handle 
 * unique aspect of error handling in the completion block first, then all other errors should be passed 
 * to this system. 
 *
 * System requires local cache to conform to `Recordable` protocol for version conflict resolution.
 */
class CloudErrorOperation: Operation {
    
    /// This property represents the instance conforming to recordable that was interacting with cloud.
    var recordable: Recordable?
    /// This is the error that needs to be handled by this operation.
    var error: CKError?
    /// This is the database cloud activity generated an error in.
    var database: CKDatabase?
    /// This is the operation that was running when error was generated.
    var operation: Operation?
    /// This is the queue that operation was running in when error was generated.
    var queue: OperationQueue?  
    
    override func main() {

        if isCancelled { return }
        
        // After the following switch identifies the type of error, variable will contain response.
        var resolvingOperation: Operation

        switch error!.code {
            
        // This error occurs when USER is not logged in to an iCloud account on their device.
        case .notAuthenticated:
            resolvingOperation = UnauthenticErrorOperation()
            
        // This error occurs when record's change tag indicates a version conflict.
        case .serverRecordChanged:
            resolvingOperation = VersionConflictOperation(error: error!,
                                                          instance: recordable!,
                                                          completionBlock: completionBlock)
            completionBlock = nil   // <-- Completion Block has been passed on to resolvingOperation.
            
        // These errors occur when a batch of requests fails or partially fails.
        case .limitExceeded, .batchRequestFailed, .partialFailure:
            resolvingOperation = BatchErrorOperation()
            
        // These errors occur as a result of environmental factors, and originating operation
        // should be retried after a set amount of time.
        case .networkUnavailable, .networkFailure,
             .serviceUnavailable, .requestRateLimited,
             .resultsTruncated,   .zoneBusy:
            if let originatingOp = operation {
                resolvingOperation = RetriableErrorOperation(error: error!,
                                                             originating: originatingOp,
                                                             associated: queue!,
                                                             completion: completionBlock)
                completionBlock = nil   // <-- Completion Block has been passed on to resolvingOperation.
            } else {
                resolvingOperation = FatalErrorOperation(error: error!)
            }
            
        // These fatal errors do not require any further handling, except for a USER notification.
        default:
            resolvingOperation = FatalErrorOperation(error: error!)
        }
        
        if isCancelled { return }

        // After resolution determined in previous switch statement, resolution is initiated here.
        let resolvingQueue = ErrorQueue()
        resolvingQueue.addOperation(resolvingOperation)
    }
    
    /**
     * - parameter error: CKError that was generated. Not optional to force check for nil / check for 
     *      success before initializing error handling.
     *
     * - parameter instance: This instance conforming to Recordable protocol generated the record which 
     *      generated said error(s).
     *
     * - parameter originating: Operation that was executing when error was generated in case a retry 
     *      attempt is warranted. If left nil, no retries will be attempted, regardless of error type.
     *
     * - parameter failedOn: The OperationQueue that `originating` error should be executed on, in the
     *      event of a retry attempt.
     */
    init(error: CKError, instance: Recordable, database: CKDatabase, originating: Operation, failedOn: OperationQueue) {
        self.error = error
        recordable = instance
        self.database = database
        operation = originating
        self.queue = failedOn
        
        super.init()
    }
    
    /// This init without dependencies has been overridden to make it private and inaccessible.
    fileprivate override init() { }
}
