//
//  Delete.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

public class Delete: Operation {
    
    // MARK: - Properties
    
    var delayInSeconds: UInt64 = 0
    
    let recordables: [Recordable]
    
    fileprivate var publicRecordables: [Recordable] {
        return recordables.filter({ $0.database == CKContainer.default().publicCloudDatabase })
    }
    
    fileprivate var privateRecordables: [Recordable] {
        return recordables.filter({ $0.database == CKContainer.default().privateCloudDatabase })
    }
    
    // MARK: - Functions
    
    public override func main() {
        if isCancelled { return }
        
        let publicDb = CKContainer.default().publicCloudDatabase
        let publicOp = Modify(publicRecordables, on: publicDb)
        publicOp.delay = delayInSeconds
        
        if isCancelled { return }
        
        let privateDb = CKContainer.default().privateCloudDatabase
        let privateOp = Modify(privateRecordables, on: privateDb)
        privateOp.delay = delayInSeconds
        
        if isCancelled { return }
        
        // These three lines pass the completionBlock down to the last operation...
        privateOp.addDependency(publicOp)
        privateOp.completionBlock = completionBlock
        completionBlock = nil
        
        if isCancelled { return }

        CloudQueue().addOperation(privateOp)
        CloudQueue().addOperation(publicOp)
    }
    
    // MARK: - Functions: Constructors
    
    init(_ array: [Recordable]) {
        recordables = array
        
        super.init()
    }
    
    // MARK: - InnerClass
    
    class Modify: Operation {
        
        // MARK: - Properties
        
        var delay: UInt64 = 0
        
        var recordables: [Recordable]
        
        fileprivate var recordIDs: [CKRecordID] { return recordables.map({ $0.recordID }) }
        
        var database: CKDatabase
        
        var savedForAsyncCompletion: OptionalClosure 
        
        override var completionBlock: (() -> Void)? {
            get { return nil }                              // <-- This ensures completionBlock doesn't execute prematurely...
            set { savedForAsyncCompletion = newValue }
        }
        
        // MARK: - Functions
        
        override func main() {
            if isCancelled { return }
            
            let op = modifyOpDecorator(recordables)
            delayDispatch(op)
        }
        
        /// This method dispatches operation after specified delay.
        func delayDispatch(_ op: CKDatabaseOperation) {
            let time = DispatchTime.now() + Double(delay)// * NSEC_PER_SEC)
            DispatchQueue(label: "DelayedRecordDeletion").asyncAfter(deadline: time) {
                if self.isCancelled { return }
                self.database.add(op)
            }
        }
        
        /// This method decorates a modify operation and returns it for use.
        func modifyOpDecorator(_ recordables: [Recordable]) -> CKModifyRecordsOperation {
            let modifyOp = CKModifyRecordsOperation(recordsToSave: nil,
                                                    recordIDsToDelete: recordables.map({ $0.recordID }))
            modifyOp.configuration.isLongLived = true
            modifyOp.name = "Upload.Modify.modifyOp"
            modifyOp.modifyRecordsCompletionBlock = modifyRecordsCB()
            
            // This passes the completion block down to the last operation...
            modifyOp.completionBlock = self.savedForAsyncCompletion
            
            return modifyOp
        }
        
        /// This method returns a ready made enclosure for 'modifyRecordsCompletionBlock'.
        func modifyRecordsCB() -> ModifyBlock {
            return { records, ids, error in
                guard error == nil else {
                    if let cloudError = error as? CKError {
                        print("handling error @ Delete.Modify")
                        let errorHandler = MCErrorHandler(error: cloudError,
                                                          originating: self,
                                                          instances: self.recordables,
                                                          target: self.database)
                        ErrorQueue().addOperation(errorHandler)
                    } else {
                        print("NSError: \(String(describing: error)) @ Delete.Modify")
                    }
                    
                    return
                }
            }
        }
        
        // MARK: - Functions: Constructors
        
        init(_ these: [Recordable], on: CKDatabase) {
            recordables = these
            database = on
            
            super.init()
        }
    }
}
