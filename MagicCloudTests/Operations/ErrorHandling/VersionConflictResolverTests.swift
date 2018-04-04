//
//  VersionConflictResolverTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 4/2/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class VersionConflictResolverTests: XCTestCase {
    
    // MARK: - Properties
    
    var mock: MockResolver?
    
    var mockReceiver: MCMirror<MockRecordable>?

    var mockRecordable = MockRecordable(created: Date.distantFuture)
    
    let TEST_KEY = "MockValue"

    var dict: [AnyHashable: Any]? {
        var dict = [AnyHashable: Any]()
        
        dict[CKRecordChangedErrorAncestorRecordKey] = previous
        dict[CKRecordChangedErrorClientRecordKey] = attempted
        dict[CKRecordChangedErrorServerRecordKey] = saved
        
        return dict
    }
    
    var previous: CKRecord {
        let rec = CKRecord(recordType: mockRecordable.recordType,
                           recordID: CKRecordID(recordName: "Mock Created: \(Date.distantPast)"))
        rec[TEST_KEY] = Date.distantPast as CKRecordValue
        
        return rec
    }
    
    var saved: CKRecord {
        let rec = CKRecord(recordType: mockRecordable.recordType,
                           recordID: mockRecordable.recordID)
        rec[TEST_KEY] = Date.distantPast as CKRecordValue
        
        return rec
    }
    
    var attempted: CKRecord {
        let rec = CKRecord(recordType: mockRecordable.recordType,
                           recordID: CKRecordID(recordName: "Mock Created: \(Date.distantFuture)"))
        rec[TEST_KEY] = Date.distantFuture as CKRecordValue
        
        return rec
    }
    
    var error: CKError? {
        let error = NSError(domain: CKErrorDomain, code: CKError.serverRecordChanged.rawValue, userInfo: dict as? [String : Any])
        
        return error as? CKError
    }
    
    // MARK: - Functions
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mockReceiver = MCMirror<MockRecordable>(db: .publicDB)
        mock = MockResolver(rec: mockReceiver!, recs: [mockRecordable])
    }
    
    override func tearDown() {
        mockReceiver = nil
        mock = nil
        
        super.tearDown()
    }
    
    // MARK: - Functions: Unit Tests
    
    func testResolvesConflictsByOverwritingAllKeys() {
        guard let cError = error else { XCTFail(); return }
        mock?.resolveVersionConflict(cError, accordingTo: CKRecordSavePolicy.allKeys)
        
        let firstPause = Pause(seconds: 3)
        let cleanUp = MCDelete([mockRecordable], of: mockReceiver!, from: .publicDB)
        let secondPause = Pause(seconds: 2)
        secondPause.addDependency(cleanUp)
        
        var results = [MockRecordable]()
        let verifyOp = MCDownload(type: mockRecordable.recordType, to: mockReceiver!, from: .publicDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = {
            results = self.mockReceiver!.silentRecordables.filter() { $0.recordID.recordName == "Mock Created: \(Date.distantFuture)" }
            OperationQueue().addOperation(cleanUp)
        }
        
        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(firstPause)

        secondPause.waitUntilFinished()

        if let firstEntry = results.first?.recordFields[TEST_KEY] as? Date, let attempted = attempted[TEST_KEY] as? Date {
            XCTAssert(firstEntry == attempted)
        } else {
            XCTFail()
        }
    }
    
    func testResolvesConflictsByOverwritingChangedKeys() {
        guard let cError = error else { XCTFail(); return }
        mock?.resolveVersionConflict(cError, accordingTo: CKRecordSavePolicy.changedKeys)
        
        let firstPause = Pause(seconds: 3)
        let cleanUp = MCDelete([mockRecordable], of: mockReceiver!, from: .publicDB)
        let secondPause = Pause(seconds: 2)
        secondPause.addDependency(cleanUp)
        
        var result = [MockRecordable]()
        let verifyOp = MCDownload(type: mockRecordable.recordType, to: mockReceiver!, from: .publicDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = {
            result = self.mockReceiver!.silentRecordables.filter() { $0.recordID.recordName == "Mock Created: \(Date.distantFuture)" }
            OperationQueue().addOperation(cleanUp)
        }
        
        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(firstPause)
        
        secondPause.waitUntilFinished()
        
        if let firstEntry = result.first?.recordFields[TEST_KEY] as? Date, let attempted = attempted[TEST_KEY] as? Date {
            XCTAssert(firstEntry == attempted)
        } else {
            XCTFail()
        }
    }
    
    func testResolvesConflictsByIgnoringWhenDifferent() {
        guard let cError = error else { XCTFail(); return }
        mock?.resolveVersionConflict(cError, accordingTo: CKRecordSavePolicy.ifServerRecordUnchanged)
        
        let expect = expectation(description: "wait for changes")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { expect.fulfill() }
        
        wait(for: [expect], timeout: 5)
        
        // With no changes to make, no record should be in the database to download.
        XCTAssert(self.mockReceiver?.silentRecordables.count == 0)
    }
}

// MARK: - Mocks

class MockResolver: Operation, MCDatabaseModifier, MCCloudErrorHandler {
    
    var receiver: MCMirror<MockRecordable>
    
    var recordables: [MockResolver.R.type]
    
    typealias R = MCMirror<MockRecordable>

    var database: MCDatabase
    
    init(rec: MCMirror<MockRecordable>, recs: [MockRecordable]) {
        receiver = rec
        database = rec.db
        recordables = recs
    }
}

extension MockResolver: VersionConflictResolver { }
