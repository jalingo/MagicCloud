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
    
    fileprivate var id: String?
    
    // MARK: - Functions
    
    /**
     This strategy creates a subscription that listens for injected change of record type at database and allows consequence.
     
     - Note: CKNotificationInfo is standardized, but includes a CKRecordID with push notification.
     
     - Parameters:
     - for: CKRecord.recordType that subscription listens for changes with.
     - change: CKQuerySubscriptionOptions for subscription.
     - database: DatabaseType for subscription to be saved to.
     */
    func start(for type: String, change trigger: CKQuerySubscriptionOptions, at database: DatabaseType = .publicDB) {
        
        // Create subscription
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: type, predicate: predicate, options: trigger)
        
        // TODO insert local notification into userInfo here
//        subscription.subscriptionID = MCNotification.changeNoticed(forType: type, at: database).toString()
        subscription.notificationInfo = CKNotificationInfo()
        
        // Saves the subscription to database
        database.db.save(subscription) { possibleSubscription, possibleError in
print("** listener save operation completing")
            if let error = possibleError as? CKError {
                guard error.code != CKError.Code.serverRejectedRequest else {
print("** subscription already exists")
                    return }
                
                guard error.code != CKError.Code.networkFailure else {
print("** DING!")
                    guard let duration = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval else { return }
                    let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { _ in
                        self.start(for: type, change: trigger, at: database)
                    })
                    
                    timer.fire()
                    return
                }
print("** not successful \(error.code.rawValue) - \(error)")
                // if not handled...
                let name = Notification.Name(MCNotification.error(error).toString())
                NotificationCenter.default.post(name: name, object: error)
            }
        }
        
        id = subscription.subscriptionID
    }
    
    // !!
    func end(subscriptionID: String? = nil, at database: DatabaseType = .publicDB) {
        // TODO: Not Working !!
print("** ending subscription")
        // This loads id with either subscriptionID, self.id, or exits if both are nil.
        guard let id = subscriptionID ?? id else { return }

        database.db.delete(withSubscriptionID: id) { possibleID, possibleError in
print("** disabling subscription \(String(describing: possibleID))")
            if let error = possibleError as? CKError {
print("** error disabling: \(error)")
                let name = Notification.Name(MCNotification.error(error).toString())
                NotificationCenter.default.post(name: name, object: error)
            }
        }
    }
    
    public init() { }   // <-- Makes initializer accessible to public
}
