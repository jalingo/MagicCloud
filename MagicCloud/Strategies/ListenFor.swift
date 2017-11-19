//
//  ListenFor.swift
//  MagicCloud
//
//  Created by James Lingo on 11/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/**
    This strategy creates a subscription that listens for injected change of record type at database and allows consequence.
 
    - Note: CKNotificationInfo is standardized, but includes a CKRecordID with push notification.
 
    - Parameters:
        - change type: CKRecord.recordType that subscription listens for changes with.
        - trigger: CKQuerySubscriptionOptions for subscription.
        - database: DatabaseType for subscription to be saved to.
        - count: Number of retries left for error handling (cannot be set higher than 3).
        - followUp: Completion Block that can be triggered when subscription is triggered.
 */
public func setupListener(notificationName: Notification.Name,
                          for type: String,
                          change trigger: CKQuerySubscriptionOptions,
                          at database: DatabaseType = .publicDB,
                          withTries count: Int = 3,
                          consequence followUp: OptionalClosure = nil) {
    let left: Int
    count < 3 ? (left = count) : (left = 3)
    
    // Create subscription
    let predicate = NSPredicate(value: true)
    let subsciption = CKQuerySubscription(recordType: type, predicate: predicate, options: trigger)
        
    // Saves the subscription to database
    database.db.save(subsciption) { _, possibleError in
        if let error = possibleError {
            NotificationCenter.default.post(name: notificationName, object: error)
            
            // Prevents infinite retries...
            guard left > 0 else { return }
            
            // TODO: depending on error type and count retry
            setupListener(notificationName: notificationName,
                          for: type,
                          change: trigger,
                          at: database,
                          withTries: left,
                          consequence: followUp)
        } else {
            if let action = followUp { action() }
        }
    }
}
