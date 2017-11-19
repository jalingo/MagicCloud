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
    
    // MARK: - Functions
    
    // MARK: - Functions: Unit Tests
    
    func testReceiverHasRecordables() { XCTAssertNotNil(mock?.recordables) }
    
    func testReceiverHasAssociatedTypeRecordable() { XCTAssert(mock?.recordables is [Recordable]) }
    
    func testVoteReceiverCanStartListening() {
        let expect = expectation(description: "Receiver Heard Notification")
        var passed = false
        
        mock?.startListening() {
            passed = true
            expect.fulfill()
        }
        
        NotificationCenter.default.post(name: Notification.Name(mock!.notifyCreated), object: nil)
        
        wait(for: [expect], timeout: 2)
        XCTAssert(passed)
    }
    
    func testVoteReceiverCanStopListening() {
        var passed = true
        
        mock?.startListening() { passed = false }
        mock?.stopListening()
        
        NotificationCenter.default.post(name: Notification.Name(mock!.notifyUpdated), object: nil)
        XCTAssert(passed)
    }
    
    func testVoteReceiverCanDownloadAll() {
        let _ = prepareDatabase()
        
        let expect = expectation(description: "All Votes Downloaded")
        mock?.download() { expect.fulfill() }
        wait(for: [expect], timeout: 3)
        
        let allVotes = testVotes()
        if let votes = mock?.recordables {
            XCTAssertEqual(allVotes, votes)
        } else {
            XCTFail()
        }
        
        let _ = cleanUpDatabase()
    }
    
    func testVoteReceiverDownloadsFromListening() {
        let _ = prepareDatabase()
        
        mock?.startListening()  // <-- At this point empty
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
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables = [type]() {
        didSet { print("MockReciever.recordables didSet: \(recordables.count)") }
    }
}
