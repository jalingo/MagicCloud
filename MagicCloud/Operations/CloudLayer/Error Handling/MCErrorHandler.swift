//
//  MCErrorHandler.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/17/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/**
 * This class handles the various possible CKErrors in a uniform and thorough way. Must create a new
 * instance for each error resolution to ensure property 'executableBlock' doesn't get overwritten before
 * func 'executeBlock' is called.
 *
 * If non-standard error handling is required for a given situation, implementation should handle
 * unique aspect of error handling in the completion block first, then all other errors should be passed
 * to this system.
 *
 * Operation requires local cache to conform to `Recordable` protocol for version conflict resolution.
 */
class MCErrorHandler<R: MCReceiver>: Operation, MCRetrier {
    
    // MARK: - Properties
    
    fileprivate let receiver: R
    
    /// This is the error that needs to be handled by this operation.
    fileprivate let error: CKError
    
    /// This is the operation that was running when error was generated.
    fileprivate let originatingOp: Operation
    
    /// This property represents the instances conforming to recordable that were interacting with cloud.
    fileprivate var recordables = [R.type]()
    
    /// This is the database cloud activity generated an error in.
    fileprivate var database: MCDatabase
    
    // MARK: - Properties: Accessors
    
    /**
        This save policy will be used if version conflict detected (CKError.serverRecordChanged).
     
        - Default: CKRecordSavePolicy.changedKeys
     */
    var conflictResolutionPolicy: CKRecordSavePolicy = .changedKeys
    
    /// Skips over any error handling for `.unknownItem` errors, except `ignoreUnknownItemCustomAction`.
    var ignoreUnknownItem = false
    
    /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
    /// - Caution: Setting this property does not effect `ignoreUnknownItem` property.
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    // MARK: - Functions
    
    override func main() {
        if isCancelled { return }
        
        // This console message reports instances when error shouldn't be ignored or isn't partial failure.
        if !(error.code == .unknownItem && ignoreUnknownItem) || !(error.code == .partialFailure) {
            let name = Notification.Name(MCNotification.error.toString())
            NotificationCenter.default.post(name: name, object: error)
        }
        
        if isCancelled { return }
        
        // After the following switch identifies the type of error, variable will contain response.
        var resolvingOperation: Operation?
        
        switch error.code {
            
        // This error occurs when record's change tag indicates a version conflict (modify operations).
        case .serverRecordChanged:
            resolvingOperation = VersionConflict(rec: receiver,
                                                 error: error,
                                                 target: database,
                                                 policy: self.conflictResolutionPolicy,
                                                 instances: recordables,
                                                 completionBlock: completionBlock)
            completionBlock = nil
     
        // These errors occur when a batch of requests fails or partially fails (batch operations).
        case .limitExceeded, .batchRequestFailed, .partialFailure:
            resolvingOperation = BatchError(error: error,
                                            occuredIn: originatingOp,
                                            target: database, receiver: receiver, instances: recordables)
                                            
            if let resolver = resolvingOperation as? BatchError<R> {
                resolver.ignoreUnknownItem = self.ignoreUnknownItem
                resolver.ignoreUnknownItemCustomAction = self.ignoreUnknownItemCustomAction
            }
    
        // These errors occur as a result of environmental factors, and originating operation should
        // be retried after a set amount of time.
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
            guard let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval else { return }

            if isCancelled { return }

            let q = DispatchQueue(label: retriableLabel)
            if let op = replicate(originatingOp, with: receiver) {
                
                if isCancelled { return }

                q.asyncAfter(deadline: .now() + retryAfterValue) {
                    if self.isCancelled { return }
                    
                    if let cloudOp = op as? CKDatabaseOperation {
                        self.database.db.add(cloudOp)
                    } else {
                        OperationQueue().addOperation(op)
                    }
                }
            }
            
            completionBlock = nil
        
        // These errors occur when CloudKit has a problem with a CKSharedDatabase operation.    // <-- Not currently supported but left here for future versions.
//        case .alreadyShared, .tooManyParticipants:
        
        // This case allows .unknownItem to be ignored (query / fetch / modify operations).
        case .unknownItem where ignoreUnknownItem:
            if let block = ignoreUnknownItemCustomAction { block() }
            
        // These fatal errors do not require any further handling.
        default: break
        }
        
        if isCancelled { return }
        
        // After resolution determined in previous switch statement, resolution is initiated here.
        if let op = resolvingOperation { OperationQueue().addOperation(op) }
    }
    
    /**
     * - parameter error: CKError that was generated. Not optional to force check for nil / check for
     *      success before initializing error handling.
     *
     * - parameter instances: This array of instances conforming to Recordable protocol generated the
     *      record which generated said error(s).
     *
     * - parameter originating: Operation that was executing when error was generated in case a retry
     *      attempt is warranted. If left nil, no retries will be attempted, regardless of error type.
     *
     * - parameter target: Cloud Database in which error was generated, and in which resolution will
     *      occur.
     */
    init(error: CKError, originating: Operation, target: MCDatabase, instances: [R.type], receiver: R) {
        self.error = error
        self.receiver = receiver
        
        originatingOp = originating
        recordables = instances
        database = target
        
        super.init()
    }
}
