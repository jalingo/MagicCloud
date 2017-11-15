//
//  NewUpload.swift
//  slBackend
//
//  Created by James Lingo on 11/9/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

// MARK: - Class

public class Upload<R: ReceivesRecordable>: Operation {
    
    // MARK: - Properties

    let database: DatabaseType
    
    let receiver: R
    
    let recordables: [R.type] 

    var savedForAsyncCompletion: OptionalClosure
    
    // MARK: - Properties: Computed
    
    public override var completionBlock: (() -> Void)? {
        get { return nil }                              // <-- This ensures completionBlock doesn't execute prematurely...
        set { savedForAsyncCompletion = newValue }
    }
    
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
    
    var modifyCompletion: ModifyBlock {
        return { _, _, error in
            guard error == nil else {
                self.completionBlock = self.savedForAsyncCompletion
                self.handle(error, from: self, whileIgnoringUnknownItem: false)
                return
            }
            
            // This transfers `Modify.completionBlock` to the end of modify operation...
            if let closure = self.savedForAsyncCompletion { closure() }
        }
    }
    
    // MARK: - Functions
    
    public override func main() {
        if isCancelled { return }
        
        let op = decorate()

        if isCancelled { return }
        
        database.db.add(op)
    }
    
    fileprivate func decorate() -> CKModifyRecordsOperation {
        let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        op.name = "Upload: \(database.db.description)"
        
        op.savePolicy = .changedKeys
        if #available(iOS 11.0, *) {
            op.configuration.isLongLived = true
        } else {
            op.isLongLived = true
        }
        
        return op
    }
    
    fileprivate func handle(_ error: Error?, from op: Operation, whileIgnoringUnknownItem: Bool) {
        
        if isCancelled { return }
        
        if let cloudError = error as? CKError {
print("handling error @ Upload")
            let errorHandler = MCErrorHandler(error: cloudError,
                                              originating: op,
                                              target: database, instances: recordables,
                                              receiver: receiver)
            errorHandler.ignoreUnknownItem = whileIgnoringUnknownItem
            ErrorQueue().addOperation(errorHandler)
        } else {
            print("NSError: \(String(describing: error?.localizedDescription)) @ Upload::\(op)")
        }
    }
    
    // MARK: - Functions: Constructors
    
    init(_ recs: [R.type]? = nil, from rec: R, to db: DatabaseType) {
        receiver = rec
        database = db
        recordables = recs ?? rec.recordables
        
        super.init()
        
        self.name = "Upload"
    }
}
