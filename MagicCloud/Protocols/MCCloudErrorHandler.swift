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
protocol MCCloudErrorHandler { }

// MARK: - Extension

extension MCCloudErrorHandler {

    /// !!
    func handle<U: MCMirrorAbstraction>(_ error: Error?, in op: Operation, with recordables: [U.type], from receiver: U, to database: MCDatabase, whileIgnoringUnknownItem: Bool, ignoreUnknownAction: OptionalClosure = nil) {
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

extension MCCloudErrorHandler where Self: MCDatabaseModifier {
    
    // MARK: - Functions

    /// This method handles errors from `CKModifyRecordsOperation` with MagicCloud framework.
    /// !!
    /// - Parameter receiver: The local mirror that operation will match up to the cloud database.
    func handle(_ error: Error?, in op: Operation, whileIgnoringUnknownItem: Bool, ignoreUnknownAction: OptionalClosure = nil) {
        handle(error,
               in: op,
               with: self.recordables as [R.type],
               from: self.receiver,
               to: self.database,
               whileIgnoringUnknownItem: whileIgnoringUnknownItem,
               ignoreUnknownAction: ignoreUnknownAction)
    }
}

extension MCCloudErrorHandler where Self: MCDatabaseQuerier {
    
    /// !!
    func handle(_ error: Error?, in op: Operation) {
        handle(error,
               in: op,
               with: [],
               from: self.receiver,
               to: self.database,
               whileIgnoringUnknownItem: true,
               ignoreUnknownAction: self.unknownItemCustomAction)
    }
}
