//
//  DownloadTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/17/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class DownloadTests: XCTestCase {
    
    // MARK: - Properties

    let start = Date()

    var testOp: MCDownload<MockReceiver>?
    
    var mock = MockRecordable()
    
    var mocks = [MockRecordable]()
    
    var mockRec = MockReceiver()
    
    var shouldCleanPublic = false
    
    var shouldCleanPrivate = false
    
    // MARK: - Functions
    
    func prepareDatabase(db: MCDatabase = .publicDB) -> Int {
        let op = MCUpload(mocks, from: mockRec, to: db)
        let pause = Pause(seconds: 3)
        pause.addDependency(op)

        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        db.description == MCDatabase.publicDB.description ? (shouldCleanPublic = true) : (shouldCleanPrivate = false)
    
        return 0
    }
    
    func cleanUpDatabase(db: MCDatabase = .publicDB) -> Int {
        let op = MCDelete(mocks, of: mockRec, from: db)
        let pause = Pause(seconds: 2)
        pause.addDependency(op)
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    // MARK: - Functions: Unit Tests
    
    func testDownloadByTypeIsOp() { XCTAssertNotNil(testOp?.isFinished) }
    
    func testDownloadByTypeHasReceiver() { XCTAssertNotNil(testOp?.receiver) }
    
    func testDownloadByTypeHasLimit() {
        testOp?.limit = 1
        XCTAssertNotNil(testOp?.limit)
    }
    
    func testDownloadByTypeHasIgnoreUnknown() {
        let nullAction: OptionalClosure = { }
        testOp?.unknownItemCustomAction = nullAction
        XCTAssertNotNil(testOp?.unknownItemCustomAction)
    }
    
    func testDownloadByQueryWorksWithPrivate() {

        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase(db: .privateDB)
        mockRec.silentRecordables = []
        
        if let key = mock.recordFields.first?.key, let value = mock.recordFields[key] {
            testOp = MCDownload(type: mock.recordType,
                                queryField: key,
                                queryValues: [value],
                                to: mockRec,
                                from: .privateDB)
            
            let expect = expectation(description: "reciever.recordables updated")
            testOp?.completionBlock = { expect.fulfill() }

            OperationQueue().addOperation(testOp!)
            wait(for: [expect], timeout: 10)

            // Evaluates results.
            if let result = mockRec.silentRecordables.first {
                XCTAssert(mock == result)
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }

    func testDownloadByQueryWorksWithPublic() {
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase()
        
        if let key = mock.recordFields.first?.key, let value = mock.recordFields[key] {
            testOp = MCDownload(type: mock.recordType,
                                queryField: key,
                                queryValues: [value],
                                to: mockRec,
                                from: .publicDB)
            
            let expect = expectation(description: "reciever.recordables updated")
            testOp?.completionBlock = { expect.fulfill() }
            
            OperationQueue().addOperation(testOp!)
            wait(for: [expect], timeout: 10)
            
            // Evaluates results.
            if let result = mockRec.silentRecordables.first {
                XCTAssert(mock == result)
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByRefWorksWithPrivate() {
        let reference = CKReference(recordID: mock.recordID, action: .deleteSelf)
        let ownedMock = MockReferable()
        ownedMock.recordID = CKRecordID(recordName: "ReferencedMock")
        ownedMock.owner = reference
        
        mocks = [ownedMock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase(db: .privateDB)
        
        testOp = MCDownload(type: ownedMock.recordType, to: mockRec, from: .privateDB)
        
        let expect = expectation(description: "reciever.recordables updated")
        testOp?.completionBlock = { expect.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)

        // Evaluates results.
        XCTAssert(mockRec.silentRecordables.contains(ownedMock))
        if let result = mockRec.silentRecordables.first {
            XCTAssert(ownedMock.recordID.recordName == result.recordID.recordName)
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByRefWorksWithPublic() {
        let reference = CKReference(recordID: mock.recordID, action: .deleteSelf)
        let ownedMock = MockReferable()
        ownedMock.recordID = CKRecordID(recordName: "ReferencedMock")
        ownedMock.owner = reference
        
        mocks = [ownedMock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase()
        
        testOp = MCDownload(type: ownedMock.recordType, to: mockRec, from: .publicDB)
        
        let expect = expectation(description: "reciever.recordables updated")
        testOp?.completionBlock = { expect.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        
        // Evaluates results.
        if let result = mockRec.silentRecordables.first {
            XCTAssert(ownedMock.recordID == result.recordID)
        } else {
            XCTFail()
        }
    }

    func testDownloadByTypeWorksWithPrivate() {
        let recordablesDidSet = expectation(forNotification: mockRec.changeNotification, object: nil, handler: nil)

        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase(db: .privateDB)

        testOp = MCDownload(type: mock.recordType, to: mockRec, from: .privateDB)
        OperationQueue().addOperation(testOp!)
        
        wait(for: [recordablesDidSet], timeout: 15)
        XCTAssertEqual(mocks, mockRec.silentRecordables)
    }
    
    func testDownloadByTypeWorksWithPublic() {
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase()
        
        testOp = MCDownload(type: mock.recordType, to: mockRec, from: .publicDB)
        
        let expect = expectation(description: "reciever.recordables updated")
        testOp?.completionBlock = { expect.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        XCTAssert(mocks == mockRec.silentRecordables)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        shouldCleanPublic = false
        shouldCleanPrivate = false

        mock = MockRecordable(created: Date())
        mockRec = MockReceiver()
        mocks = [mock]

        testOp = MCDownload(type: mock.recordType, to: mockRec, from: .publicDB)
    }
    
    override func tearDown() {
        testOp = nil

        if shouldCleanPublic { let _ = cleanUpDatabase() }
        if shouldCleanPrivate { let _ = cleanUpDatabase(db: .privateDB) }
        
        super.tearDown()
    }
}

class MockReferable: MockRecordable {
    
    let ownerKey = "MockOwner"
    
    var owner: CKReference?
    
    override var recordFields: Dictionary<String, CKRecordValue> {
        get {
            var dictionary = [String: CKRecordValue]()
            
            dictionary[MockRecordable.key] = self.created as CKRecordValue
            dictionary[ownerKey] = owner
            
            return dictionary
        }
        
        set {
            if let date = newValue[MockRecordable.key] as? Date { created = date }
            if let ref = newValue[ownerKey] as? CKReference { owner = ref }
        }
    }
}
