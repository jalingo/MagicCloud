//
//  MCDatabaseOperation.swift
//  MagicCloud
//
//  Created by James Lingo on 3/20/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Protocol

/// Types conforming to this protocol have the properties needed to prepare and launch `CKDatabaseOperation` classes.
protocol MCDatabaseOperation {
    
    /// This read-only property returns the target cloud database for operation.
    var database: MCDatabase { get }
}
