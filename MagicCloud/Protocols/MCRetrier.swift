//
//  MCRetrier.swift
//  MagicCloud
//
//  Created by James Lingo on 12/5/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

//!!
protocol MCRetrier: MCOperationReplicator {
    
    // !!
    var retriableErrors: [CKError.Code] { get }
    
    var retriableLabel: String { get }
}

extension MCRetrier {
    
    // These errors occur as a result of environmental factors, and originating operation should be retried after a set amount of time.
    var retriableErrors: [CKError.Code] {
        return [.networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy]
    }
    
    // !!
    var retriableLabel: String { return "RetryAttemptQueue" }
}
