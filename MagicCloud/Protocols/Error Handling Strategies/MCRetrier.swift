//
//  MCRetrier.swift
//  MagicCloud
//
//  Created by James Lingo on 12/5/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types that conform to MCRetrier have access to a collection of retriable errors and a queue label for retries.
protocol MCRetrier: MCOperationReplicator {

    /// This read-only, computed property returns a collection of errors that occur as a result of environmental factors, and originating operation should be retried after a set amount of time.
    var retriableErrors: [CKError.Code] { get }
    
    /// This read-only, computed property returns the label "RetryAttemptQueue" for dispatch queues used to retry.
    var retriableLabel: String { get }
}

extension MCRetrier {
    
    /// This read-only, computed property returns a collection of errors that occur as a result of environmental factors, and originating operation should be retried after a set amount of time.
    var retriableErrors: [CKError.Code] {
        return [.networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy]
    }
    
    /// This read-only, computed property returns the label "RetryAttemptQueue" for dispatch queues used to retry.
    var retriableLabel: String { return "RetryAttemptQueue" }
}
