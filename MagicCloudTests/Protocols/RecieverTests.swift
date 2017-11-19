//
//  RecievesRecTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class RecievesRecTests: XCTestCase {
    
    // MARK: - Properties

    var mock: MockReceiver?
    
    var mockRecordables: [MockRecordable] {
        var array = [MockRecordable]()

        array.append(MockRecordable(created: Date.distantPast))
        array.append(MockRecordable(created: Date.distantFuture))
        
        return array
    }
    
    // MARK: - Functions
    
    func prepareDatabase() -> Int {
        let op = Upload(mockRecordables, from: mock!, to: .publicDB)
        let pause = Pause(seconds: 2)
        pause.addDependency(op)

        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    func cleanUpDatabase() -> Int {
        let op = Delete(mockRecordables, of: mock!, from: .publicDB)
        let pause = Pause(seconds: 2)
        pause.addDependency(op)
        
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    // MARK: - Functions: Unit Tests
    
    func testReceiverHasRecordables() { XCTAssertNotNil(mock?.recordables) }
    
    func testReceiverHasAssociatedTypeRecordable() { XCTAssert(mock?.recordables is [Recordable]) }
    
    func testVoteReceiverCanStartListening() {
        let expect = expectation(description: "Receiver Heard Notification")
        var passed = false
        
        mock?.startListening(on: .publicDB) {
            passed = true
            expect.fulfill()
        }
        
        NotificationCenter.default.post(name: Notification.Name(mock!.notifyCreated), object: nil)
        
        wait(for: [expect], timeout: 2)
        XCTAssert(passed)
    }
    
    func testVoteReceiverCanStopListening() {
        var passed = true
        
        mock?.startListening(on: .publicDB) { passed = false }
        mock?.stopListening(on: .publicDB)
        
        NotificationCenter.default.post(name: Notification.Name(mock!.notifyUpdated), object: nil)
        XCTAssert(passed)
    }
    
    func testVoteReceiverCanDownloadAll() {
        let _ = prepareDatabase()
        
        let expect = expectation(description: "All Recordables Downloaded")
        mock?.download(from: .publicDB) { expect.fulfill() }
        wait(for: [expect], timeout: 3)
        
        if let recordables = mock?.recordables {
            XCTAssertEqual(recordables, mockRecordables)
        } else {
            XCTFail()
        }
        
        let _ = cleanUpDatabase()
    }
    
    func testVoteReceiverDownloadsFromListening() {
        let _ = prepareDatabase()
        
        mock?.startListening(on: .publicDB)  // <-- At this point empty
        NotificationCenter.default.post(name: Notification.Name(mock!.notifyUpdated), object: nil)
        
        XCTAssert(mock?.recordables.count != 0)
        
        let _ = cleanUpDatabase()
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
        mock = MockReceiver()
    }
    
    override func tearDown() {
        mock = nil
        super.tearDown()
    }
}

// MARK: - Mocks

class MockReceiver: ReceivesRecordable {

    typealias type = MockRecordable

    var notifyCreated: String { return "Mock Added To Database" }
    
    var notifyUpdated: String { return "Mock Updated in Database" }
    
    var notifyDeleted: String { return "Mock Removed from Database" }
    
    var createdID: String?
    
    var updatedID: String?
    
    var deletedID: String?
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables = [type]()
}
