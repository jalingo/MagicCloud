//
//  MCCloudErrorHandler.swift
//  MagicCloud
//
//  Created by James Lingo on 3/20/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Protocol

/// Types conforming to this protocol can call the `handle:error:from:whileIgnoringUnknownItem` method and resolve cloud errors.
protocol MCCloudErrorHandler: MCDatabaseOperation { }

// MARK: - Extension

extension MCCloudErrorHandler {
    
    // MARK: - Functions

    /// This method handles errors from `CKModifyRecordsOperation` with MagicCloud framework.
    /// !!
    /// - Parameter receiver: The local mirror that operation will match up to the cloud database.
    func handle<U: MCMirrorAbstraction>(_ error: Error?, in op: Operation, with recordables: [U.type], from receiver: U, whileIgnoringUnknownItem: Bool, ignoreUnknownAction: OptionalClosure = nil) {
        if let cloudError = error as? CKError {
            let errorHandler = MCErrorHandler(error: cloudError,
                                              originating: op,
                                              target: database, instances: recordables,
                                              receiver: receiver)
            errorHandler.ignoreUnknownItem = whileIgnoringUnknownItem
            errorHandler.ignoreUnknownItemCustomAction = ignoreUnknownAction

            OperationQueue().addOperation(errorHandler)
        } else {
            print("NSError: \(String(describing: error?.localizedDescription)) @ MCCloudErrorHandler::\(String(describing: op.name))")
        }
    }
}
