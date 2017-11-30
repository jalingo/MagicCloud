//
//  RecievesRecTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit


// !! CAUTION: These tests require a NotificationReader in host app delegate for local / remote notifications to work.

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
        let op = MCUpload(mockRecordables, from: mock!, to: .publicDB)
        let pause = Pause(seconds: 3)
        pause.addDependency(op)
pause.completionBlock = { print("** finished prep pause") }
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    func cleanUpDatabase() -> Int {
        let op = MCDelete(mockRecordables, of: mock!, from: .publicDB)
        let pause = Pause(seconds: 2)
        pause.addDependency(op)
pause.completionBlock = { print("** finished cleanUp pause") }
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    // MARK: - Functions: Unit Tests
    
    func testReceiverHasRecordables() { XCTAssertNotNil(mock?.recordables) }

    func testReceiverHasAssociatedTypeRecordable() { XCTAssert(mock?.recordables is [MCRecordable]) }
    
    func testReceiverHasSubscriber() { XCTAssertNotNil(mock?.subscription) }
    
    func testReceiverCanDownloadAll() {
        let _ = prepareDatabase()
        
        let pause = Pause(seconds: 2)
        mock?.downloadAll(from: .publicDB) { pause.start() }
        pause.waitUntilFinished()
        
        if let recordables = mock?.recordables {
            XCTAssertEqual(recordables, mockRecordables)
        } else {
            XCTFail()
        }
    }
    
    func testReceiverCanListenForLocalNotification() {
        mock?.listenForDatabaseChanges()
        
        let _ = prepareDatabase()
        
        let type = MockRecordable().recordType
        let notice = MCNotification.changeNoticed(forType: type, at: .publicDB)
       
        let name = Notification.Name(notice.toString())
        NotificationCenter.default.post(name: name, object: notice)
        
        let pause = Pause(seconds: 2)
        OperationQueue().addOperation(pause)
        
        pause.waitUntilFinished()
        XCTAssert(mock?.recordables.count != 0)
    }
    
    func testReceiverCanStartSubscriptionAndListen() {
        mock?.subscribeToChanges(on: .publicDB)
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { print("** done waiting for subscription") }
        OperationQueue().addOperation(pause)
        
        pause.waitUntilFinished()
print("** uploading mocks to trigger remote notification")
        let _ = prepareDatabase()
        
        XCTAssert(mock?.recordables.count != 0)
    }
    
    func testReceiverCanStopSubscription() {
        mock?.subscribeToChanges(on: .publicDB)
        mock?.unsubscribeToChanges(from: .publicDB)
        
        let pause = Pause(seconds: 2)
        OperationQueue().addOperation(pause)
        pause.waitUntilFinished()

        let _ = prepareDatabase()   // <-- If still subscribed, then this will trigger download
        
        XCTAssert(mock?.recordables.count == 0)
    }
  
    func testReceiverCanSyncForRecordCreation() { XCTFail() }
    
    func testReceiverCanSyncForRecordUpdate() { XCTFail() }
    
    func testReceiverCanSyncForRecordDeletion() { XCTFail() }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
        mock = MockReceiver()
    }
    
    override func tearDown() {
        let _ = cleanUpDatabase()
        mock = nil

        super.tearDown()
    }
}

// MARK: - Mocks

class MockReceiver: MCReceiver {

    var subscription = MCSubscriber()
    
    typealias type = MockRecordable
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables = [type]() {
        didSet { print("** recordables didSet = \(recordables.count)") }
    }
    
    deinit {
        unsubscribeToChanges(from: .publicDB)
        
        let pause = Pause(seconds: 3)
        OperationQueue().addOperation(pause)
pause.completionBlock = { print("** finished deinit pause") }
        pause.waitUntilFinished()
        
        print("** deinit MockReceiver")
    }
}
