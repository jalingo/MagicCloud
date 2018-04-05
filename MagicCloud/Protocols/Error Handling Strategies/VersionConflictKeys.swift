//
//  VersionConflictKeys.swift
//  MagicCloud
//
//  Created by James Lingo on 3/27/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// !!
protocol VersionConflictKeys { }

extension VersionConflictKeys {
    
    /**
     * This method is used during cloud error handling, to repair version conflicts (reported as
     * `ServerRecordChanged` CKError), under CKRecordSavePolicy.allKeys.
     */
    func allKeys(for error: CKError) -> CKRecord? {
        return error.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord
    }
    
    /**
     * This method is used during cloud error handling, to repair version conflicts (reported as
     * `ServerRecordChanged` CKError), under CKRecordSavePolicy.changedKeys.
     */
    func changedKeys(for error: CKError, with recordables: [MCRecordable]) -> CKRecord? {
        guard let original = error.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord,
            let current = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
            let attempt = error.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord
            else {
                print("recordableIsNil @ VersionConflict:0")
                return nil
        }
        
        var recordable: MCRecordable?
        for instance in recordables {
            if instance.recordID.recordName == current.recordID.recordName { recordable = instance }
        }
        
        guard recordable != nil else { print("recordableIsNil @ VersionConflict:1"); return nil }
        
        for entry in recordable!.recordFields {
            if let originalValue = original[entry.key],
                let currentValue = current[entry.key],
                let attemptValue = attempt[entry.key] {
                
                switch entry.value {
                case is NSNumber:
                    if currentValue as? NSNumber == originalValue as? NSNumber &&
                        currentValue as? NSNumber != attemptValue as? NSNumber {
                        current[entry.key] = attemptValue
                    }
                case is NSData:
                    if currentValue as? NSData == originalValue as? NSData &&
                        currentValue as? NSData != attemptValue as? NSData {
                        current[entry.key] = attemptValue
                    }
                case is NSDate:
                    if currentValue as? NSDate == originalValue as? NSDate &&
                        currentValue as? NSDate != attemptValue as? NSDate {
                        current[entry.key] = attemptValue
                    }
                case is CKAsset:
                    if currentValue as? CKAsset == originalValue as? CKAsset &&
                        currentValue as? CKAsset != attemptValue as? CKAsset {
                        current[entry.key] = attemptValue
                    }
                case is CLLocation:
                    if currentValue as? CLLocation == originalValue as? CLLocation &&
                        currentValue as? CLLocation != attemptValue as? CLLocation {
                        current[entry.key] = attemptValue
                    }
                case is CKReference:
                    if currentValue as? CKReference == originalValue as? CKReference &&
                        currentValue as? CKReference != attemptValue as? CKReference {
                        current[entry.key] = attemptValue
                    }
                default:    // <-- String
                    if currentValue as? String == originalValue as? String &&
                        currentValue as? String != attemptValue as? String {
                        current[entry.key] = attemptValue
                    }
                }
            }
        }
        
        return current
    }
}
