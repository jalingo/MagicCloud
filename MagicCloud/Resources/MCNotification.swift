//
//  CloudNotification.swift
//  slBackend
//
//  Created by James Lingo on 11/12/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

public enum MCNotification {
    case error(CKError), changeNoticed(forType: String, at: DatabaseType)
    
    public func toString() -> String {
        switch self {
        case .error(let error):                 return "CLOUD_ERROR_\(error.errorCode)"
        case .changeNoticed(let type, let db):  return "\(type)_CHANGED_IN_\(db)"
        }
    }
}
