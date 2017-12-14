//
//  ListenFor.swift
//  MagicCloud
//
//  Created by James Lingo on 11/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit
import UserNotifications

//!!
public class MCSubscriber {

    // MARK: - Properties
    
    let subscription: CKQuerySubscription
    
    let database: MCDatabase
    
    var subscriptionError: MCSubscriberError { return MCSubscriberError(delegate: self) }
    
    // MARK: - Functions
    
    /**
        This method creates a subscription that listens for injected change of record type at database and allows consequence.
        - Note: Each MCSubscriber manages a single subscription. For multiple subscriptions use different MCSubscribers.
     */
    func start() {
        
        // Saves the subscription to database
        database.db.save(self.subscription) { possibleSubscription, possibleError in
            if let error = possibleError as? CKError {
                self.subscriptionError.handle(error, whileSubscribing: true)
            }
        }
    }
    
    // !!
    func end(subscriptionID: String? = nil) {
        // This loads id with either parameter or self.subscription's id
        let id = subscriptionID ?? subscription.subscriptionID

        database.db.delete(withSubscriptionID: id) { possibleID, possibleError in
            if let error = possibleError as? CKError {
                self.subscriptionError.handle(error, whileSubscribing: false, to: subscriptionID)
            }
        }
    }
    
    // MARK: - Functions: Constructors
    
    /**
        !!
     
        - Parameters:
            - type: CKRecord.recordType that subscription listens for changes with.
            - triggers: CKQuerySubscriptionOptions for subscription.
            - db: DatabaseType for subscription to be saved to.
     */
    public init(forRecordType type: String,
                withConditions triggers: CKQuerySubscriptionOptions = [.firesOnRecordUpdate, .firesOnRecordDeletion, .firesOnRecordCreation],
                on db: MCDatabase = .publicDB) {
        
        let predicate = NSPredicate(value: true)
        self.subscription = CKQuerySubscription(recordType: type, predicate: predicate, options: triggers)
        
        let info = CKNotificationInfo()
        info.alertLocalizationKey = type       // <-- Needs some form alert to be constructed or doesn't trigger. Avoid alertBody, soundName or shouldBadge
        subscription.notificationInfo = info       // This also passes record type for local notification.
        
        database = db
    }
}

struct MCSubscriberError: MCRetrier {
    
    var delegate: MCSubscriber?
    
    var database: MCDatabase { return delegate?.database ?? .publicDB }
    
    var recordType: String { return delegate?.subscription.recordType ?? "MockRecordable" }
    
    /// This function handles CKErrors resulting from failed subscription attempts.
    /// - Parameters: !!
    func handle(_ error: CKError, whileSubscribing isSubscribing: Bool, to id: String? = nil) {

        // Subscription already exists.
        guard error.code != CKError.Code.serverRejectedRequest else {
            subscriptionAlreadyExists(retryAfter: error.retryAfterSeconds)
            return
        }
        
        if retriableErrors.contains(error.code), let duration = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            let q = DispatchQueue(label: retriableLabel)
            q.asyncAfter(deadline: .now() + duration) {
                isSubscribing ? self.delegate?.start() : self.delegate?.end(subscriptionID: id)
            }
        } else {
            // if not handled...
            let name = Notification.Name(MCErrorNotification)
            NotificationCenter.default.post(name: name, object: error)
        }
        
    }
    
    func subscriptionAlreadyExists(retryAfter: Double?) {
        database.db.fetchAllSubscriptions { possibleSubscriptions, possibleError in
            
            // identify existing subscription...
            if let subs = possibleSubscriptions {
                var conflictingSubscriptionFound = false

                for sub in subs {
                    if let subscription = sub as? CKQuerySubscription {
                        //}, subscription == self.delegate?.subscription {

                        if subscription.recordType == self.delegate?.subscription.recordType,
                            subscription.querySubscriptionOptions == self.delegate?.subscription.querySubscriptionOptions {

                            // delete the subscription...
                            self.delegate?.end(subscriptionID: sub.subscriptionID)
                            conflictingSubscriptionFound = true
                        }
                    }
                }

                // try new subscription again...
                if conflictingSubscriptionFound {
                    let delay = retryAfter ?? 1
                    let q = DispatchQueue(label: self.retriableLabel)
                    q.asyncAfter(deadline: .now() + delay) { self.delegate?.start() }
                }
            }
        }
    }
}
