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

    var mock: MCReferable?
    
    // MARK: - Functions
    
    // MARK: - Functions: Unit Tests
    
    func testReferableIsProtocol() { XCTAssertNotNil(mock) }

    func testReferableIsRecordable() { XCTAssert(mock is MCRecordable) }
    
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

// MARK: - Mocks

class MockReferable: MockRecordable, MCReferable {
    
    // MARK: - Properties
    
    let REC_TYPE = "MockReferable"
    let REFS_KEY = OWNER_KEY
    
    // MARK: - Properties: Referrable
    
    fileprivate var owners: [CKReference]?
    
    var references: [CKReference] { return owners ?? [CKReference]() }
    
    // MARK: - Properties: Recordable
    
    /**
     * This is a token used with cloudkit to build CKRecordID for this object's CKRecord.
     */
    override var recordType: String { return REC_TYPE }
    
    // MARK: - Functions: Referrable
    
    func attachReference(reference: CKReference) {
        guard owners != nil else { owners = [reference]; return }
        
        owners?.append(reference)
    }
    
    func detachReference(reference: CKReference) {
        if let index = owners?.index(of: reference) { owners?.remove(at: index) }
    }
}
