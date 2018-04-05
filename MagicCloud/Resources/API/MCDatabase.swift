//
//  MCDatabaseType.swift
//  MagicCloud
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Enum

/// This enumerates the different cloud databases available, and provides access.
public indirect enum MCDatabase {
    
    // MARK: - Cases
    
    /// An enumeration of CKContainer.default().publicCloudDatabase or public scope of a custom container.
    case publicDB
    
    /// An enumeration of CKContainer.default().privateCloudDatabase or private scope of a custom container.
    case privateDB
    
    /// A string enumeration of CKContainer.default().sharedCloudDatabase or shared scope of a custom container.
    case sharedDB

    /// An indirect enumeration of an MCDatabase w/custom container.
    case custom(MCDatabase, CKContainer)
    
    // MARK: - Functions
    
    /// Derives and returns an MCDatabaseType from a CKDatabaseScope.
    static func from(scope: CKDatabaseScope, custom container: CKContainer? = nil) -> MCDatabase {
        if let c = container { return custom(MCDatabase.from(scope: scope), c) }
        
        switch scope {
        case .private:  return .privateDB
        case .public:   return .publicDB
        case .shared:   return .sharedDB
        }
    }
}
