//
//  Referable.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/// This key should be used for storing references in a CKRecord, to allow 'Download' by reference to work.
let OWNER_KEY = "Owners"

/**
 * The Referable protocol ensures that any conforming instances have what is necessary
 * to be referenced by an owner record in the cloud database. For that relationship
 * to be reflected in the cloud database, conforming instances must also conform to the
 * Recordable protocol and it's 'Recordable.recordFields' dictionary must be amended to
 * store collected CKReferences.
 */
public protocol Referable: Recordable {
    
    // MARK: - Properties
    
    /**
     * This array stores a conforming instance's CKReferences used as database
     * relationships. Instance is owned by each record that is referenced in the
     * array (supports multiple ownership).
     */
    var references: [CKReference] { get }
    
    // MARK: - Functions
    
    /**
     * This method is used to store new ownership relationship in references array,
     * and to ensure that cloud data model reflects such changes. If necessary, ensures
     * that owned instance has only a single reference in its list of references.
     *
     * - CAUTION: 'OWNER_KEY' must be used for references' field for compatibility with
     *            'Download' operation.
     */
    mutating func attachReference(reference: CKReference)
    
    /**
     * This method is used to store new ownership relationship in references array,
     * and to ensure that cloud data model reflects such changes. If object has no
     * references, it may need to be deleted from database (which would happen here).
     */
    mutating func detachReference(reference: CKReference)
}

// MARK: - Mocks

class MockReferable: Referable {
    
    // MARK: - Properties
    
    let REC_TYPE = "MockReferable"
    let REFS_KEY = OWNER_KEY
    
    var created = Date().description
    
    // MARK: - Properties: Referrable
    
    fileprivate var owners: [CKReference]?
    
    var references: [CKReference] { return owners ?? [CKReference]() }
    
    // MARK: - Properties: Recordable
    
    /**
     * This database is used to determine whether conforming instance is stored in the
     * public or private cloud database.
     */
    var database: CKDatabase = CKContainer.default().privateCloudDatabase
    
    /**
     * This is a token used with cloudkit to build CKRecordID for this object's CKRecord.
     */
    var recordType: String { return REC_TYPE }
    
    /**
     * This dictionary has to match all of the keys used in CKRecord in order for version
     * conflicts and retry attempts to succeed. Its values should match the associated
     * fields in CKRecord.
     */
    var recordFields: Dictionary<String, CKRecordValue> {
        get {
            return [REFS_KEY: references as CKRecordValue]
        }
        
        set {
            owners = newValue[REFS_KEY] as? [CKReference]
        }
    }
    
    /**
     * A record identifier used to store and recover conforming instance's record. This ID is
     * used to construct records and references, as well as query and fetch from the cloud
     * database.
     *
     * - Warning: Must be unique in the database.
     */
    var recordID: CKRecordID {//= CKRecordID(recordName: "Mock Referable")
        get { return CKRecordID(recordName: created) }
        set { created = newValue.recordName }
    }
    
    // MARK: - Functions: Referrable
    
    func attachReference(reference: CKReference) {
        guard owners != nil else { owners = [reference]; return }
        
        owners?.append(reference)
    }
    
    func detachReference(reference: CKReference) {
        if let index = owners?.index(of: reference) { owners?.remove(at: index) }
    }
}

extension MockReferable: Equatable { }

func ==(left: MockReferable, right: MockReferable) -> Bool {
    return left.recordID == right.recordID
}
