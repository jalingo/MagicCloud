//
//  SubscriptionReducer.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol SubscriptionReducer { }

extension SubscriptionReducer where Self: SubscriptionErrorHandler {
    
    /**
     This void method removes all but one subscription of the same type.
     
     - Parameter subs: An array of subscriptions that need to be unregistered, save one.
     */
    func leaveOnlyFirstSubscription(in subs: [CKSubscription]) {
        var isNotFirst = false
        for sub in subs {
            if let subscription = sub as? CKQuerySubscription,
                subscription.recordType == self.subscription.recordType,
                subscription.querySubscriptionOptions == self.subscription.querySubscriptionOptions {
                
                // delete the subscription...
                isNotFirst ? (self.end(subscriptionID: subscription.subscriptionID)) : (self.replaceSubscription(with: subscription))
                isNotFirst = true
            }
        }
    }
}
