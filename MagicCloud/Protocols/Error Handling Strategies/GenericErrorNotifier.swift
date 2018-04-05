//
//  GenericErrorNotifier.swift
//  MagicCloud
//
//  Created by James Lingo on 3/26/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Global Constant

/// This string key ("CLOUD_KIT_ERROR"), is used as a name to listen for during error handling. When observed, attached object is an optional CKError value.
public let MCErrorNotification = "CLOUD_KIT_ERROR"

// MARK: - Protocol

/// Types conforming to this protocol can call the `notifyExternalAccessors` method that posts a notification when injected error shouldn't be ignored or isn't partial failure.
protocol GenericErrorNotifier {
    
    /// This is the error that needs to be handled by this operation.
    var error: CKError { get }
    
    /// This is the operation that was running when error was generated.
    var originatingOp: Operation { get }
    
    /// Skips over any error handling for `.unknownItem` errors, except `ignoreUnknownItemCustomAction`.
    var ignoreUnknownItem: Bool { get set }
}

// MARK: - Extension

extension GenericErrorNotifier {
    
    /// This void method posts a notification when injected error shouldn't be ignored or isn't partial failure.
    func notifyExternalAccessors() {
        if !(error.code == .unknownItem && ignoreUnknownItem) || !(error.code == .partialFailure) {
            let name = Notification.Name(MCErrorNotification)
            NotificationCenter.default.post(name: name, object: error)
        }
    }
}
