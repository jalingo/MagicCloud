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

    var testOp: Download?
    
    var mock = MockRecordable()
    
    var mockRec: RecievesRecordable?
    
    // MARK: - Functions
    
    func switchMockToPublic() { mock.database = CKContainer.default().publicCloudDatabase }
    
    func mixOfMocks() -> [MockRecordable] {
        var mix = [mock]

        var pubMock = MockRecordable()
        pubMock.created = Date.distantPast
        pubMock.database = CKContainer.default().publicCloudDatabase
        mix.append(pubMock)

        return mix
    }
    
    // MARK: - Functions: Unit Tests
    
    func testDownloadByTypeIsOp() { XCTAssertNotNil(testOp?.isFinished) }
    
    func testDownloadByTypeHasReciever() { XCTAssertNotNil(testOp?.reciever) }
    
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
        let database = CKContainer.default().privateCloudDatabase

        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload([mock])
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
                              to: mockRec!,
                              from: database)

            // This operation will be used to clean up the database after the test finishes.
            let cleanUp = Delete([mock])
            let pause1 = Pause(seconds: 2)
            testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
            
            cleanUp.addDependency(pause1)

            CloudQueue().addOperation(cleanUp)
            
            let expect = expectation(description: "reciever.recordables updated")
            cleanUp.completionBlock = { expect.fulfill() }

            CloudQueue().addOperation(testOp!)
            wait(for: [expect], timeout: 10)

            // Evaluates results.
            if let result = mockRec?.recordables.first as? MockRecordable {
                XCTAssert(mock == result)
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }

    func testDownloadByQueryWorksWithPublic() {
        let database = CKContainer.default().publicCloudDatabase
        switchMockToPublic()
        let mocks = [mock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
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
                              to: mockRec!,
                              from: database)
            
            // This operation will be used to clean up the database after the test finishes.
            let cleanUp = Delete(mocks)
            let pause1 = Pause(seconds: 2)
            testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
            
            cleanUp.addDependency(pause1)
            
            CloudQueue().addOperation(cleanUp)
            
            let expect = expectation(description: "reciever.recordables updated")
            cleanUp.completionBlock = { expect.fulfill() }
            
            CloudQueue().addOperation(testOp!)
            wait(for: [expect], timeout: 10)
            
            // Evaluates results.
            if let result = mockRec?.recordables.first as? MockRecordable {
                XCTAssert(mock == result)
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByQueryWorksWithPrivateAndPublic() {
        let mocks = mixOfMocks()
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
        let pause0 = Pause(seconds: 4)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 20)
        
        if let key = mock.recordFields.first?.key, let value = mock.recordFields[key] {

            // need values from both mocks...
            let pubVal = mocks[1].recordFields[key]!
            var values = [pubVal]
            values.append(value)
            
            testOp = Download(type: mock.recordType, queryField: key, queryValues: values, to: mockRec!)

            // This operation will be used to clean up the database after the test finishes.
            let cleanUp = Delete(mocks)
            let pause1 = Pause(seconds: 5)
            testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
            
            cleanUp.addDependency(pause1)
            
            CloudQueue().addOperation(cleanUp)
            
            let expect = expectation(description: "reciever.recordables updated")
            cleanUp.completionBlock = { expect.fulfill() }
            
            CloudQueue().addOperation(testOp!)
            wait(for: [expect], timeout: 15)
            
            // Evaluates results.
            if let results = mockRec?.recordables as? [MockRecordable] {
                let sortedResults = results.sorted() { $0.created > $1.created }
                XCTAssert(mocks == sortedResults)
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }

    func testDownloadByRefWorksWithPrivate() {
        let database = CKContainer.default().privateCloudDatabase

        let reference = CKReference(recordID: mock.recordID, action: .deleteSelf)
        let ownedMock = MockReferable()
        ownedMock.attachReference(reference: reference)
        
        let mocks = [ownedMock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        testOp = Download(type: ownedMock.recordType, to: mockRec!, from: database)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)

        // Evaluates results.
        if let result = mockRec?.recordables.first as? MockReferable {
            XCTAssert(ownedMock.recordID == result.recordID)
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByRefWorksWithPublic() {
        let database = CKContainer.default().publicCloudDatabase
        switchMockToPublic()
        
        let reference = CKReference(recordID: mock.recordID, action: .deleteSelf)
        let ownedMock = MockReferable()
        ownedMock.attachReference(reference: reference)
        ownedMock.database = database
        
        let mocks = [ownedMock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        testOp = Download(type: ownedMock.recordType, to: mockRec!, from: database)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        
        // Evaluates results.
        if let result = mockRec?.recordables.first as? MockReferable {
            XCTAssert(ownedMock.recordID == result.recordID)
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByRefWorksWithPrivateAndPublic() {
        let reference = CKReference(recordID: mock.recordID, action: .deleteSelf)

        let pubOwned = MockReferable()
        pubOwned.database = CKContainer.default().publicCloudDatabase
        let priOwned = MockReferable()
        priOwned.database = CKContainer.default().privateCloudDatabase
        let mocks = [pubOwned, priOwned]
        
        for mock in mocks { mock.attachReference(reference: reference) }
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
        let pause0 = Pause(seconds: 3)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 12)

        testOp = Download(type: priOwned.recordType, ownedBy: mock, to: mockRec!)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        
        // Evaluates results.
        if let result = mockRec?.recordables as? [MockReferable] {
            XCTAssert(result == mocks)
        } else {
            XCTFail()
        }
    }

    func testDownloadByTypeWorksWithPrivate() {
        let mocks = [mock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)

        testOp = Download(type: mock.recordType, to: mockRec!, from: mock.database)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
print("mocks: \(mocks.count) :: \(mocks.map { $0.created })")
print("results: \(mockRec!.recordables.count)")
        // Evaluates results.
        if let results = mockRec?.recordables as? [MockRecordable] {
            XCTAssert(mocks == results)
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByTypeWorksWithPublic() {
        switchMockToPublic()
        
        let mocks = [mock]
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        testOp = Download(type: mock.recordType, to: mockRec!, from: mock.database)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        
        // Evaluates results.
        if let results = mockRec?.recordables as? [MockRecordable] {
            XCTAssert(mocks == results)
        } else {
            XCTFail()
        }
    }
    
    func testDownloadByTypeWorksWithPrivateAndPublic() {
        let mocks = mixOfMocks()
        
        // This operation will be used to ensure mocks are already present in cloud database.
        let prepOp = Upload(mocks)
        let pause0 = Pause(seconds: 5)
        prepOp.completionBlock = { CloudQueue().addOperation(pause0) }
        
        let prepped = expectation(description: "records uploaded to database.")
        pause0.completionBlock = { prepped.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [prepped], timeout: 10)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks)
        let pause1 = Pause(seconds: 2)
        testOp?.completionBlock = { CloudQueue().addOperation(pause1) }
        
        cleanUp.addDependency(pause1)
        
        CloudQueue().addOperation(cleanUp)
        
        let expect = expectation(description: "reciever.recordables updated")
        cleanUp.completionBlock = { expect.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        wait(for: [expect], timeout: 10)
        
        // Evaluates results.
        if let results = mockRec?.recordables as? [MockRecordable] {
            let sortedResults = results.sorted() { $0.created > $1.created }
print("mocks : \(mocks)")
print("results: \(results.count)")
            XCTAssert(mocks == sortedResults)
        } else {
            XCTFail()
        }
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mock = MockRecordable()
        mockRec = MockReciever()
        
        testOp = Download(type: mock.recordType, to: mockRec!)
    }
    
    override func tearDown() {
        testOp = nil
        mockRec = nil
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        super.tearDown()
    }
}
