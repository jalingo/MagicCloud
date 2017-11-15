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

public class Upload<T: Recordable>: Operation {
    
    // MARK: - Properties
    
    let publicDB = CKContainer.default().publicCloudDatabase
    
    let privateDB = CKContainer.default().privateCloudDatabase
    
    let sharedDB = CKContainer.default().sharedCloudDatabase
    
    let recordables: [T]
    
    fileprivate var publicRecordables: [T] {
        return recordables.filter() { $0.database == CKContainer.default().publicCloudDatabase }
    }
    
    fileprivate var privateRecordables: [T] {
        return recordables.filter() { $0.database == CKContainer.default().privateCloudDatabase }
    }
    
    fileprivate var sharedRecordables: [T] {
        return recordables.filter() { $0.database == CKContainer.default().sharedCloudDatabase }
    }
    // MARK: - Functions
    
    public override func main() {
        if isCancelled { return }
        
        let publicOp = Modify<T>(these: publicRecordables, on: .publicDB, completion: completionBlock)
        completionBlock = nil

        if isCancelled { return }
        
        let privateOp = Modify<T>(these: privateRecordables, on: .privateDB)
        
        if isCancelled { return }
        
        let sharedOp = Modify<T>(these: sharedRecordables, on: .sharedDB)
        
        privateOp.addDependency(sharedOp)
        publicOp.addDependency(privateOp)
        
        if isCancelled { return }

        publicDB.add(publicOp)
        privateDB.add(privateOp)
        sharedDB.add(sharedOp)
    }
    
    // MARK: - Functions: Constructors
    
    init(_ array: [T]) {
        recordables = array
        
        super.init()
        
        self.name = "NewUpload"
    }
    
    // MARK: - InnerClasses
    
    class Modify<T: Recordable>: CKModifyRecordsOperation {
        
        // MARK: - Enum
        
        enum DatabaseType {
            case publicDB, privateDB, sharedDB
        }
        
        // MARK: - Properties
        
        var db: CKDatabase
        
        var recordables: [Recordable]

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
                    self.completionBlock = self.totalCompletion
                    self.handle(error, from: self, whileIgnoringUnknownItem: false)
                    return
                }
                
                // This transfers `Modify.completionBlock` to the end of modify operation...
                if let closure = self.totalCompletion {
print("NewUpload.Modify concluding...")
                    closure()
                }
            }
        }
        
        var totalCompletion: OptionalClosure

        // MARK: - Functions
        
        fileprivate func decorate(completion: OptionalClosure) {
            
            if isCancelled { return }
            
            self.recordsToSave = records
            self.name = "NewUpload.Modify: \(db.description)"

            self.savePolicy = .changedKeys
            if #available(iOS 11.0, *) {
                self.configuration.isLongLived = true
            } else {
                self.isLongLived = true
            }
            
            self.totalCompletion = completion
            self.modifyRecordsCompletionBlock = modifyCompletion
        }
        
        fileprivate func handle(_ error: Error?, from op: CKOperation, whileIgnoringUnknownItem: Bool) {
            
            if isCancelled { return }
            
            if let cloudError = error as? CKError, let recordables = self.recordables as? [T] {
print("handling error @ NewUpload")
                let errorHandler = MCErrorHandler(error: cloudError,
                                                  originating: op,
                                                  target: self.db,
                                                  instances: recordables)
                errorHandler.ignoreUnknownItem = whileIgnoringUnknownItem
                ErrorQueue().addOperation(errorHandler)
            } else {
                print("NSError: \(String(describing: error?.localizedDescription)) @ NewUpload::\(op)")
            }
        }
        
        // MARK: - Functions: Inits
        
        init(these recs: [T], on database: DatabaseType, completion: OptionalClosure = nil) {
           
            recordables = recs
            
            switch database {
            case .privateDB: db = CKContainer.default().privateCloudDatabase
            case .publicDB: db = CKContainer.default().publicCloudDatabase
            case .sharedDB: db = CKContainer.default().sharedCloudDatabase
            }
            
            super.init()

            decorate(completion: completion)
            
        }
    }
}
