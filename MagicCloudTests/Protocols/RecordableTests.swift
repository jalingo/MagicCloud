//
//  RecordableTests.swift
//
//  Created by j.lingo on 10/9/16.
//  Copyright © 2016 j.lingo. All rights reserved.
//
import XCTest
import CloudKit

class RecordableTests: XCTestCase {
    
    // MARK: - Properties
    
    fileprivate let queue = OperationQueue()
    
    fileprivate var mock: Recordable?
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        
        mock = MockRecordable()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Tests: Protocol Conformance
    
    func testRecordableHasRecordType() { XCTAssertNotNil(mock?.recordType) }
    
    func testRecordableHasRecordID() { XCTAssertNotNil(mock?.recordID) }
    
    func testRecordableHasDictionaryOfRecordFields() { XCTAssertNotNil(mock?.recordFields) }
        
    func testRecordableRecordFieldsCanBeSet() {
        let altDate = Date(timeIntervalSince1970: 5)
        let altMock = MockRecordable(created: altDate)
        if let date = altMock.recordFields[MockRecordable.key] as? Date {
            mock?.recordFields[MockRecordable.key] = date as CKRecordValue
            XCTAssert((mock as! MockRecordable).created == altMock.created)
        } else {
            XCTFail()
        }
    }
    
    func testRecordableRequiresBlankInit() {
        XCTAssertNotNil(MockRecordable())
    }
}

// MARK: - Mocks

extension MockRecordable: Equatable { }

func ==(left: MockRecordable, right: MockRecordable) -> Bool {
    return left.created == right.created
}
