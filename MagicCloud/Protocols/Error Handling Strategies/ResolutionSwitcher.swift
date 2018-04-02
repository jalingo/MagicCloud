//
//  ResolutionSwitcher.swift
//  MagicCloud
//
//  Created by James Lingo on 3/26/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types conforming to the protocol can call the generic `resolve:error:in:from:to:withPolicy:whileIgnoringUnknowns:unknownCustomAction` method that selects resolution strategy based on error code and then executes said resolution.
protocol ResolutionSwitcher: RetriableErrorResolver, BatchErrorResolver, VersionConflictResolver { }

extension ResolutionSwitcher where Self: Operation & MCDatabaseModifier {
    
    /// This generic method selects resolution strategy based on error code and then executes said resolution.
    ///
    /// - Parameters:
    ///     - error: The cloud error that needs to be resolved.
    ///     - originatingOp: The operation that generated the error, and (if needed) this operation will be copied and relaunched.
    ///     - recordables: This array contains the recordables that were being manipulated when the error occured. Use an empty array if fetching or querying when operation failed.
    ///     - receiver: This is the instance of the associated `MCMirrorAbstraction` and may be interacted with during error resolution.
    ///     - database: This argument enumerates the scope of the database being interacted with when error was thrown.
    ///     - conflictingResolutionPolicy: The conflict resolution policy for error handling to follow.
    ///     - ignoreUnknownItem: When true, the method will disregard errors that resulted from an expected record being found. This would be useful if making a query where there may or may not be results. If false, unknown item situations will be resolved normally.
    ///     - ignoreUnknownItemCustomAction: When not nil, this closure will be executed if an unknown item situation occurs. If set, `ignoreUnknownItem` will be treated as true, regardless of passed argument.
    func resolve<R: MCMirrorAbstraction>(_ error: CKError, in originatingOp: Operation, with recordables: [R.type], from receiver: R, to database: MCDatabase, withPolicy conflictResolutionPolicy: CKRecordSavePolicy, whileIgnoringUnknowns ignoreUnknownItem: Bool, unknownCustomAction ignoreUnknownItemCustomAction: OptionalClosure = nil) {
        
        switch error.code {
            
        // This error occurs when record's change tag indicates a version conflict (modify operations).
        case .serverRecordChanged: resolveVersionConflict(error, accordingTo: conflictResolutionPolicy)

        // These errors occur when a batch of requests fails or partially fails (batch operations).
        case .limitExceeded, .batchRequestFailed, .partialFailure: resolveBatch(error, in: originatingOp)
            
        // These errors occur as a result of environmental factors, and originating operation should be retried after a set amount of time.
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy: resolveRetriable(error, in: originatingOp)
            
        // These errors occur when CloudKit has a problem with a CKSharedDatabase operation.    // <-- Not currently supported but left here as a reminder for future versions.
//        case .alreadyShared, .tooManyParticipants:
            
        // This case allows .unknownItem to be ignored (query / fetch / modify operations).
        case .unknownItem where ignoreUnknownItem: if let block = ignoreUnknownItemCustomAction { block() }
            
        // These fatal errors do not require any further handling.
        default: break
        }
    }
}
