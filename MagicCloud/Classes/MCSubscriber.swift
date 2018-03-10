//
//  ListenFor.swift
//  MagicCloud
//
//  Created by James Lingo on 11/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/// This public class handles Magic Cloud's CKQuerySubscriptions, allowing for receivers to be listen for changes while handling any errors that might arise (does NOT currently work with generic error handling).
public class MCSubscriber {

    // MARK: - Properties
    
    /// This property references CKQuerSubscription being decorated and registered by class.
    var subscription: CKQuerySubscription
    
    /// This read-only, constant property stores database that subscription will register with (pub / priv).
    let database: MCDatabase

    /// This read-only, computed property returns a subsctiption error handler using self as delegate.
    var subscriptionError: MCSubscriberError { return MCSubscriberError(delegate: self) }
    
    // MARK: - Functions
    
    /**
        This method creates a subscription that listens for injected change of record type at database and allows consequence.
     
        - Note: Each MCSubscriber manages a single subscription. For multiple subscriptions use different MCSubscribers.
     */
    func start() {
        // Saves the subscription to database
        database.defaultDB.save(self.subscription) { possibleSubscription, possibleError in
            if let error = possibleError as? CKError { self.subscriptionError.handle(error, whileSubscribing: true) }
        }
    }
    
    /**
        This method unregisters either this class's subscription property or another subscription matching supplied identifier.
     
        - Parameter subscriptionID: An optional (defaults nil) string identifier to match against CKQuerySubscription.subscriptionID. If nil, id from subscription property used instead.
     */
    func end(subscriptionID: String? = nil) {
        // This loads id with either parameter or self.subscription's id
        let id = subscriptionID ?? subscription.subscriptionID

        database.defaultDB.delete(withSubscriptionID: id) { possibleID, possibleError in
            if let error = possibleError as? CKError {
                self.subscriptionError.handle(error, whileSubscribing: false, to: subscriptionID)
            }
        }
    }
    
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
