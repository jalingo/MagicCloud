//
//  Delete.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

public class Delete<R: ReceivesRecordable>: Operation {
    
    // MARK: - Properties
    
    var delayInSeconds: UInt64 = 0
    
    let recordables: [R.type]
    
    let receiver: R

    let database: DatabaseType
    
    var savedForAsyncCompletion: OptionalClosure
    
    // MARK: - Properties: Computed
    
    public override var completionBlock: (() -> Void)? {
        get { return nil }                              // <-- This ensures completionBlock doesn't execute prematurely...
        set { savedForAsyncCompletion = newValue }
    }
    
    fileprivate var recordIDs: [CKRecordID] { return recordables.map({ $0.recordID }) }
    
    // MARK: - Functions
    
    public override func main() {
        if isCancelled { return }

        let op = decorate()
        
        if isCancelled { return }
        
        delayDispatch(op)
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
                    print("handling error @ Delete")
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: self,
                                                      target: self.database, instances: self.recordables,
                                                      receiver: self.receiver)
                    ErrorQueue().addOperation(errorHandler)
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
        op.completionBlock = self.savedForAsyncCompletion
        
        return op
    }
    
    // MARK: - Functions: Constructors
    
    init(_ array: [R.type]? = nil, from rec: R, to type: DatabaseType) {
        recordables = array ?? rec.recordables
        receiver = rec
        database = type
        
        super.init()
    }
}
