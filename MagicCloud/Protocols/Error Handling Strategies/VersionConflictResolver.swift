//
//  VersionConflictResolver.swift
//  MagicCloud
//
//  Created by James Lingo on 3/26/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types conforming to this protocol can call the `resolveVersionConflict:error:accordingTo` method that deals with serverRecordChanged CKErrors based on specified policy.
protocol VersionConflictResolver: VersionConflictKeys { }

extension VersionConflictResolver {
    
    /// This method determines approach to use (based on policy).
    /// !!
    fileprivate func conflictResolution(for error: CKError, accordingTo policy: CKRecordSavePolicy, with recordables: [MCRecordable]) -> CKRecord? {
        guard error.code == .serverRecordChanged else { return nil }
        
        switch policy {
        case .changedKeys:              return changedKeys(for: error, with: recordables)
        case .allKeys:                  return allKeys(for: error)
        case .ifServerRecordUnchanged:  return nil          // <-- Any resolution will be skipped.
        }
    }
}

extension VersionConflictResolver where Self: Operation & MCDatabaseModifier & MCCloudErrorHandler {
    
    /// This void method deals with serverRecordChanged CKErrors based on specified policy.
    /// !!
    func resolveVersionConflict(_ error: CKError, accordingTo policy: CKRecordSavePolicy) {
        guard let record = conflictResolution(for: error, accordingTo: policy, with: self.recordables) else { return }
        
        // Uploads current record with changes made and latest changeTag.
        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        op.savePolicy = policy
        op.modifyRecordsCompletionBlock = { _, _, error in
            guard error == nil else { self.handle(error, in: op, whileIgnoringUnknownItem: false); return }
        }
        
        op.completionBlock = self.completionBlock
        self.completionBlock = nil
        
        self.database.db.add(op)
    }
}

extension VersionConflictResolver where Self: Operation & MCDatabaseQuerier & MCCloudErrorHandler {
    
    /// This void method deals with serverRecordChanged CKErrors based on specified policy.
    /// !!
   func resolveVersionConflict(_ error: CKError, accordingTo policy: CKRecordSavePolicy) {
        guard let record = conflictResolution(for: error, accordingTo: policy, with: []) else { return }

        // Uploads current record with changes made and latest changeTag.
        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        op.savePolicy = policy
        op.modifyRecordsCompletionBlock = { _, _, error in
            guard error == nil else { self.handle(error, in: op); return }
        }
        
        op.completionBlock = self.completionBlock
        self.completionBlock = nil
        
        self.database.db.add(op)
    }
}
