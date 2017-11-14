//
//  Duplicate.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/29/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import Foundation
import CloudKit

/// This function takes the originatingOp (which has already been spent) and creates a
/// a new version with the same property values and completion blocks.
func duplicate(_ op: Operation) -> Operation? {
    print("resetting: \(String(describing: op.name))")
    
    // Custom Operations
    
    if let failure = op as? FailedOp {
        return FailedOp(notify: failure.notification)
    }
    
    // Custom Recordable Operations
    
    if let uploader = op as? Upload {
        let new = Upload(uploader.recordables)
        
        new.completionBlock = uploader.completionBlock
        new.name = "\(String(describing: uploader.name))+"
        
        return new
    }
    
    if let uploader = op as? Upload.Modify {
        var database: Upload.Modify.DatabaseType
        
        switch uploader.db {
        case CKContainer.default().privateCloudDatabase: database = .privateDB
        case CKContainer.default().publicCloudDatabase: database = .publicDB
        case CKContainer.default().sharedCloudDatabase: database = .sharedDB
        default:
print("Error @ duplicate.uploader = Upload.Modify")
            database = .privateDB
        }
        
        let new = Upload.Modify(these: uploader.recordables, on: database)
        
        new.completionBlock = uploader.totalCompletion
        new.name = "\(String(describing: uploader.name))+"
        
        return new
    }
    
    if let deleter = op as? Delete {
        let new = Delete(deleter.recordables)
        
        new.delayInSeconds = deleter.delayInSeconds
        new.completionBlock = deleter.completionBlock
        new.name = "\(String(describing: deleter.name))+"

        return new
    }
    
    if let deleter = op as? Delete.Modify {
        let new = Delete.Modify(deleter.recordables, on: deleter.database)
        
        new.delay = deleter.delay
        new.completionBlock = deleter.savedForAsyncCompletion
        new.name = "\(String(describing: deleter.name))+"
        
        return new
    }
    
    if let downloader = op as? Download {
        let new = Download(type: downloader.query.recordType, to: downloader.reciever)
        
        new.query = downloader.query
        new.db = downloader.db
        new.ignoreUnknownItemCustomAction = downloader.ignoreUnknownItemCustomAction
        new.limit = downloader.limit
        new.completionBlock = downloader.completionBlock
        new.name = "\(String(describing: downloader.name))+"
        
        return new
    }
    
    // CKDatabaseOperations
    
    if let fetcher = op as? CKFetchRecordsOperation {
        guard let ids = fetcher.recordIDs else { return nil }
        
        let new = CKFetchRecordsOperation(recordIDs: ids)
        
        new.completionBlock = fetcher.completionBlock
        new.fetchRecordsCompletionBlock = fetcher.fetchRecordsCompletionBlock
        new.perRecordProgressBlock = fetcher.perRecordProgressBlock
        new.perRecordCompletionBlock = fetcher.perRecordCompletionBlock
        new.name = fetcher.name
        
        return new
    }
    
    if let modifier = op as? CKModifyRecordsOperation {
        
        let new = CKModifyRecordsOperation(recordsToSave: modifier.recordsToSave,
                                           recordIDsToDelete: modifier.recordIDsToDelete)
        new.completionBlock = modifier.completionBlock
        new.modifyRecordsCompletionBlock = modifier.modifyRecordsCompletionBlock
        new.perRecordCompletionBlock = modifier.perRecordCompletionBlock
        new.perRecordProgressBlock = modifier.perRecordProgressBlock
        new.name = modifier.name
        
        return new
    }
    
    if let querier = op as? CKQueryOperation {
        let new: CKQueryOperation

        if let cursor = querier.cursor {
            new = CKQueryOperation(cursor: cursor)
        } else if let query = querier.query {
            new = CKQueryOperation(query: query)
        } else { return nil }
        
        new.completionBlock = querier.completionBlock
        new.queryCompletionBlock = querier.queryCompletionBlock
        new.recordFetchedBlock = querier.recordFetchedBlock
        new.name = querier.name

        return new
    }
    
    return nil
}
