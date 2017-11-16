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
class MCErrorHandler<R: ReceivesRecordable>: Operation {
    
    // MARK: - Properties
    
    fileprivate let receiver: R
    
    /// This is the error that needs to be handled by this operation.
    fileprivate let error: CKError
    
    /// This is the operation that was running when error was generated.
    fileprivate let originatingOp: Operation
    
    /// This property represents the instances conforming to recordable that were interacting with cloud.
    fileprivate var recordables = [R.type]()
    
    /// This is the database cloud activity generated an error in.
    fileprivate var database: DatabaseType
    
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
print("** running error handling")
        // This console message reports instances when error shouldn't be ignored or isn't partial failure.
        if !(error.code == .unknownItem && ignoreUnknownItem) || !(error.code == .partialFailure) {                 // <-- !! Remove after tests all passing !!
print("!! CKError: \(error.code.rawValue) / \(error.localizedDescription) @ \(String(describing: originatingOp.name))")
        }
        
        if isCancelled { return }
        
        // After the following switch identifies the type of error, variable will contain response.
        var resolvingOperation: Operation?
        
        switch error.code {
            
        // This error occurs when USER is not logged in to an iCloud account on their device.
        case .notAuthenticated:
            NotificationCenter.default.post(name: MCNotification.notAuthenticated, object: error)
            
        // This error occurs when record's change tag indicates a version conflict.
        case .serverRecordChanged:
            NotificationCenter.default.post(name: MCNotification.serverRecordChanged, object: error)
            resolvingOperation = VersionConflict(rec: receiver,
                                                 error: error,
                                                 target: database,
                                                 policy: self.conflictResolutionPolicy,
                                                 instances: recordables,
                                                 completionBlock: completionBlock)
            completionBlock = nil
     
        // These errors occur when a batch of requests fails or partially fails.
        case .limitExceeded, .batchRequestFailed, .partialFailure:
            NotificationCenter.default.post(name: MCNotification.batchIssue, object: error)
            resolvingOperation = BatchError(error: error,
                                            occuredIn: originatingOp,
                                            target: database, receiver: receiver, instances: recordables)
                                            
            if let resolver = resolvingOperation as? BatchError<R> {
                resolver.ignoreUnknownItem = self.ignoreUnknownItem
                resolver.ignoreUnknownItemCustomAction = self.ignoreUnknownItemCustomAction
            }
    
        // These errors occur as a result of environmental factors, and originating operation should
        // be retried after a set amount of time.
        case .networkUnavailable, .networkFailure,
             .serviceUnavailable, .requestRateLimited,
             .resultsTruncated,   .zoneBusy:
            NotificationCenter.default.post(name: MCNotification.retriable, object: error)
            resolvingOperation = RetriableError(error: error,
                                                originating: originatingOp,
                                                target: database,
                                                receiver: receiver,
                                                completion: completionBlock)
            completionBlock = nil
        
        // These errors occur when CloudKit has a problem with a CKSharedDatabase operation.
        case .alreadyShared, .tooManyParticipants:
            NotificationCenter.default.post(name: MCNotification.sharingError, object: error)
        
        // This case allows .unknownItem to be ignored.
        case .unknownItem where ignoreUnknownItem:
            print("** ignoring unknownItem.")
            if let block = ignoreUnknownItemCustomAction { block() }
            
        // These fatal errors do not require any further handling, except for a USER notification.
        default:
            NotificationCenter.default.post(name: MCNotification.fatalError, object: error)
        }
        
        if isCancelled { return }
        
        // After resolution determined in previous switch statement, resolution is initiated here.
        if let op = resolvingOperation { ErrorQueue().addOperation(op) }
    }
    
    /// This override hides no argument initializer to ensure dependencies get injected.
//    fileprivate override init() {
//        error = CKError(_nsError: NSError())
//        originatingOp = Operation()
//    }
    
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
    init(error: CKError, originating: Operation, target: DatabaseType, instances: [R.type], receiver: R) {
        self.error = error
        self.receiver = receiver
        
        originatingOp = originating
        recordables = instances
        database = target
        
        super.init()
    }
}
