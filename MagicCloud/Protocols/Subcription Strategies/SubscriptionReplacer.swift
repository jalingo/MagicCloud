//
//  SubscriptionReplacer.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol SubscriptionReplacer { }

extension SubscriptionReplacer where Self: SubscriptionErrorHandler {
    
    /// This void method replaces delegate?.subscription with passed argument cast as CKQuerySubscription.
    /// - Parameter sub: This argument is cast as CKQuerySubscription, and overwrites delegate?.subscription.
    func replaceSubscription(with sub: CKSubscription?) {
        if let subscription = sub as? CKQuerySubscription { self.subscription = subscription }
    }
}
