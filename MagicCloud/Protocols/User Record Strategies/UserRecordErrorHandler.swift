//
//  UserRecordErrorHandler.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol UserRecordErrorHandler: MCRetrier {
    
    /// This property is used to hold singleton delivery until recordID is fetched.
    var group: DispatchGroup { get }
}

extension UserRecordErrorHandler where Self: UserRecordRetriever {
 
    /// This method handles any errors during the record fetch operation.
    /// - Parameter error: The CKError that needs to be handled.
    func handle(_ error: CKError) {
        if retriableErrors.contains(error.code),
            let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            let queue = DispatchQueue(label: retriableLabel)
            queue.asyncAfter(deadline: .now() + retryAfterValue) { self.retrieveUserRecord() }
        } else {
            
            // Fatal Errors...
            let name = Notification.Name(MCErrorNotification)
            NotificationCenter.default.post(name: name, object: error)
            
            self.group.leave()
        }
    }
}
