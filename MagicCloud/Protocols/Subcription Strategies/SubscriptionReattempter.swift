//
//  SubscriptionReattempter.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol SubscriptionReattempter { }

extension SubscriptionReattempter where Self: SubscriptionErrorHandler {
    
    /**
     This void method attempts to reregister subscription. Theoretically, would only trigger in the event that there are no same type subscriptions...but that should never occur. Maintained as a safety, but may be deprecated in the future.
     
     - Parameter retryAfter: If nil, retries are immediate. Else, double is number of seconds retry is delayed.
     */
    func attemptCreateSubscriptionAgain(after retryAfter: Double?) {
        print("MCSubscriber.attemptCreateSubscriptionAgain ...SHOULD NEVER TRIGGER")
        
        let delay = retryAfter ?? 1
        let q = DispatchQueue(label: self.retriableLabel)
        q.asyncAfter(deadline: .now() + delay) { self.start() }
    }
}
