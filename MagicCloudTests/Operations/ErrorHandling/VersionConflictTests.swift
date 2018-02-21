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
    
    var testOp: VersionConflict<MCMirror<MockRecordable>>?
    
    var mock: MockRecordable?

    var mockRec: MCMirror<MockRecordable>?
    
    var dict: [AnyHashable: Any]? {
        var dict = [AnyHashable: Any]()
        
        dict[CKRecordChangedErrorAncestorRecordKey] = previous
        dict[CKRecordChangedErrorClientRecordKey] = attempted
        dict[CKRecordChangedErrorServerRecordKey] = saved
        
        return dict
    }

    var previous: CKRecord?
    
    var _previous: CKRecord {
        let rec = CKRecord(recordType: mock!.recordType, recordID: CKRecordID(recordName: "MockIdentifier: \(Date.distantPast)"))
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
        let rec = CKRecord(recordType: mock!.recordType, recordID: CKRecordID(recordName: "MockIdentifier: \(Date.distantFuture)"))
        rec[TEST_KEY] = Date.distantFuture as CKRecordValue

        return rec
    }
    
    // MARK: - Functions
    
    func loadInfo() {
        previous = _previous
        saved = _saved
        attempted = _attempted
        
        mockRec = MCMirror<MockRecordable>(db: .publicDB)
    }

    func nullifyInfo() {
        previous = nil
        saved = nil
        attempted = nil
    }
    
    func loadTestOp() {
        let error = NSError(domain: CKErrorDomain, code: CKError.serverRecordChanged.rawValue, userInfo: dict as? [String : Any])
        testOp = VersionConflict(rec: mockRec!,
                                 error: CKError(_nsError: error),
                                 target: .privateDB,
                                 policy: .changedKeys,
                                 instances: [mock!],
                                 completionBlock: nil)
    }
    
    // MARK: - Functions: Unit Tests

    func testVersionConflictResolvesAsChangedKeys() {
        // default policy == .changedKeys

        let firstPause = Pause(seconds: 3)
        firstPause.addDependency(testOp!)
        
        let cleanUp = MCDelete([mock!], of: mockRec!, from: .privateDB)
        
        let secondPause = Pause(seconds: 2)
        secondPause.addDependency(cleanUp)

        let verifyOp = MCDownload(type: mock!.recordType, to: mockRec!, from: .privateDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = { OperationQueue().addOperation(cleanUp) }

        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(firstPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(testOp!)
        
        secondPause.waitUntilFinished()
        
        let result = mockRec!.silentRecordables.filter() { $0.recordID.recordName == "MockIdentifier: \(Date.distantFuture)" }
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
        
        let cleanUp = MCDelete([mock!], of: mockRec!, from: .privateDB)
        
        let secondPause = Pause(seconds: 2)
        secondPause.addDependency(cleanUp)
        
        let verifyOp = MCDownload(type: mock!.recordType, to: mockRec!, from: .privateDB)
        verifyOp.addDependency(firstPause)
        verifyOp.completionBlock = { OperationQueue().addOperation(cleanUp) }
        
        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(firstPause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(testOp!)
        
        secondPause.waitUntilFinished()
        
        let result = mockRec!.silentRecordables.filter() { $0.recordID.recordName == "MockIdentifier: \(Date.distantFuture)" }
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

        let verifyOp = MCDownload(type: mock!.recordType, to: mockRec!, from: .privateDB)
        verifyOp.addDependency(firstPause)
        
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(firstPause)
        OperationQueue().addOperation(testOp!)
        
        verifyOp.waitUntilFinished()
        
        // With no changes to make, no record should be in the database to download.
        XCTAssert(mockRec!.silentRecordables.count == 0)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
        
        mock = MockRecordable()
        loadInfo()
        loadTestOp()
        
        mockRec = MCMirror<MockRecordable>(db: .publicDB)
    }
    
    override func tearDown() {
        mock = nil
        testOp = nil
        nullifyInfo()

        mockRec = nil
        
        super.tearDown()
    }
}
