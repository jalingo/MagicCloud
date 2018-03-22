//
//  OperationDecorator.swift
//  MagicCloud
//
//  Created by James Lingo on 3/20/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Protocol

/// Types conforming to this protocol can call the `decorate` method and generate a configured Operation.
protocol OperationDecorator: MCCloudErrorHandler {
    
    /// This method returns a fully configured Operation, ready to be launched.
    func decorate() -> Operation
}

// MARK: - Extension

extension OperationDecorator where Self: Operation & MCDatabaseModifier {
 
    // MARK: - Properties
    
    /// This read-only, computed property returns a ModifyBlock for uploading with a CKModifyRecordsOperation.
    var modifyCompletion: ModifyBlock {
        return { recs, ids, error in
            guard error == nil else { self.handle(error, from: self, whileIgnoringUnknownItem: false); return }
        }
    }
    
    // MARK: - Functions
    
    /// !!
    func uniformSetup(_ op: CKModifyRecordsOperation) {
        op.modifyRecordsCompletionBlock = modifyCompletion
        op.savePolicy = .changedKeys
        setLongLived(op)
        setCompletion(op)
    }
    
    /// !!
    fileprivate func setLongLived(_ op: CKModifyRecordsOperation) {
        if #available(iOS 11.0, *) {
            op.configuration.isLongLived = true
        } else {
            op.isLongLived = true
        }
    }
    
    /// This void method passes the completion block down to the last operation and provide local cache clean up. After cloud is updated, this will notify all local receivers, then run passed down completion handling.
    /// - Warning: Any operation passed should have only saves or deletions, or else only deletion clean up will occur.
    /// - Parameter op: The operation whose completion block needs to be passed down, and then whose activity needs to be cleaned up.
    func setCompletion(_ op: CKModifyRecordsOperation) {
        let block = completionBlock
        
        if let overwrites = op.recordsToSave?.count, overwrites > 0 { op.completionBlock = self.uploadBlock(containing: block) }
        
        if let deletions = op.recordIDsToDelete?.count, deletions > 0 { op.completionBlock = self.deleteBlock(containing: block) }
        
        completionBlock = nil
    }
    
    // !!
    fileprivate func uploadBlock(containing block: OptionalClosure) -> OptionalClosure {
        return {
            let unchanged: [T] = self.receiver.localRecordables - self.recordables as! [T]
            let changed = unchanged + self.recordables  // <-- !!
            self.receiver.localRecordables = changed as! [U.type] //unchanged + self.recordables
            block?()
        }
    }
    
    // !!
    fileprivate func deleteBlock(containing block: OptionalClosure) -> OptionalClosure {
        return {
            // originating receiver will ignore notification, this manually removes...
            let newVal = self.receiver.silentRecordables.filter { silent in
                !self.recordables.contains(where: { silent.recordID.recordName == $0.recordID.recordName })
            }
            self.receiver.localRecordables = newVal
            
            block?()
        }
    }
}
