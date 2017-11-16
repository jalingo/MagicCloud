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

    var testOp: Download<MockReceiver>?
    
    var mock = MockRecordable()
    
    var mockRec = MockReceiver()
    
    // MARK: - Functions
    
    // MARK: - Functions: Unit Tests
    
    func testDownloadByTypeIsOp() { XCTAssertNotNil(testOp?.isFinished) }
    
    func testDownloadByTypeHasReceiver() { XCTAssertNotNil(testOp?.receiver) }
    
    func testDownloadByTypeHasLimit() {
        testOp?.limit = 1
        XCTAssertNotNil(testOp?.limit)
    }
    
    func testDownloadByTypeHasIgnoreUnknown() {
        let nullAction: OptionalClosure = { }
        testOp?.ignoreUnknownItemCustomAction = nullAction
        XCTAssertNotNil(testOp?.ignoreUnknownItemCustomAction)
    }
    
    func testDownloadByQueryWorksWithPrivate() {

        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload([mock], from: mockRec, to: .privateDB)
        let pause0 = Pause(seconds: 4)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        if let key = mock.recordFields.first?.key, let value = mock.recordFields[key] {
            testOp = Download(type: mock.recordType,
                              queryField: key,
                              queryValues: [value],
                              to: mockRec,
                              from: .privateDB)

            // This operation will be used to clean up the database after the test finishes.
            let cleanUp = Delete([mock], from: mockRec, to: .privateDB)
            let pause1 = Pause(seconds: 2)
            testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
            
            cleanUp.addDependency(pause1)

            CloudQueue().addOperation(cleanUp)
            
            let expect = expectation(description: "reciever.recordables updated")
            cleanUp.completionBlock = { expect.fulfill() }

            CloudQueue().addOperation(testOp!)
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
        let mocks = [mock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks, from: mockRec, to: .publicDB)
        let pause0 = Pause(seconds: 3)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        if let key = mock.recordFields.first?.key, let value = mock.recordFields[key] {
            testOp = Download(type: mock.recordType,
                              queryField: key,
                              queryValues: [value],
                              to: mockRec,
                              from: .publicDB)
            
            // This operation will be used to clean up the database after the test finishes.
            let cleanUp = Delete(mocks, from: mockRec, to: .publicDB)
            let pause1 = Pause(seconds: 2)
            testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
            
            cleanUp.addDependency(pause1)
            
            CloudQueue().addOperation(cleanUp)
            
            let expect = expectation(description: "reciever.recordables updated")
            cleanUp.completionBlock = { expect.fulfill() }
            
            CloudQueue().addOperation(testOp!)
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
        let database = DatabaseType.privateDB

        let reference = CKReference(recordID: mock.recordID, action: .deleteSelf)
        let ownedMock = MockReferable()
        ownedMock.attachReference(reference: reference)
        
        let mocks = [ownedMock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks, from: mockRec, to: database)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        testOp = Download(type: ownedMock.recordType, to: mockRec, from: database)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks, from: mockRec, to: database)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)

        // Evaluates results.
        if let result = mockRec.recordables.first {
            XCTAssert(ownedMock.recordID == result.recordID)
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByRefWorksWithPublic() {
        let database = DatabaseType.publicDB
        
        let reference = CKReference(recordID: mock.recordID, action: .deleteSelf)
        let ownedMock = MockReferable()
        ownedMock.attachReference(reference: reference)
        
        let mocks = [ownedMock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks, from: mockRec, to: database)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        testOp = Download(type: ownedMock.recordType, to: mockRec, from: database)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks, from: mockRec, to: database)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        
        // Evaluates results.
        if let result = mockRec.recordables.first {
            XCTAssert(ownedMock.recordID == result.recordID)
        } else {
            XCTFail()
        }
    }

    func testDownloadByTypeWorksWithPrivate() {
        let mocks = [mock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks, from: mockRec, to: .privateDB)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 30)

        testOp = Download(type: mock.recordType, to: mockRec, from: .privateDB)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks, from: mockRec, to: .privateDB)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)

        wait(for: [expect], timeout: 10)
        XCTAssertEqual(mocks, mockRec.recordables)
    }
    
    func testDownloadByTypeWorksWithPublic() {
        let mocks = [mock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks, from: mockRec, to: .publicDB)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        testOp = Download(type: mock.recordType, to: mockRec, from: .publicDB)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks, from: mockRec, to: .publicDB)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        
        wait(for: [expect], timeout: 10)
        XCTAssert(mocks == mockRec.recordables)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mock = MockRecordable()
        mockRec = MockReceiver()
        
        testOp = Download(type: mock.recordType, to: mockRec, from: .publicDB)
    }
    
    override func tearDown() {
        testOp = nil
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        super.tearDown()
    }
}
