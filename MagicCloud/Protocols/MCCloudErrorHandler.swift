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

    /// This generic method is associated with a type conforming to `MCMirrorAbstraction` protocol, and handles any cloud error passed along with environmental variables and configurations.
    ///
    /// - Parameters:
    ///     - error: The cloud error that needs to be resolved.
    ///     - op: The operation that generated the error, and (if needed) this operation will be copied and relaunched.
    ///     - recordables: This array contains the recordables that were being manipulated when the error occured. Use an empty array if fetching or querying when operation failed.
    ///     - receiver: This is the instance of the associated `MCMirrorAbstraction` and may be interacted with during error resolution.
    ///     - database: This argument enumerates the scope of the database being interacted with when error was thrown.
    ///     - whileIgnoringUnknownItem: When true, the method will disregard errors that resulted from an expected record being found. This would be useful if making a query where there may or may not be results. If false, unknown item situations will be resolved normally.
    ///     - ignoreUnknownAction: When not nil, this closure will be executed if an unknown item situation occurs. Usually this occurs instead of typical error handling, but `whileIgnoringUnknownItem` can be false when this is set, allowing for closure to be executed in addition to typical error handling.
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

    /// This convenience method wraps the `handle:_:in:with:from:to:whileIgnoringUnknownItem:ignoreUnknownAction` method for errors from `CKModifyRecordsOperation` with MagicCloud framework.
    ///
    /// - Parameters:
    ///     - error: The cloud error that needs to be resolved.
    ///     - op: The operation that generated the error, and (if needed) this operation will be copied and relaunched.
    ///     - whileIgnoringUnknownItem: When true, the method will disregard errors that resulted from an expected record being found. This would be useful if making a query where there may or may not be results. If false, unknown item situations will be resolved normally.
    ///     - ignoreUnknownAction: When not nil, this closure will be executed if an unknown item situation occurs. Usually this occurs instead of typical error handling, but `whileIgnoringUnknownItem` can be false when this is set, allowing for closure to be executed in addition to typical error handling.
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
    
    /// This convenience method wraps the `handle:_:in:with:from:to:whileIgnoringUnknownItem:ignoreUnknownAction` method for errors from `CKModifyRecordsOperation` with MagicCloud framework.
    ///
    /// - Parameters:
    ///     - error: The cloud error that needs to be resolved.
    ///     - op: The operation that generated the error, and (if needed) this operation will be copied and relaunched.
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
