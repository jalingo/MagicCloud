//
//  MCErrorHandler.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/17/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/**
    This class handles the various possible CKErrors in a uniform and thorough way. Must create a new
    instance for each error resolution to ensure property 'executableBlock' doesn't get overwritten before
    func 'executeBlock' is called.
 
    If non-standard error handling is required for a given situation, implementation should handle
    unique aspect of error handling in the completion block first, then all other errors should be passed
    to this system.
 
    Operation requires local cache to conform to `Recordable` protocol for version conflict resolution.
 */
class MCErrorHandler<R: MCMirrorAbstraction>: Operation, ConsoleErrorPrinter, GenericErrorNotifier, ResolutionSwitcher {
    
    // MARK: - Properties
    
    /// This property represents the instances conforming to recordable that were interacting with cloud.
    fileprivate var recordables = [R.type]()
    
    // MARK: - Properties: MCRecordableReceiver
    
    /// !!
    fileprivate let receiver: R

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
    
    /**
        Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
        Setting this property with a non-nil value sets `ignoreUnknownItem` property to true.
     */
    var ignoreUnknownItemCustomAction: OptionalClosure {
        didSet {
            if ignoreUnknownItemCustomAction != nil { ignoreUnknownItem = true }
        }
    }
    
    // MARK: - Properties: GenericErrorNotifier
    
    /// This is the error that needs to be handled by this operation.
    let error: CKError
    
    /// This is the operation that was running when error was generated.
    let originatingOp: Operation
    
    // MARK: - Functions
    
    override func main() {
        if isCancelled { return }
        printAbout(error, from: originatingOp, to: database, with: recordables)

        if isCancelled { return }
        notifyExternalAccessors()
        
        if isCancelled { return }
        resolve(error, in: originatingOp, with: recordables, from: receiver, to: database, withPolicy: conflictResolutionPolicy, whileIgnoringUnknowns: ignoreUnknownItem, unknownCustomAction: ignoreUnknownItemCustomAction)
    }
    
    /**
        - parameter error: CKError that was generated. Not optional to force check for nil / check for success before initializing error handling.
        - parameter instances: This array of instances conforming to Recordable protocol generated the record which generated said error(s).
        - parameter originating: Operation that was executing when error was generated in case a retry attempt is warranted. If left nil, no retries will be attempted, regardless of error type.
        - parameter target: Cloud Database in which error was generated, and in which resolution will occur.
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
