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
protocol OperationDecorator {
    
    /// This method returns a fully configured Operation, ready to be launched.
    func decorate() -> Operation
}

// MARK: - Extension

extension OperationDecorator where Self: Operation & MCDatabaseModifier & SpecialCompleter {

    // MARK: - Functions
    
    /// !!
    func uniformSetup(_ op: CKModifyRecordsOperation) {
        op.modifyRecordsCompletionBlock = modifyCompletion
        op.savePolicy = .changedKeys
        setLongLived(op)
        setCompletion(op)
    }
    
    /// !!
    fileprivate func setLongLived(_ op: CKModifyRecordsOperation) {
        if #available(iOS 11.0, *) {
            op.configuration.isLongLived = true
        } else {
            op.isLongLived = true
        }
    }
    
    /// This void method passes the completion block down to the last operation and provide local cache clean up. After cloud is updated, this will notify all local receivers, then run passed down completion handling.
    /// - Warning: Any operation passed should have only saves or deletions, or else only deletion clean up will occur.
    /// - Parameter op: The operation whose completion block needs to be passed down, and then whose activity needs to be cleaned up.
    func setCompletion(_ op: CKModifyRecordsOperation) {
        let block = completionBlock
        op.completionBlock = self.specialCompletion(containing: block)
        completionBlock = nil
    }
}
