//
//  Recordable.swift
//  Voyage
//
//  Created by Jimmy Lingo on 8/31/16.
//  Copyright © 2016 lingoTECH Solutions. All rights reserved.
//

import CloudKit

// MARK: - Protocol: Recordable

/**
 * The Recordable protocol ensures that any conforming instances have what is necessary
 * to be recorded in the cloud database. Conformance to this protocol is also necessary
 * to interact with the generic cloud functionality in this workspace.
 */
public protocol Recordable {
    
    /**
     * This database is used to determine whether conforming instance is stored in the
     * public or private cloud database.
     */
//    var database: CKDatabase { get set }    // <-- Deprecated ??
    
    /**
     * This is a token used with cloudkit to build CKRecordID for this object's CKRecord.
     */
    var recordType: String { get }
    
    /**
     * This dictionary has to match all of the keys used in CKRecord in order for version
     * conflicts and retry attempts to succeed. Its values should match the associated
     * fields in CKRecord.
     */
    var recordFields: Dictionary<String, CKRecordValue> { get set }
    
    /**
     * A record identifier used to store and recover conforming instance's record. This ID is
     * used to construct records and references, as well as query and fetch from the cloud
     * database.
     *
     * - Warning: Must be unique in the database.
     */
    var recordID: CKRecordID { get set }
    
    /// This requires a 'blank' init for preparation from record values.
    init()
}

// MARK: - Mock

/// Mock instance that only conforms to `Recordable` for testing and prototype development.
class MockRecordable: Recordable {
    
    // MARK: - Properties
        
    var created = Date()
    
    // MARK: - Properties: Static Values
    
    static let key = "MockValue"
    static let mockType = "MockRecordable"
    
    // MARK: - Properties: Recordable
    
    var recordType: String { return MockRecordable.mockType }
    
    var recordFields: Dictionary<String, CKRecordValue> {
        get { return [MockRecordable.key: created as CKRecordValue] }
        set {
            if let date = newValue[MockRecordable.key] as? Date { created = date }
        }
    }
    
    var recordID: CKRecordID {
        get {
            return CKRecordID(recordName: "MockIdentifier: \(String(describing: created))")
        }
        
        set {
            var str = newValue.recordName
            if let range = str.range(of: "MockIdentifier: ") {
                str.removeSubrange(range)
                if let date = DateFormatter().date(from: str) { created = date }
            }
        }
    }
    
    // MARK: - Functions: Constructor
    
    required init() { }
    
    init(created: Date? = nil) {
        if let date = created { self.created = date }
    }
}
