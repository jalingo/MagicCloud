//
//  CKDatabaseScopeWrapper.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol CKDatabaseScopeWrapper {
    
    /// This read-only, computed property returns the scope of MCDatabase enumeration.
    var scope: CKDatabaseScope { get }
}
