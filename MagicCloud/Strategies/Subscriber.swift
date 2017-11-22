//
//  ListenFor.swift
//  MagicCloud
//
//  Created by James Lingo on 11/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit
import UserNotifications

public class Subscriber {

    // MARK: - Properties
    
    var id: String?
    
    // MARK: - Functions
    
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
    func start(for type: String, change trigger: CKQuerySubscriptionOptions, at database: DatabaseType = .publicDB) {
        
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
                    self.end(subscriptionID: subsciption.subscriptionID, at: database)
                    self.start(for: type,
                                           change: trigger,
                                           at: database,
                                           consequence: followUp)
                    return
                }
                
                // if not handled...
                NotificationCenter.default.post(name: MCNotification.error(error).toString(), object: error)
            }
        }
        
        id = subsciption.subscriptionID
    }
    
    // !!
    public func end(subscriptionID: String? = nil, at database: DatabaseType = .publicDB) {

        // This loads id with either subscriptionID, self.id, or exits if both are nil.
        guard let id = subscriptionID ?? id else { return }
        
        database.db.delete(withSubscriptionID: id) { possibleID, possibleError in
print("** disabling subscription")
            if let error = possibleError {
print("** error disabling: \(error)")
                NotificationCenter.default.post(name: MCNotification.subscription, object: error)
            }
        }
    }
}
