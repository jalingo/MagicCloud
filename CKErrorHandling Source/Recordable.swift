//
//  Recordable.swift
//  Voyage
//
//  Created by Jimmy Lingo on 8/31/16.
//  Copyright © 2016 lingoTECH Solutions. All rights reserved.
//

import CloudKit

/**
 * The Recordable protocol ensures that any conforming instances have what is necessary
 * to be recorded in the cloud database. Conformance to this protocol is also necessary 
 * to interact with the generic cloud functionality in this workspace.
 */
protocol Recordable {
    
    /**
     * This is a token used with cloudkit to build CKRecordID for this object's CKRecord.
     */
    static var REC_TYPE: String { get }

    /**
     * This dictionary has to match all of the keys used in CKRecord in order for version
     * conflicts and retry attempts to succeed. It values chould reflect the Type associated
     * with keys in CKRecord.
     */
    static var dictionaryOfKeysAndAssociatedValueTypes: Dictionary<String, CKRecordValue.Type> { get }
    
    /**
     * This string identifier is used when constructing a conforming instance's CKRecordID.
     * Said ID is used to construct records and references, as well as query and fetch from
     * the cloud database. 
     *
     * Must be unique in the database.
     */
    var identifier: String { get }
    
    /**
     * A record identifier used to store and recover conforming instance's record.
     */
    var recordID: CKRecordID { get }
    
    /**
     * This computed property accesses associated CKRecord. Should reference an optional
     * property that stores record from database (with contained changed tag) or when not
     * set, nil value should trigger fetch from database.
     */
    var record: CKRecord { get set }
}
