//
//  MCDatabaseQuerier.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol MCDatabaseQuerier: MCRecordableReceiver {
    
    /// This property stores a customized completion block triggered by `Unknown Item` errors.
    var unknownItemCustomAction: OptionalClosure { get set }
    
    /**
     The maximum number of records to return at one time.
     
     For most queries, leave the value of this property set to the default value, which is represented by the **CKQueryOperationMaximumResults** constant. When using that value, the server chooses a limit that aims to provide an optimal number of results that returns as many records as possible while minimizing delays in receiving those records. However, if you know that you want to process a fixed number of results, change the value of this property accordingly.
     */
    var limit: Int? { get set }
}

extension MCDatabaseQuerier {
    
    /// This method creates an operation that can finish an incomplete query from a CKQueryCursor.
    fileprivate func followUp(cursor: CKQueryCursor, op: CKQueryOperation) -> CKQueryOperation {
        let newOp = CKQueryOperation(cursor: cursor)
        
        newOp.queryCompletionBlock = op.queryCompletionBlock
        newOp.recordFetchedBlock = op.recordFetchedBlock
        newOp.resultsLimit = op.resultsLimit
        
        return newOp
    }
}

extension MCDatabaseQuerier where Self: Operation & MCCloudErrorHandler {
 
    /// This method supplies a completion block for CKQueryOperation.queryCompletionBlock.
    func queryCompletion(op: CKQueryOperation) -> QueryBlock {
        return { cursor, error in
            if let queryCursor = cursor {
                self.database.db.add(self.followUp(cursor: queryCursor, op: op))
            } else {
                guard error == nil else { self.handle(error, in: self); return }
            }
        }
    }
    
    /// This method supplies a completion block for CKQueryOperation.recordFetchedBlock.
    func recordFetched() -> FetchBlock {
        return { record in
            let recordable = R.type().prepare(from: record)
            
            // This if statement checks to avoid downloading duplicates.
            if !self.receiver.silentRecordables.contains(where: { $0.recordID.recordName == recordable.recordID.recordName }) {
                self.receiver.silentRecordables.append(recordable)
            }
        }
    }
}
