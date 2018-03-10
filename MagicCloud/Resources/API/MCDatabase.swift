//
//  MCDatabaseType.swift
//  MagicCloud
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Enum

/// This enumerates the different cloud databases available as strings, and provides access
public indirect enum MCDatabase {

    // MARK: - Cases
    
    /// A string enumeration of CKContainer.default().publicCloudDatabase
    case publicDB
    
    /// A string enumeration of CKContainer.default().privateCloudDatabase
    case privateDB
    
    /// A string enumeration of CKContainer.default().sharedCloudDatabase
    case sharedDB

    /// A string enumeration of an MCDatabase w/custom container.
    case custom(MCDatabase, CKContainer)

    // MARK: - Properties
    
    /// This computed property returns the actual CKDatabase being enumerated.
    var db: CKDatabase { return database(for: self) }

    /// This read-only, computed property returns the scope of MCDatabase enumeration.
    var scope: CKDatabaseScope {
        switch self {
        case .publicDB: return CKDatabaseScope.public
        case .privateDB: return CKDatabaseScope.private
        case .sharedDB: return CKDatabaseScope.shared
        case .custom(let d, _): return d.scope
        }
    }
    
    // MARK: - Functions
    
    /// This method returns the exact database being referred to by passed arguments.
    fileprivate func database(for db: MCDatabase, in container: CKContainer = CKContainer.default()) -> CKDatabase {
        switch db {
        case .publicDB: return container.publicCloudDatabase
        case .privateDB: return container.privateCloudDatabase
        case .sharedDB: return container.sharedCloudDatabase
        case .custom(let db, let c): return database(for: db, in: c)
        }
    }

    // MARK: - Functions: Static Constructors
    
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
