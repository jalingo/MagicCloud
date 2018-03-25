//
//  SubscriptionErrorHandler.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol SubscriptionErrorHandler: MCRetrier, SubscriptionLauncher, SubscriptionReattempter, SubscriptionReplacer, SubscriptionReducer {
    
    /// This read-only, computed property returns delegate's database type, or publicDB if delegate is nil.
    var database: MCDatabase { get }
}

extension SubscriptionErrorHandler {
    
    /**
     This function handles CKErrors resulting from failed subscription attempts.
     
     - Parameters:
     - error: The CKError generated by subscription, which requires handling.
     - isSubscribing: This argument is true when subscription is registering, false when unregistering.
     - id: The subscriptionID of subscription generating error, defaults nil. When nil, assumes error is coming from delegate's subscription.
     */
    func handle(_ error: CKError, whileSubscribing isSubscribing: Bool, to id: String? = nil) {
        
        // Subscription already exists.
        guard error.code != CKError.Code.serverRejectedRequest else {
            subscriptionAlreadyExists(retryAfter: error.retryAfterSeconds)
            return
        }
        
        if retriableErrors.contains(error.code), let duration = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            let q = DispatchQueue(label: retriableLabel)
            q.asyncAfter(deadline: .now() + duration) {
                isSubscribing ? self.start() : self.end(subscriptionID: id)
            }
        } else {
            // if not handled...
            let name = Notification.Name(MCErrorNotification)
            NotificationCenter.default.post(name: name, object: error)
        }
    }
    
    /**
     This void method deals with errors resulting from subscription type already existing in the database.
     
     - Parameter retryAfter: If nil, retries are immediate. Else, double is number of seconds retry is delayed.
     */
    fileprivate func subscriptionAlreadyExists(retryAfter: Double?) {
        database.db.fetchAllSubscriptions { possibleSubscriptions, possibleError in
            
            // identify existing subscription...
            if let subs = possibleSubscriptions {
                switch subs.count {
                case 0:
                    self.attemptCreateSubscriptionAgain(after: retryAfter)
                case 1:
                    self.replaceSubscription(with: subs.first)
                default:
                    self.leaveOnlyFirstSubscription(in: subs)
                }
            }
        }
    }
}