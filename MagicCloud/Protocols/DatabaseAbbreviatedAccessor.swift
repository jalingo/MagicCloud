//
//  DatabaseAbbreviatedAccessor.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol DatabaseAbbreviatedAccessor {
    
    /// This computed property returns the actual CKDatabase being enumerated.
    var db: CKDatabase { get }
}
