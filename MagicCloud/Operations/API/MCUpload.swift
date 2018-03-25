//
//  NewUpload.swift
//  slBackend
//
//  Created by James Lingo on 11/9/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Class

/// This wrapper class for CKModifyRecordsOperation saves records for the injected recordables in the specified database.
public class MCUpload<R: MCMirrorAbstraction>: Operation, MCDatabaseModifier, MCCloudErrorHandler {    
    
    // MARK: - Properties
    
    // MARK: - Properties: MCDatabaseModifier
    
    /// This constant property is an array that stores the recordables associated with the records that need to be uploaded to the specified database.
    let recordables: [R.type]
    
    // MARK: - Properties: MCDatabaseOperation

    /// This read-only property returns the target cloud database for operation.
    let database: MCDatabase
    
    /// This is the MCMirror that contains the recordables that are being uploaded to database.
    let receiver: R
    
    // MARK: - Functions
    
    // MARK: - Functions: Operation
    
    /// If not cancelled, this method override will decorate and launch a CKModifyRecordsOperation in the specifified database.
    public override func main() {
        guard recordables.count != 0 else { return }

        if isCancelled { return }
        
        guard let op = decorate() as? CKDatabaseOperation else { return }
        
        if isCancelled { return }
        
        database.db.add(op)
        
        if isCancelled { return }
        
        op.waitUntilFinished()
    }
    
    // MARK: - Functions: Constructors
    
    /**
        This wrapper class for CKModifyRecordsOperation saves records for the injected recordables in the specified database.
     
        - Parameters:
            - recs: An array of the MCRecordables associated with the records that need to be uploaded to the specified database.
            - rec: The MCReceiver from which records are being derived and uploaded.
            - db: An enumeration of the CKDatabase records are to be uploaded to.
     */
    public init(_ recs: [R.type]? = nil, from rec: R, to db: MCDatabase) {
        receiver = rec
        database = db
        recordables = recs ?? rec.silentRecordables
        
        super.init()
        
        self.name = "Upload \(String(describing: recs?.count)) recs for \(rec.name) to \(db)"
    }
}

// MARK: - Extension

extension MCUpload: OperationDecorator {
    
    /// This method returns a fully configured Operation, ready to be launched.
    func decorate() -> Operation {
        let op = CKModifyRecordsOperation(recordsToSave: self.records,
                                          recordIDsToDelete: nil)
        op.name = self.name
        uniformSetup(op)
        
        return op
    }
}
