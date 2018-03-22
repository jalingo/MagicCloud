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
protocol MCCloudErrorHandler {
 
    associatedtype U: MCMirrorAbstraction
    
    /// This read-only property returns the local mirror that operation will match up to the cloud database.
    var receiver: U { get }
    
    /// This method handles errors from CKModifyRecordsOperation with MagicCloud framework.
    func handle(_ error: Error?, from op: Operation, whileIgnoringUnknownItem: Bool)
}

// MARK: - Extension

extension MCCloudErrorHandler where Self: MCDatabaseModifier {
    
    // MARK: - Functions

    /// This method handles errors from CKModifyRecordsOperation with MagicCloud framework.
    func handle(_ error: Error?, from op: Operation, whileIgnoringUnknownItem: Bool) {
        if let cloudError = error as? CKError {
            let errorHandler = MCErrorHandler(error: cloudError,
                                              originating: op,
                                              target: database, instances: recordables as! [U.type],
                                              receiver: receiver)
            errorHandler.ignoreUnknownItem = whileIgnoringUnknownItem

            OperationQueue().addOperation(errorHandler)
        } else {
            print("NSError: \(String(describing: error?.localizedDescription)) @ MCCloudErrorHandler::\(String(describing: op.name))")
        }
    }
}

