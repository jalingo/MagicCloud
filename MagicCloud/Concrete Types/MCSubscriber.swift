//
//  ListenFor.swift
//  MagicCloud
//
//  Created by James Lingo on 11/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/// This public class handles Magic Cloud's CKQuerySubscriptions, allowing for receivers to be listen for changes while handling any errors that might arise.
public class MCSubscriber: SubscriptionErrorHandler {

    // MARK: - Properties
    
    // MARK: - Properties: RemoteSubscriber
    
    /// This property references CKQuerSubscription being decorated and registered by class.
    var subscription: CKQuerySubscription
    
    /// This read-only, constant property stores database that subscription will register with (pub / priv).
    let database: MCDatabase
    
    // MARK: - Functions
    
    // MARK: - Functions: Constructors
    
    /**
        This public class handles Magic Cloud's CKQuerySubscriptions, allowing for receivers to be listen for changes while handling any errors that might arise (does NOT currently work with generic error handling).
     
        - Parameters:
            - type: CKRecord.recordType that subscription listens for changes with.
            - triggers: CKQuerySubscriptionOptions for subscription.
            - db: DatabaseType for subscription to be registered to.
     */
    public init(forRecordType type: String,
                withConditions triggers: CKQuerySubscriptionOptions = [.firesOnRecordUpdate, .firesOnRecordDeletion, .firesOnRecordCreation],
                on db: MCDatabase = .publicDB) {
        
        let predicate = NSPredicate(value: true)
        self.subscription = CKQuerySubscription(recordType: type, predicate: predicate, options: triggers)
        
        let info = CKNotificationInfo()
        info.alertLocalizationKey = type
        subscription.notificationInfo = info                                // <-- Passes record type for local notification.
        
        subscription.notificationInfo?.shouldSendContentAvailable = true    // <-- Required for background notifications.
        
        database = db
    }
}
