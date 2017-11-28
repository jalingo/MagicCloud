//
//  Queues.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import Foundation

class ErrorQueue: OperationQueue {
    
}

class CloudQueue: OperationQueue {
    
}

// MARK: - Enum

import CloudKit

public enum DatabaseType {
    case publicDB, privateDB, sharedDB
    
    static func from(scope: CKDatabaseScope) -> DatabaseType {
        switch scope {
        case .private:  return .privateDB
        case .public:   return .publicDB
        case .shared:   return .sharedDB
        }
    }
    
    var db: CKDatabase {
        switch self {
        case .publicDB: return CKContainer.default().publicCloudDatabase
        case .privateDB: return CKContainer.default().privateCloudDatabase
        case .sharedDB: return CKContainer.default().sharedCloudDatabase
        }
    }
}
