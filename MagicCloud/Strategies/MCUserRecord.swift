//
//  GetUserRecord.swift
//  MagicCloud
//
//  Created by James Lingo on 11/18/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Class

/// This struct contains a static var (singleton) which accesses USER's iCloud CKRecordID.
public class MCUserRecord {
    
    // MARK: - Properties
    
    /// This property is used to hold singleton delivery until recordID is fetched.
    fileprivate let group = DispatchGroup()

    /// This optional property stores USER recordID after it is recovered.
    fileprivate var id: CKRecordID?
    
    /**
        This read-only, computed property should be called async from main thread because it calls to remote database before returning value. If successful returns the User's CloudKit CKRecordID, otherwise returns nil.
     */
    var singleton: CKRecordID? {
        group.enter()

        retrieveUserRecord()
        
        group.wait()
        return id
    }
    
    // MARK: - Functions
    
    /// This method handles any errors during the record fetch operation.
    fileprivate func handle(_ error: CKError) {

        // These errors occur as a result of environmental factors, and originating operation should be retried after a set amount of time.
        let retriableErrors: [CKError.Code] = [.networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy]
        if retriableErrors.contains(error.code), let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            let queue = DispatchQueue(label: "RetryAttemptQueue")
            queue.asyncAfter(deadline: .now() + retryAfterValue) { self.retrieveUserRecord() }
        } else {
            
            // Fatal Errors...
            let name = Notification.Name(MCNotification.error.toString())
            NotificationCenter.default.post(name: name, object: error)
            
            self.group.leave()
        }
    }
    
    /// This method fetches the current USER recordID and stores it in 'id' property.
    fileprivate func retrieveUserRecord() {
        CKContainer.default().fetchUserRecordID { possibleID, possibleError in
            if let error = possibleError as? CKError {
                self.handle(error)
            } else {
                if let id = possibleID { self.id = id }
                self.group.leave()
            }
        }
    }
}
