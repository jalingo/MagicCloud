//
//  MCDatabase Extensions.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Extensions

// MARK: - Extension: CKDatabaseScopeWrapper

extension MCDatabase: CKDatabaseScopeWrapper {
    
    /// This read-only, computed property returns the scope of MCDatabase enumeration.
    var scope: CKDatabaseScope {
        switch self {
        case .publicDB: return CKDatabaseScope.public
        case .privateDB: return CKDatabaseScope.private
        case .sharedDB: return CKDatabaseScope.shared
        case .custom(let d, _): return d.scope
        }
    }
}

// MARK: - Extension: DatabaseAbbreviatedAccessor

extension MCDatabase: DatabaseAbbreviatedAccessor {
    
    /// This computed property returns the actual CKDatabase being enumerated.
    var db: CKDatabase { return database(for: self) }
        
    /// This method returns the exact database being referred to by passed arguments.
    fileprivate func database(for db: MCDatabase, in container: CKContainer = CKContainer.default()) -> CKDatabase {
        switch db {
        case .publicDB: return container.publicCloudDatabase
        case .privateDB: return container.privateCloudDatabase
        case .sharedDB: return container.sharedCloudDatabase
        case .custom(let db, let c): return database(for: db, in: c)
        }
    }
}

// MARK: - Extension: CustomStringConvertible

extension MCDatabase: CustomStringConvertible {
    
    /// This read-only, computed property returns a string description of this enumeration.
    public var description: String { return toStr(db: self) }
    
    /// This method returns a string description of enumeration of passed arguments.
    fileprivate func toStr(db: MCDatabase, in container: CKContainer = CKContainer.default()) -> String {
        switch db {
        case .publicDB: return "public database in \(container.description)"
        case .privateDB: return "private database in \(container.description)"
        case .sharedDB: return "shared database in \(container.description)"
        case .custom(let d, let c): return toStr(db: d, in: c)
        }
    }
}
