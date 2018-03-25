//
//  Delete.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Class

/**
    This wrapper class for CKModifyRecordsOperations deletes records associated with the recordables inserted, from the specified database.
 */
public class MCDelete<R: MCMirrorAbstraction>: Operation, MCDatabaseModifier, MCCloudErrorHandler {
     
    // MARK: - Properties
    
    /// If a delay is required before dispatching, it can be set here in seconds format (defaults to 0).
    var delayInSeconds: Double = 0
    
    // MARK: - Properties: MCDatabaseModifier

    /// This constant property is an array that stores the recordables associated with the records that need to be removed from the specified database.
    let recordables: [R.type]

    // MARK: - Properties: MCCloudErrorHandler
    
    /// This constant property stores the MCMirror associated with MCDelete, that was itself storing the recordables to be deleted from the specified database.
    let receiver: R

    // MARK: - Properties: MCDatabaseOperation

    /// This read-only property returns the target cloud database for operation.
    let database: MCDatabase
        
    // MARK: - Functions
    
    // MARK: - Functions: Operation
    
    /// If not cancelled, this method override will decorate and launch a CKModifyRecordsOperation in the specifified database.
    public override func main() {
        guard recordables.count != 0 else { return }

        if isCancelled { return }

        let op = decorate()
        
        if isCancelled { return }
        
        DispatchQueue(label: "DelayedRecordDeletion").asyncAfter(deadline: .now() + delayInSeconds) {
            if self.isCancelled { return }
            if let op = op as? CKDatabaseOperation { self.database.db.add(op) }
        }
        
        if isCancelled { return }
        
        op.waitUntilFinished()
    }
    
    // MARK: - Functions: Constructors
    
    /**
        This wrapper class for CKModifyRecordsOperations deletes records associated with the recordables inserted, from the specified database.
     
        - Parameters:
            - array: The recordables associated with the records that need to be removed from the specified database.
            - rec: The MCReceiver associated with MCDelete, that was itself storing the recordables to be deleted from the specified database.
            - db: The DatabaseType enumerating the CKDatabase containing the records that need to be deleted.
     */
    public init(_ array: [R.type]? = nil, of rec: R, from db: MCDatabase) {
        recordables = array ?? rec.silentRecordables
        receiver = rec
        database = db
        
        super.init()
        
        self.name = "Delete \(String(describing: array?.count)) recs for \(rec.name) to \(db)"
    }
}

// MARK: - Extension

extension MCDelete: OperationDecorator {
    
    /// This method decorates a modify operation.
    func decorate() -> Operation {
        let op = CKModifyRecordsOperation(recordsToSave: nil,
                                          recordIDsToDelete: recordIDs)
        op.name = self.name
        uniformSetup(op)
        
        return op
    }
}
