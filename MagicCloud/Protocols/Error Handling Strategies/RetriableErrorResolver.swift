//
//  RetriableErrorResolver.swift
//  MagicCloud
//
//  Created by James Lingo on 3/27/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types conforming to this protocol can call the `resolveRetriable:error:in` method that retries error codes that provide a retry after value.
protocol RetriableErrorResolver: MCRetrier { }

extension RetriableErrorResolver where Self: MCRecordableReceiver {
    
    /// This void method retries error codes that provide a retry after value.
    /// !!
    func resolveRetriable(_ error: CKError, in originatingOp: Operation) {
        guard let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval else { return }

        let q = DispatchQueue(label: retriableLabel)
        if let op = replicate(originatingOp, with: receiver) {
            q.asyncAfter(deadline: .now() + retryAfterValue) {
                if let cloudOp = op as? CKDatabaseOperation {
                    self.database.db.add(cloudOp)
                } else {
                    OperationQueue().addOperation(op)
                }
            }
        }
    }
}
