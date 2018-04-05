//
//  SubscriptionLauncher.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol SubscriptionLauncher: AnyObject {
    
    /// This property references CKQuerSubscription being decorated and registered by class.
    var subscription: CKQuerySubscription { get set }
    
    /// This read-only, constant property stores database that subscription will register with (pub / priv).
    var database: MCDatabase { get }
    
    /// This read-only, computed property returns a subsctiption error handler using self as delegate.
//    var subscriptionError: MCSubscriberError { get }
}

extension SubscriptionLauncher where Self: SubscriptionErrorHandler {
    
    /**
     This method creates a subscription that listens for injected change of record type at database and allows consequence.
     
     - Note: Each MCSubscriber manages a single subscription. For multiple subscriptions use different MCSubscribers.
     */
    func start() {
        // Saves the subscription to database
        database.db.save(self.subscription) { possibleSubscription, possibleError in
            if let error = possibleError as? CKError { self.handle(error, whileSubscribing: true) }
        }
    }
    
    /**
     This method unregisters either this class's subscription property or another subscription matching supplied identifier.
     
     - Parameter subscriptionID: An optional (defaults nil) string identifier to match against CKQuerySubscription.subscriptionID. If nil, id from subscription property used instead.
     */
    func end(subscriptionID: String? = nil) {
        // This loads id with either parameter or self.subscription's id
        let id = subscriptionID ?? subscription.subscriptionID
        
        database.db.delete(withSubscriptionID: id) { possibleID, possibleError in
            if let error = possibleError as? CKError {
                self.handle(error, whileSubscribing: false, to: subscriptionID)
            }
        }
    }
}
