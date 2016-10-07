//
//  VersionConflictOperation.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/21/16.
//
//

import Foundation
import CloudKit

class VersionConflictOperation: Operation {
    
    var error: CKError?
    
    var recordable: Recordable?
    
    var database: CKDatabase?
    
    var completionOperation = Operation()
    
    override func main() {
        if isCancelled { return }

        guard let original = error?.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord,
            let current = error?.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
            let attempt = error?.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord
            else {
                // Error not dealt with, completion failed.
//                completionOperation.start()      // <-- should this happen during a failure?
                return
        }
        
        if isCancelled { return }
        
        // This for loop goes through every record field, attempting version conflict resolution.
        for entry in recordable!.dictionaryOfKeysAndAssociatedValueTypes {
            if let originalValue = original[entry.key] as? entry.Type,
                let currentValue = current[entry.key] as? entry.Type,
                let attemptValue = attempt[entry.key] as? entry.Type {
                
                if currentValue == originalValue && currentValue != attemptValue {
                    current[entry.key] = attemptValue as? CKRecordValue
                }
            }
        }
        
        if isCancelled { return }
        
        // Uploads current record with changes made and new changeTag.
        let operation = CKModifyRecordsOperation(recordsToSave: [current], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { records, recordIDs, error in
            
            guard error == nil else {

                let queue = ErrorQueue()

                let errorHandler = CloudErrorOperation(error: error as! CKError,
                                                       instance: self.recordable!,
                                                       database: self.database!,
                                                       originating: self, failedOn: queue)
                
                self.completionOperation.addDependency(errorHandler)
                queue.addOperation(errorHandler)
                queue.addOperation(self.completionOperation)
                
                return
            }
        }
        
        if isCancelled { return }
        
        let queue = CloudQueue()

        if completionOperation.completionBlock != nil {
            completionOperation.addDependency(operation)
            queue.addOperation(completionOperation)
        }
        
        queue.addOperation(operation)
    }
    
    init(error: CKError, instance: Recordable, completionBlock: OptionalClosure) {
        self.error = error
        recordable = instance
        completionOperation.completionBlock = completionBlock
        
        super.init()
    }
    
    fileprivate override init() { }
}
