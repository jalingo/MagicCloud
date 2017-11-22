//
//  ListenFor.swift
//  MagicCloud
//
//  Created by James Lingo on 11/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit
import UserNotifications

/**
    This strategy creates a subscription that listens for injected change of record type at database and allows consequence.
 
    - Note: CKNotificationInfo is standardized, but includes a CKRecordID with push notification.
 
    - Parameters:
        - for: CKRecord.recordType that subscription listens for changes with.
        - change: CKQuerySubscriptionOptions for subscription.
        - database: DatabaseType for subscription to be saved to.
        - count: Number of retries left for error handling (cannot be set higher than 3).
        - followUp: Completion Block that executes after subscription saved to the database.
 */
public func setupListener(for type: String,
                          change trigger: CKQuerySubscriptionOptions,
                          at database: DatabaseType = .publicDB,
                          withTries count: Int = 2,
                          consequence followUp: OptionalClosure = nil) -> String {
    let left: Int
    count < 2 ? (left = count - 1) : (left = 2)
    
    // Create subscription
    let predicate = NSPredicate(value: true)
    let subsciption = CKQuerySubscription(recordType: type, predicate: predicate, options: trigger)
    subsciption.notificationInfo = CKNotificationInfo()
    
    // Saves the subscription to database
    database.db.save(subsciption) { _, possibleError in
print("** listener save operation completing")
        if let error = possibleError as? CKError {
print("** not successful \(error.code.rawValue) - \(error)")
            
            guard error.code != CKError.Code.serverRejectedRequest else {
                disableListener(subscriptionID: subsciption.subscriptionID, at: database)
                return
            }
            
            // if not handled...
            NotificationCenter.default.post(name: MCNotification.subscription, object: error)
            
            // Prevents infinite retries...
            guard left > 0 else { return }
            
            // TODO: depending on error type and count retry
            let _ = setupListener(for: type,
                                  change: trigger,
                                  at: database,
                                  withTries: left,
                                  consequence: followUp)
        } else {
            if let action = followUp { action() }
        }
    }
    
    return subsciption.subscriptionID
}

// !!
public func disableListener(subscriptionID id: String,
                            withTries count: Int = 2,
                            at database: DatabaseType = .publicDB) {
    let left: Int
    count < 2 ? (left = count - 1) : (left = 2)

    database.db.delete(withSubscriptionID: id) { possibleID, possibleError in
print("** disabling subscription")
        if let error = possibleError {
print("** error disabling: \(error)")
            NotificationCenter.default.post(name: MCNotification.subscription, object: error)
            
            // Prevents infinite retries...
            guard left > 0 else { return }
            
            disableListener(subscriptionID: id, withTries: left, at: database)
        }
    }
}
