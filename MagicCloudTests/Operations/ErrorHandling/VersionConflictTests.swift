//
//  VersionConflictTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/22/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class VersionConflictTests: XCTestCase {
    
    // MARK: - Properties
    
    let TEST_KEY = "MockValue"
    
    var testOp: VersionConflict<MockReceiver>?
    
    var mock: MCRecordable?

    var mockRec = MockReceiver() {
didSet { print("ø- instantiating MockReceiver") }
    }
    
    var dict: [AnyHashable: Any]? {
        var dict = [AnyHashable: Any]()
        
        dict[CKRecordChangedErrorAncestorRecordKey] = previous
        dict[CKRecordChangedErrorClientRecordKey] = attempted
        dict[CKRecordChangedErrorServerRecordKey] = saved
        
        return dict
    }

    var previous: CKRecord?
    
    var _previous: CKRecord {
        let rec = CKRecord(recordType: mock!.recordType, recordID: CKRecordID(recordName: "Distant-Past"))
        rec[TEST_KEY] = Date.distantPast as CKRecordValue

        return rec
    }

    var saved: CKRecord?
    
    var _saved: CKRecord {
        let rec = CKRecord(recordType: mock!.recordType, recordID: mock!.recordID)
        rec[TEST_KEY] = Date.distantPast as CKRecordValue

        return rec
    }

    var attempted: CKRecord?
    
    var _attempted: CKRecord {
        let rec = CKRecord(recordType: mock!.recordType, recordID: CKRecordID(recordName: "MockIdentifier: 4001-01-01 00:00:00 +0000"))
        rec[TEST_KEY] = Date.distantFuture as CKRecordValue

        return rec
    }
    
    // MARK: - Functions
    
    func loadInfo() {
        previous = _previous
        saved = _saved
        attempted = _attempted
        
        mockRec = MockReceiver()
    }

    func nullifyInfo() {
        previous = nil
        saved = nil
        attempted = nil
    }
    
    func loadTestOp() {
        let error = NSError(domain: CKErrorDomain, code: CKError.serverRecordChanged.rawValue, userInfo: dict as? [String : Any])
        testOp = VersionConflict(rec: mockRec,
                                 error: CKError(_nsError: error),
                                 target: .privateDB,
                                 policy: .changedKeys,
                                 instances: [mock as! MockRecordable],
                                 completionBlock: nil)
    }
    
    // MARK: - Functions: Unit Tests

    func testVersionConflictResolvesAsChangedKeys() {
        // default policy == .changedKeys

        let firstPause = Pause(seconds: 3)
        firstPause.addDependency(testOp!)
        
        let cleanUp = MCDelete([mock as! MockRecordable], of: mockRec, from: .privateDB)
        
        let secondPause = Pause(seconds: 2)
        secondPause.addDependency(cleanUp)

        let verifyOp = MCDownload(type: mock!.recordType, to: mockRec, from: .privateDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = { OperationQueue().addOperation(cleanUp) }

        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(firstPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(testOp!)
        
        secondPause.waitUntilFinished()
        
        let result = mockRec.recordables.filter() { $0.recordID.recordName == "MockIdentifier: 4001-01-01 00:00:00 +0000" } // <- RecordName for MockRecordable dependent on date field.
        if let firstEntry = result.first?.recordFields[TEST_KEY] as? Date, let attempted = attempted?[TEST_KEY] as? Date {
            XCTAssert(firstEntry == attempted)
        } else {
            XCTFail()
        }
    }
    
    func testVersionConflictResolvesAsAllKeys() {
        testOp?.policy = .allKeys
        
        let firstPause = Pause(seconds: 3)
        firstPause.addDependency(testOp!)
        
        let cleanUp = MCDelete([mock as! MockRecordable], of: mockRec, from: .privateDB)
        
        let secondPause = Pause(seconds: 2)
        secondPause.addDependency(cleanUp)
        
        let verifyOp = MCDownload(type: mock!.recordType, to: mockRec, from: .privateDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = { OperationQueue().addOperation(cleanUp) }
        
        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(firstPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(testOp!)
        
        secondPause.waitUntilFinished()
        
        let result = mockRec.recordables.filter() { $0.recordID.recordName == "MockIdentifier: 4001-01-01 00:00:00 +0000" }    // <-- RecordName for MockRecordable dependent on date field.
        if let firstEntry = result.first?.recordFields[TEST_KEY] as? Date, let attempted = attempted?[TEST_KEY] as? Date {
            XCTAssert(firstEntry == attempted)
        } else {
            XCTFail()
        }
    }
    
    func testVersionConflictResolvesAsUnchanged() {
        testOp?.policy = .ifServerRecordUnchanged
        
        let firstPause = Pause(seconds: 3)
        firstPause.addDependency(testOp!)

        let verifyOp = MCDownload(type: mock!.recordType, to: mockRec, from: .privateDB)
        verifyOp.addDependency(firstPause)
        
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(firstPause)
        OperationQueue().addOperation(testOp!)
        
        verifyOp.waitUntilFinished()
        
        // With no changes to make, no record should be in the database to download.
        XCTAssert(mockRec.recordables.count == 0)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
        
        mock = MockRecordable()
        loadInfo()
        loadTestOp()
    }
    
    override func tearDown() {
        mock = nil
        testOp = nil
        nullifyInfo()
        
        super.tearDown()
    }
}
