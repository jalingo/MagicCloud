//
//  UserRecordRetriever.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol UserRecordRetriever: AnyObject, UserRecordErrorHandler {
    
    /// This optional property stores USER recordID after it is recovered.
    var id: CKRecordID? { get set }
}

extension UserRecordRetriever {
    
    /// This method fetches the current USER recordID and stores it in 'id' property.
    func retrieveUserRecord() {
        CKContainer.default().fetchUserRecordID { possibleID, possibleError in
            if let error = possibleError as? CKError {
                self.handle(error)
            } else {
                if let id = possibleID {self.id = id }
                self.group.leave()
            }
        }
    }
}
