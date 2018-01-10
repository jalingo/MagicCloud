//
//  Delete.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/**
    This wrapper class for CKModifyRecordsOperations deletes records associated with the recordables inserted, from the specified database.
 */
public class MCDelete<R: MCReceiverAbstraction>: Operation {
     
    // MARK: - Properties
    
    /// If a delay is required before dispatching, it can be set here in seconds format (defaults to 0).
    var delayInSeconds: UInt64 = 0

    /// This constant property is an array that stores the recordables associated with the records that need to be removed from the specified database.
    let recordables: [R.type]
    
    /// This constant property stores the MCReceiver associated with MCDelete, that was itself storing the recordables to be deleted from the specified database.
    let receiver: R

    /**
        A conduit for accessing and for performing operations on the public and private data of an app container.
     
        An app container has a public database whose data is accessible to all users and a private database whose data is accessible only to the current user. A database object takes requests for data and applies them to the appropriate part of the container.
     
        You do not create database objects yourself, nor should you subclass CKDatabase. Your app’s CKContainer objects provide the CKDatabase objects you use to access the associated data. Use database objects as-is to perform operations on data.
     
        The public database is always available, regardless of whether the device has an an active iCloud account. When no iCloud account is available, your app may fetch records and perform queries on the public database, but it may not save changes. (Saving records to the public database requires an active iCloud account to identify the owner of those records.) Access to the private database always requires an active iCloud account on the device.
     */
    let database: MCDatabase
    
    // MARK: - Properties: Computed
    
    /// This computed property returns an array of CKRecordID's, derived from `recordables`.
    fileprivate var recordIDs: [CKRecordID] { return recordables.map({ $0.recordID }) }
    
    // MARK: - Functions
    
    public override func main() {
        if isCancelled { return }

        let op = decorate()
        
        if isCancelled { return }
        
        delayDispatch(op)
        
        if isCancelled { return }
        
        for recordable in recordables {
            let name = Notification.Name(recordable.recordType)
            let change = LocalChangePackage(id: recordable.recordID, reason: .recordDeleted, originatingRec: self.receiver.name, db: database)
            NotificationCenter.default.post(name: name, object: change)
        }
    }
    
    /// This method dispatches operation after specified delay.
    func delayDispatch(_ op: CKDatabaseOperation) {
        let time = DispatchTime.now() + Double(delayInSeconds)
        DispatchQueue(label: "DelayedRecordDeletion").asyncAfter(deadline: time) {

            if self.isCancelled { return }
            self.database.db.add(op)
        }
    }
    
    /// This method returns a ready made enclosure for 'modifyRecordsCompletionBlock'.
    func modifyRecordsCB() -> ModifyBlock {
        return { records, ids, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: self,
                                                      target: self.database, instances: self.recordables,
                                                      receiver: self.receiver)
                    OperationQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(String(describing: error)) @ Delete")
                }
                
                return
            }
        }
    }
    
    /// This method decorates a modify operation.
    func decorate() -> CKModifyRecordsOperation {
        let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        
        op.name = "Delete"
        op.modifyRecordsCompletionBlock = modifyRecordsCB()
        if #available(iOS 11.0, *) {
            op.configuration.isLongLived = true
        } else {
            op.isLongLived = true
        }
        
        // This passes the completion block down to the last operation...
        op.completionBlock = self.completionBlock
        self.completionBlock = nil
        
        return op
    }
    
    // MARK: - Functions: Constructors
    
    /**
        - Parameters:
            - array: The recordables associated with the records that need to be removed from the specified database.
            - rec: The MCReceiver associated with MCDelete, that was itself storing the recordables to be deleted from the specified database.
            - db: The DatabaseType enumerating the CKDatabase containing the records that need to be deleted.
     */
    public init(_ array: [R.type]? = nil, of rec: R, from db: MCDatabase) {
        recordables = array ?? rec.recordables
        receiver = rec
        database = db
        
        super.init()
    }
}
