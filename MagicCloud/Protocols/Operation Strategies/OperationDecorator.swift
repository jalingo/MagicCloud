//
//  OperationDecorator.swift
//  MagicCloud
//
//  Created by James Lingo on 3/20/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Protocol

/// Types conforming to this protocol can call the `decorate` method and generate a configured Operation.
protocol OperationDecorator: SpecialCompleter {
    
    /// This method returns a fully configured Operation, ready to be launched.
    func decorate() -> Operation
}

// MARK: - Extensions

extension OperationDecorator where Self: Operation {
    
    /// This void method sets injected operation's `isLongLived` property to specified value, based on current device's operating system.
    /// - Parameters:
    ///     - op: The database modification operation that may or may not need to persist in the database after an app has moved to the background (if background app refresh not enabled) or has been terminated, depending on `value` passed.
    ///     - value: When true, operation will be set to long lived. Otherwise, operation will terminate when the local app is no longer running.
    func setLongLived(_ op: CKModifyRecordsOperation, to value: Bool) {
        if #available(iOS 11.0, *) {
            op.configuration.isLongLived = value
        } else {
            op.isLongLived = value
        }
    }
    
    /// This void method passes the completion block down to the last operation and provide local cache clean up. After cloud is updated, this will notify all local receivers, then run passed down completion handling.
    ///
    /// - Warning: Any operation passed should have only saves or deletions, or else only deletion clean up will occur.
    ///
    /// - Parameter op: The operation whose completion block needs to be passed down, and then whose activity needs to be cleaned up.
    func setCompletion(_ op: Operation) {
        let block = completionBlock
        op.completionBlock = self.specialCompletion(containing: block)
        completionBlock = nil
    }
}

extension OperationDecorator where Self: Operation & MCDatabaseModifier {

    // MARK: - Functions
    
    /// This method configures a `CKModifyRecordsOperation` with settings, appropriate completion blocks and name.
    ///
    /// - Parameter op: The operation to be configured for database modification.
    func setupModifier(_ op: CKModifyRecordsOperation) {
        op.modifyRecordsCompletionBlock = modifyCompletion
        op.savePolicy = .changedKeys

        setLongLived(op, to: true)
        setCompletion(op)
    }
}

extension OperationDecorator where Self: Operation & MCDatabaseQuerier & MCCloudErrorHandler {
    
    /// This method configures a `CKQueryOperation` with settings, appropriate completion blocks and name.
    ///
    /// - Parameter op: The operation to be configured for database query.
    func setupQuerier(_ op: CKQueryOperation) {
        if let integer = limit { op.resultsLimit = integer }
        if database.scope == MCDatabase.privateDB.scope { op.zoneID = CKRecordZone.default().zoneID }
        
        op.recordFetchedBlock = recordFetched()
        op.queryCompletionBlock = queryCompletion(op: op)
        
        setCompletion(op)
    }
}


