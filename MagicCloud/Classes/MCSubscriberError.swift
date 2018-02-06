//
//  MCSubscriberError.swift
//  MagicCloud
//
//  Created by James Lingo on 2/6/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// This struct contains error handling for CKQuerySubscriptions. Currently only supports MCSubscriber class.
struct MCSubscriberError: MCRetrier {
    
    // !!
    var delegate: MCSubscriber?
    
    // !!
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
            print("!! error not handled @ MCSubscriberError.handle #\(error.errorCode)")
        }
    }
    
    func subscriptionAlreadyExists(retryAfter: Double?) {
        database.db.fetchAllSubscriptions { possibleSubscriptions, possibleError in
            
            // identify existing subscription...
            if let subs = possibleSubscriptions {
                switch subs.count {
                case 0: self.attemptCreateSubscriptionAgain(after: retryAfter)
                case 1: break   // <-- Do NOTHING; leaves solitary subscription in place.
                default: self.leaveOnlyFirstSubscription(in: subs)
                }
            }
        }
    }
    
    func attemptCreateSubscriptionAgain(after retryAfter: Double?) {
        print("MCSubscriber.attemptCreateSubscriptionAgain ...SHOULD NEVER TRIGGER !!")
        let delay = retryAfter ?? 1
        let q = DispatchQueue(label: self.retriableLabel)
        q.asyncAfter(deadline: .now() + delay) { self.delegate?.start() }
    }
    
    func leaveOnlyFirstSubscription(in subs: [CKSubscription]) {
        var isNotFirst = false
        for sub in subs {
            if let subscription = sub as? CKQuerySubscription,
                subscription.recordType == self.delegate?.subscription.recordType,
                subscription.querySubscriptionOptions == self.delegate?.subscription.querySubscriptionOptions {
                //print("*- Sub found = \(subscription.recordType) / \(subscription.subscriptionID)")
                //print("*- Sub isNotFirst = \(isNotFirst)")
                // delete the subscription...
                isNotFirst ? (self.delegate?.end(subscriptionID: sub.subscriptionID)) : (isNotFirst = true)
            }
        }
    }
}
