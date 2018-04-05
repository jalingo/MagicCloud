//
//  MCDatabaseModifier.swift
//  MagicCloud
//
//  Created by James Lingo on 3/20/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Protocol

/// Types conforming to this protocol have the properties needed to prepare and launch `CKModifyRecordsOperation` classes.
protocol MCDatabaseModifier: MCRecordableReceiver {
    
    /// This read-only property returns an array of the recordables that will be modified (added / edited / removed) in the cloud database.
    var recordables: [R.type] { get }
    
    /// This read-only, computed property returns a ModifyBlock for uploading with a CKModifyRecordsOperation.
    var modifyCompletion: ModifyBlock { get }
}

extension MCDatabaseModifier {
    
    /// This read-only, computed property returns an array of `CKRecord`s for each entry in `recordables` property.
    var records: [CKRecord] {
        var recs = [CKRecord]()
        
        // This loop converts recordables into CKRecord's for array
        for recordable in recordables {
            let rec = CKRecord(recordType: recordable.recordType, recordID: recordable.recordID)
            for entry in recordable.recordFields { rec[entry.key] = entry.value }
            recs.append(rec)
        }
        
        return recs
    }
    
    /// This read-only, computed property returns an array of `CKRecordID`s for each entry in `recordables` property.
    var recordIDs: [CKRecordID] {
        return recordables.map { $0.recordID }
    }
}

extension MCDatabaseModifier where Self: Operation & MCCloudErrorHandler {
    
    /// This read-only, computed property returns a ModifyBlock for uploading with a CKModifyRecordsOperation.
    var modifyCompletion: ModifyBlock {
        return { recs, ids, error in
            guard error == nil else { self.handle(error,
                                                  in: self,
                                                  whileIgnoringUnknownItem: false,
                                                  ignoreUnknownAction: nil); return }
        }
    }
}
