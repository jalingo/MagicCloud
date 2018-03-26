//
//  BatchErrorResolver.swift
//  MagicCloud
//
//  Created by James Lingo on 3/26/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types conforming to this protocol can call the `resolveBatch:error:in` method that identifies the type of error thrown by batch and handles it.
protocol BatchErrorResolver: BatchSplitter, PartialErrorResolver { }

extension BatchErrorResolver where Self: MCDatabaseModifier {
    
    /// This void method identifies the type of error thrown by batch and handles it.
    ///
    /// - Parameter error: The cloud error that needs to be resolved.
    /// - Parameter op: The operation that generated the error, and (if needed) this operation will be copied and relaunched.
    func resolveBatch(_ error: CKError, in operation: Operation) {
        
        // !! This notification is required for tests and is in addition to more specific notification
        let name = Notification.Name(MCErrorNotification)
        NotificationCenter.default.post(name: name, object: error)
        
        switch error.code {
        case .partialFailure: resolvePartial(error, in: operation)
        case .limitExceeded:  splitBatch(error: error, in: operation)
        default: break  // .batchRequestFailed is fatal error, and all other errors should not be here.
        }
    }
}

extension BatchErrorResolver where Self: MCDatabaseQuerier {
    
    /// This void method identifies the type of error thrown by batch and handles it.
    ///
    /// - Parameter error: The cloud error that needs to be resolved.
    /// - Parameter op: The operation that generated the error, and (if needed) this operation will be copied and relaunched.
    func resolveBatch(_ error: CKError, in operation: Operation) {
        
        // !! This notification is required for tests and is in addition to more specific notification
        let name = Notification.Name(MCErrorNotification)
        NotificationCenter.default.post(name: name, object: error)
        
        // MCDatabaseQuerier should never actually trigger batch errors (recordables is empty).
        if error.code == .partialFailure { resolvePartial(error, in: operation) }
    }
}
