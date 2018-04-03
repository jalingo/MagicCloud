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

    var mockRecordable = MockRecordable()
    
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
                           recordID: CKRecordID(recordName: "MockIdentifier: \(Date.distantPast)"))
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
                           recordID: CKRecordID(recordName: "MockIdentifier: \(Date.distantFuture)"))
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
        
        mock = MockResolver()
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
        
        let verifyOp = MCDownload(type: mockRecordable.recordType, to: mockReceiver!, from: .publicDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = { OperationQueue().addOperation(cleanUp) }
        
        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(firstPause)

        secondPause.waitUntilFinished()
        
        let result = mockReceiver!.silentRecordables.filter() { $0.recordID.recordName == "MockIdentifier: \(Date.distantFuture)" }
        if let firstEntry = result.first?.recordFields[TEST_KEY] as? Date, let attempted = attempted[TEST_KEY] as? Date {
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
        
        let verifyOp = MCDownload(type: mockRecordable.recordType, to: mockReceiver!, from: .publicDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = { OperationQueue().addOperation(cleanUp) }
        
        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(firstPause)
        
        secondPause.waitUntilFinished()
        
        let result = mockReceiver!.silentRecordables.filter() { $0.recordID.recordName == "MockIdentifier: \(Date.distantFuture)" }
        if let firstEntry = result.first?.recordFields[TEST_KEY] as? Date, let attempted = attempted[TEST_KEY] as? Date {
            XCTAssert(firstEntry == attempted)
        } else {
            XCTFail()
        }
    }
    
    func testResolvesConflictsByIgnoringWhenDifferent() {
        guard let cError = error else { XCTFail(); return }
        mock?.resolveVersionConflict(cError, accordingTo: CKRecordSavePolicy.ifServerRecordUnchanged)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            // With no changes to make, no record should be in the database to download.
            XCTAssert(self.mockReceiver?.silentRecordables.count == 0)
        }
    }
}

// MARK: - Mocks

class MockResolver: Operation, MCDatabaseModifier, MCCloudErrorHandler {
    
    var receiver: MCMirror<MockRecordable>
    
    var recordables = [MockResolver.R.type]()
    
    typealias R = MCMirror<MockRecordable>

    var database: MCDatabase = .publicDB
    
    override init() {
        receiver = MCMirror<MockRecordable>(db: database)
    }
}

extension MockResolver: VersionConflictResolver { }
