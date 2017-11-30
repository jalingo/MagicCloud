//
//  Prepare.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/31/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/// Builds an appropriate recordable based on type.
public func prepare<T: MCRecordable>(type: T.Type, from record: CKRecord) -> MCRecordable {
    var recordable: MCRecordable = T()
    
    // Overwrites default recordable with data from recovered record.
    // Order of these two lines is important.
    recordable.recordID = record.recordID
    for (key, _) in recordable.recordFields { recordable.recordFields[key] = record[key] }
    
    return recordable
}
