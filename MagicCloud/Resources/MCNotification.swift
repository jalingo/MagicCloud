//
//  CloudNotification.swift
//  slBackend
//
//  Created by James Lingo on 11/12/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/// forType = CKRecordType
public enum MCNotification {
    case error, changeNoticed(forType: String, at: MCDatabaseType)
    
    static let userInfoKey = "MCNotification_Dictionary_Key"
    
    public func toString() -> String {
        switch self {
        case .error:                            return "CLOUD_KIT_ERROR"
        case .changeNoticed(let type, let db):  return "\(type)_CHANGED_IN_\(db)"
        }
    }
}
