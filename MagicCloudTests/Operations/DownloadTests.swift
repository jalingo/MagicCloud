//
//  DownloadTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/17/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class DownloadTests: XCTestCase {
    
    // MARK: - Properties

    let start = Date()

    var testOp: MCDownload<MockReceiver>?
    
    var mock = MockRecordable()
    
    var mocks = [MockRecordable]()
    
    var mockRec = MockReceiver() {
didSet { print("ø- instantiating MockReceiver") }
    }
    
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
        
        if let key = mock.recordFields.first?.key, let value = mock.recordFields[key] {
            testOp = MCDownload(type: mock.recordType,
                                queryField: key,
                                queryValues: [value],
                                to: mockRec,
                                from: .privateDB)

            // This will be used to clean up the database after the test finishes.
            shouldCleanPrivate = true
            
            let expect = expectation(description: "reciever.recordables updated")
            testOp?.completionBlock = { expect.fulfill() }

            OperationQueue().addOperation(testOp!)
            wait(for: [expect], timeout: 10)

            // Evaluates results.
            if let result = mockRec.recordables.first {
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
            
            // This will be used to clean up the database after the test finishes.
            shouldCleanPublic = true
            
            let expect = expectation(description: "reciever.recordables updated")
            testOp?.completionBlock = { expect.fulfill() }
            
            OperationQueue().addOperation(testOp!)
            wait(for: [expect], timeout: 10)
            
            // Evaluates results.
            if let result = mockRec.recordables.first {
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
        
        // This will be used to clean up the database after the test finishes.
        shouldCleanPrivate = true
        
        let expect = expectation(description: "reciever.recordables updated")
        testOp?.completionBlock = { expect.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)

        // Evaluates results.
        XCTAssert(mockRec.recordables.contains(ownedMock))
        if let result = mockRec.recordables.first {
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
        
        // This will be used to clean up the database after the test finishes.
        shouldCleanPublic = true
        
        let expect = expectation(description: "reciever.recordables updated")
        testOp?.completionBlock = { expect.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        
        // Evaluates results.
        if let result = mockRec.recordables.first {
            XCTAssert(ownedMock.recordID == result.recordID)
        } else {
            XCTFail()
        }
    }

    func testDownloadByTypeWorksWithPrivate() {
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase(db: .privateDB)

        testOp = MCDownload(type: mock.recordType, to: mockRec, from: .privateDB)
        
        // This will be used to clean up the database after the test finishes.
        shouldCleanPrivate = true
        
        let expect = expectation(description: "reciever.recordables updated")
        testOp?.completionBlock = { expect.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)

        XCTAssertEqual(mocks, mockRec.recordables)
    }
    
    func testDownloadByTypeWorksWithPublic() {
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let _ = prepareDatabase()
        
        testOp = MCDownload(type: mock.recordType, to: mockRec, from: .publicDB)
        
        // This will be used to clean up the database after the test finishes.
        shouldCleanPublic = true
        
        let expect = expectation(description: "reciever.recordables updated")
        testOp?.completionBlock = { expect.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        XCTAssert(mocks == mockRec.recordables)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        shouldCleanPublic = false
        shouldCleanPrivate = false

        mock = MockRecordable()
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
