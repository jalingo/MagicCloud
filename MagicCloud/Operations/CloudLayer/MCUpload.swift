//
//  NewUpload.swift
//  slBackend
//
//  Created by James Lingo on 11/9/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

// MARK: - Class
 
/**
    This wrapper class for CKModifyRecordsOperation saves records for the injected recordables in the specified database.
 */
public class MCUpload<R: MCMirrorAbstraction>: Operation {
    
    // MARK: - Properties

    /**
        A conduit for accessing and for performing operations on the public and private data of an app container.
     
        An app container has a public database whose data is accessible to all users and a private database whose data is accessible only to the current user. A database object takes requests for data and applies them to the appropriate part of the container.
     
        You do not create database objects yourself, nor should you subclass CKDatabase. Your app’s CKContainer objects provide the CKDatabase objects you use to access the associated data. Use database objects as-is to perform operations on data.
     
        The public database is always available, regardless of whether the device has an an active iCloud account. When no iCloud account is available, your app may fetch records and perform queries on the public database, but it may not save changes. (Saving records to the public database requires an active iCloud account to identify the owner of those records.) Access to the private database always requires an active iCloud account on the device.
     */
    let database: MCDatabase
    
    /// This is the MCReceiver that contains the recordables that are being uploaded to database.
    let receiver: R
    
    /**
        This constant property is an array that stores the recordables associated with the records that need to be uploaded to the specified database.
     */
    let recordables: [R.type]
    
    // MARK: - Properties: Computed

    /// This read-only, computed property returns an array of CKRecords containing data from recordables.
    fileprivate var records: [CKRecord] {
        var recs = [CKRecord]()
        
        // This loop converts recordables into CKRecord's for array
        for recordable in recordables {
            let rec = CKRecord(recordType: recordable.recordType, recordID: recordable.recordID)
            for entry in recordable.recordFields { rec[entry.key] = entry.value }
            recs.append(rec)
        }
        
        return recs
    }
    
    /// This read-only, computed property returns a ModifyBlock for uploading with a CKModifyRecordsOperation.
    fileprivate var modifyCompletion: ModifyBlock {
        return { recs, ids, error in
            guard error == nil else { self.handle(error, from: self, whileIgnoringUnknownItem: false); return }
        }
    }
    
    // MARK: - Functions
    
    /// This method decorates CKModifyRecordsOperation with settings and name.
    fileprivate func decorate() -> CKModifyRecordsOperation {
        let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        op.name = "Upload: \(database)"
        
        op.modifyRecordsCompletionBlock = modifyCompletion
        
        op.savePolicy = .changedKeys
        if #available(iOS 11.0, *) {
            op.configuration.isLongLived = true
        } else {
            op.isLongLived = true
        }
        
        let block = completionBlock
        
        // After cloud is updated, this will notify all local receivers, then run passed down completion handling.
        op.completionBlock = {
            let unchanged: [R.type] = self.receiver.localRecordables - self.recordables as! [R.type]
            self.receiver.localRecordables = unchanged + self.recordables
            block?()
        }
        
        completionBlock = nil
        
        return op
    }
    
    /// This method handles errors from CKModifyRecordsOperation with MagicCloud framework.
    fileprivate func handle(_ error: Error?, from op: Operation, whileIgnoringUnknownItem: Bool) {
        if isCancelled { return }
        
        if let cloudError = error as? CKError {
            let errorHandler = MCErrorHandler(error: cloudError,
                                              originating: op,
                                              target: database, instances: recordables,
                                              receiver: receiver)
            errorHandler.ignoreUnknownItem = whileIgnoringUnknownItem
            OperationQueue().addOperation(errorHandler)
        } else {
            print("NSError: \(String(describing: error?.localizedDescription)) @ Upload::\(op)")
        }
    }
    
    // MARK: - Functions: Operation
    
    /// If not cancelled, this method override will decorate and launch a CKModifyRecordsOperation in the specifified database.
    public override func main() {

        guard recordables.count != 0 else { return }

        if isCancelled { return }
        
        let op = decorate()
        
        if isCancelled { return }
        
        database.db.add(op)
        
        if isCancelled { return }
        
        op.waitUntilFinished()
    }
    
    // MARK: - Functions: Constructors
    
    /**
        - Parameters:
            - recs: An array of the MCRecordables associated with the records that need to be uploaded to the specified database.
            - rec: The MCReceiver from which records are being derived and uploaded.
            - db: An enumeration of the CKDatabase records are to be uploaded to.
     */
    public init(_ recs: [R.type]? = nil, from rec: R, to db: MCDatabase) {
        receiver = rec
        database = db   //DatabaseType.from(scope: db)
        recordables = recs ?? rec.silentRecordables
        
        super.init()
        
        self.name = "Upload \(String(describing: recs?.count)) recs for \(rec.name) to \(db)"
    }
}
