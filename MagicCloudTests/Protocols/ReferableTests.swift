//
//  ReferableTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit
import XCTest

class ReferableTests: XCTestCase {
    
    // MARK: - Properties

    var mock: Referable?
    
    // MARK: - Functions
    
    // MARK: - Functions: Unit Tests
    
    func testReferableIsProtocol() { XCTAssertNotNil(mock) }

    func testReferableIsRecordable() { XCTAssert(mock is Recordable) }
    
    func testReferableHasRefs() { XCTAssertNotNil(mock?.references) }
    
    func testReferableCanAttachRefs() {
        guard mock != nil else { XCTFail(); return }
        
        let id = CKRecordID(recordName: "TestReference")
        let mockRef = CKReference(recordID: id, action: .deleteSelf)
        
        mock?.attachReference(reference: mockRef)
        
        XCTAssert(mock!.references.contains(mockRef))
    }
    
    func testReferableCanDetachRefs() {
        guard mock != nil else { XCTFail(); return }

        let id = CKRecordID(recordName: "TestReference")
        let mockRef = CKReference(recordID: id, action: .deleteSelf)
        
        mock?.attachReference(reference: mockRef)
        mock?.detachReference(reference: mockRef)
        
        XCTAssertFalse(mock!.references.contains(mockRef))
    }

    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mock = MockReferable()
    }
    
    override func tearDown() {
        mock = nil
        
        super.tearDown()
    }
}
