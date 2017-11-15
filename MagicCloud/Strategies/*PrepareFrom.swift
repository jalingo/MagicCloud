//
//  Prepare.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/31/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/// Builds an appropriate recordable based on type.
func prepare<T: Recordable>(type: T.Type, from record: CKRecord/*, in db: CKDatabase*/) -> Recordable {
    var recordable: Recordable = T()
    
    // Overwrites default recordable with data from recovered record.
    // Order of these two lines is important.
    recordable.recordID = record.recordID
    for (key, _) in recordable.recordFields { recordable.recordFields[key] = record[key] }
    
    return recordable
}
