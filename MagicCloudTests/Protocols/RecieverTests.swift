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
    
    func testReceiverCanStartAndEndSubscriptions() {
        var originalNumberOfSubscriptions: Int?
        var modifiedNumberOfSubscriptions: Int?
        var finalNumberOfSubscriptions: Int?
        
        let firstFetch = expectation(description: "All Subscriptions Fetched")
        MCDatabase.publicDB.db.fetchAllSubscriptions { possibleSubscriptions, possibleError in
            if let subscriptions = possibleSubscriptions {
                originalNumberOfSubscriptions = subscriptions.count
            } else {
                originalNumberOfSubscriptions = 0
            }
            
            if let error = possibleError as? CKError {
                print("** error @ Subscription Start tests \(error.code.rawValue): \(error.localizedDescription)")
            }
            
            firstFetch.fulfill()
        }
        
        wait(for: [firstFetch], timeout: 5)
        mock?.subscribeToChanges(on: .publicDB)
        
        let firstPause = Pause(seconds: 2)
        firstPause.completionBlock = { print("** done waiting for subscription to start") }
        OperationQueue().addOperation(firstPause)
        
        firstPause.waitUntilFinished()
        let secondFetch = expectation(description: "All Subscriptions Fetched, again")
        MCDatabase.publicDB.db.fetchAllSubscriptions { possibleSubscriptions, possibleError in
            if let subscriptions = possibleSubscriptions {
                modifiedNumberOfSubscriptions = subscriptions.count
            } else {
                modifiedNumberOfSubscriptions = 0
            }
            
            if let error = possibleError as? CKError {
                print("** error @ Subscription End tests \(error.code.rawValue): \(error.localizedDescription)")
            } else {
                self.mock?.unsubscribeToChanges(from: .publicDB)
            }
            
            secondFetch.fulfill()
        }
        
        wait(for: [secondFetch], timeout: 5)
        guard originalNumberOfSubscriptions != nil, modifiedNumberOfSubscriptions != nil else { XCTFail(); return }
        XCTAssertNotEqual(originalNumberOfSubscriptions, modifiedNumberOfSubscriptions)
        
        mock?.unsubscribeToChanges(from: .publicDB)
        
        let secondPause = Pause(seconds: 2)
        secondPause.completionBlock = { print("** done waiting for subscription to end") }
        OperationQueue().addOperation(secondPause)
        
        secondPause.waitUntilFinished()
        let thirdFetch = exception(description: "All Subscriptions Fetched, for a final time")
        MCDatabase.publicDB.db.fetchAllSubscriptions { possibleSubscriptions, possibleError in
            if let subscriptions = possibleSubscriptions {
                finalNumberOfSubscriptions = subscriptions.count
            } else {
                finalNumberOfSubscriptions = 0
            }
            
            if let error = possibleError as? CKError {
                print("** error @ Subscription End tests \(error.code.rawValue): \(error.localizedDescription)")
            } else {
                self.mock?.unsubscribeToChanges(from: .publicDB)
            }
            
            thirdFetch.fulfill()
        }
        
        wait(for: [thirdFetch], timeout: 5)
        guard finalNumberOfSubscriptions != nil else { XCTFail(); return }
        XCTAssertEqual(originalNumberOfSubscriptions, finalNumberOfSubscriptions)
    }
    
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

    var subscription = MCSubscriber(forRecordType: type().recordType)
    
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
