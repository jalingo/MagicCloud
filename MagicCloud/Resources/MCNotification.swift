//
//  CloudNotification.swift
//  slBackend
//
//  Created by James Lingo on 11/12/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

public enum MCNotification {
    case error(CKError), changeAt(DatabaseType)
    
    public func toString() -> String {
        switch self {
        case .error(let error): return "CLOUD_ERROR_\(error.errorCode)"
        case .changeAt(let db): return "\(db.db.databaseScope)_CHANGED"
        }
    }
}


/// These notifications are launched at various stages of error handling, and allow for additional implementation.
public struct _MCNotification {
    
    // MARK: - Properties: Static Constants
    
    /// Notification.Name for an error registering a CKQuerySubscription.
    public static let subscription = Notification.Name("CLOUD_ERROR_SUBSCRIPTION")
    
    /**
        Notification.Name for an error recovering USER's unique iCloud identity token.
     
        - Note: User should be notified and instructed to login to their iCloud account.
     */
    public static let cloudIdentity = Notification.Name("CLOUD_ERROR_IDENTITY")
    
    /// Notification.Name for any CKError detected
    public static let cloudError = Notification.Name("CLOUD_ERROR_OCCURED")    // <-- Deprecate?
    
    /// Notification.Name for CKError.notAuthenticated
    public static let notAuthenticated = Notification.Name("CLOUD_ERROR_NOT_AUTHENTICATED")
    
    /// Notification.Name for CKError.serverRecordChanged
    public static let serverRecordChanged = Notification.Name("CLOUD_ERROR_CHANGED_RECORD")
    
    /**
        Notification.Name for CKError.limitExceeded, CKError.batchRequestFailed,
        CKError.partialFailure...
     */
    public static let batchIssue = Notification.Name("CLOUD_ERROR_BATCH_ISSUE")
    
        /// Notification.Name for CKError.limitExceeded
        public static let limitExceeded = Notification.Name("CLOUD_ERROR_LIMIT_EXCEEDED")

        /// Notification.Name for CKError.batchRequestFailed
        public static let batchRequestFailed = Notification.Name("CLOUD_ERROR_BATCH_REQUEST")
    
        /// Notification.Name for CKError.partialFailure
        public static let partialFailure = Notification.Name("CLOUD_ERROR_PARTIAL_FAILURE")
    
    /**
        Notification.Name for CKError.networkUnavailable, CKError.networkFailure,
        CKError.serviceUnavailable, CKError.requestRateLimited, CKError.zoneBusy,
        CKError.resultsTruncated...
     */
    public static let retriable = Notification.Name("CLOUD_ERROR_RETRIABLE")
    
    /**
        Notification.Name for CKError.assetFileModified, CKError.serverRejectedRequest,
        CKError.assteFileNotFound, CKError.badContainer, CKError.serverResponseLost,
        CKError.changeTokenExpired, CKError.constraintViolation, CKError.internalError,
        CKError.incompatibleVersion, CKError.invalidArguments, CKError.quotaExceeded
        CKError.managedAccountRestricted, CKError.participantMayNeedVerification,
        CKError.operationCancelled, CKError.missingEntitlement, CKError.badDatabase,
        CKError.permissionFailure, CKError.referenceViolation, CKError.unknownItem,
        CKError.userDeletedZone, CKError.zoneNotFound...
     */
    public static let fatalError = NSNotification.Name("CLOUD_ERROR_FATAL")

    /**
        Notification.Name for CKError.alreadyShared, CKError.tooManyParticipants,
     */
    public static let sharingError = NSNotification.Name("CLOUD_ERROR_SHARING")
}
