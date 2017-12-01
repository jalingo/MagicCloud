//
//  GetUserRecord.swift
//  MagicCloud
//
//  Created by James Lingo on 11/18/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

/// This globally available MagicCloud method returns the CKRecordID associated with the current user.
public func getCurrentUserRecord() -> CKRecordID? {
    var result: CKRecordID?
    
    let group = DispatchGroup()
    group.enter()
    
    CKContainer.default().fetchUserRecordID { possibleID, possibleError in
        if let error = possibleError as? CKError {
            let name = Notification.Name(MCNotification.error.toString())
            NotificationCenter.default.post(name: name, object: error)
        }
        
        if let id = possibleID { result = id }
        group.leave()
    }
    
    group.wait()
    return result
}

/// This struct contains a static var (singleton) which accesses USER's iCloud CKRecordID.
public struct MCUserRecord {
    
    /**
        This read-only, computed property should be called async from main thread because it calls to remote database before returning value. If successful returns the User's CloudKit CKRecordID, otherwise returns nil.
     */
    static var singleton: CKRecordID? {
        var result: CKRecordID?

        let group = DispatchGroup()
        group.enter()
        
        CKContainer.default().fetchUserRecordID { possibleID, possibleError in
            if let error = possibleError as? CKError { MCFetchRecordIDError.handle(error) }
            if let id = possibleID { result = id }
            group.leave()
        }
        
        group.wait()
        return result
    }
}

public struct MCFetchRecordIDError {
    
    static func handle(_ error: CKError) {

        // If not handled...
        let name = Notification.Name(MCNotification.error.toString())
        NotificationCenter.default.post(name: name, object: error)
    }
}
