//
//  RecordableTests.swift
//  Voyage
//
//  Created by Jimmy Lingo on 8/31/16.
//  Copyright © 2016 lingoTECH Solutions. All rights reserved.
//

import XCTest
import CloudKit

class RecordableTests: XCTestCase {

    // MARK: - Properties (testObjects)

    let mock = mockRecordable()

    // MARK: - Functions

    // MARK: - Functions (methods)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Functions (tests)
    
    func testRecordableHasRecordTypeConstant() { XCTAssertNotNil(mockRecordable.REC_TYPE) }
    
    func testRecordableHasIdentifier() { XCTAssertNotNil(mock.identifier) }
    
    func testRecordableIdentifierMustBeUniqueInDatabase() {
        XCTFail()
    }
    
    func testRecordableHasRecordID() { XCTAssertNotNil(mock.recordID) }
    
    func testRecordableHasRecord() { XCTAssertNotNil(mock.record) }
    
    func testRecordableRecordIsFetchedWhenItExistsInTheDatabase() {
        XCTFail()
    }
}

// MARK: - Structs: Mocks

/**
 * The Recordable protocol ensures that any conforming instances have what is necessary
 * to be recorded in the cloud database. Conformance to this protocol is also necessary
 * to interact with the generic cloud functionality in this workspace.
 */
struct mockRecordable: Recordable {
    
    /**
     * This is a token used with cloudkit to build CKRecordID for this object's CKRecord.
     */
    static var REC_TYPE: String { return "RecordType" }
    
    /**
     * This string identifier is used when constructing a conforming instance's CKRecordID.
     * Said ID is used to construct records and references, as well as query and fetch from
     * the cloud database.
     *
     * Must be unique in the database.
     */
    var identifier: String { return "RecordIdentifier" }
    
    /**
     * A record identifier used to store and recover conforming instance's record.
     */
    var recordID: CKRecordID { return CKRecordID(recordName: identifier) }
    
    /**
     * This computed property accesses associated CKRecord. Should reference an optional
     * property that stores record from database (with contained changed tag) or when not
     * set, nil value should trigger fetch from database.
     */
    var record: CKRecord {
        get {
            return _record ?? CKRecord(recordType: mockRecordable.REC_TYPE,
                                       recordID: recordID)
        }
        
        set { _record = newValue }
    }
    
    /// Active memory storage for 'record' computed property.
    fileprivate var _record: CKRecord?
}

// MARK: - Extensions: Equatable

extension mockRecordable: Equatable { }

func ==(left: mockRecordable, right: mockRecordable) -> Bool {
    guard left.identifier == right.identifier else { return false }
    guard left.recordID == right.recordID else { return false }
    guard left.record == right.record else { return false }
    return true
}
