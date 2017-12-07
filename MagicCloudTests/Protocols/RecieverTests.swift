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

        let distantPast = MockRecordable(created: Date.distantPast)
        distantPast.recordID = CKRecordID(recordName: "Distant-Past")
        array.append(distantPast)
        array.append(MockRecordable(created: Date.distantFuture))
        
        return array
    }
    
    // MARK: - Functions
    
    func prepareDatabase() -> Int {
        let op = MCUpload(mockRecordables, from: mock!, to: .publicDB)
        let pause = Pause(seconds: 3)
        pause.addDependency(op)
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    func cleanUpDatabase() -> Int {
        let op = MCDelete(mockRecordables, of: mock!, from: .publicDB)
        let pause = Pause(seconds: 2)
        pause.addDependency(op)
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
    
    func testReceiverCanStartAndEndSubscriptions() {
        var originalNumberOfSubscriptions: Int?
        var modifiedNumberOfSubscriptions: Int?
        var finalNumberOfSubscriptions: Int?
        
        let firstFetch = expectation(description: "All Subscriptions Fetched")
        MCDatabase.publicDB.db.fetchAllSubscriptions { possibleSubscriptions, possibleError in
            if let subscriptions = possibleSubscriptions, subscriptions.count != 0 {
                let op = CKModifySubscriptionsOperation(subscriptionsToSave: nil,
                                                        subscriptionIDsToDelete: subscriptions.map({$0.subscriptionID}))
                op.completionBlock = { print("@________ \(subscriptions.count)") }
                MCDatabase.publicDB.db.add(op)
                op.waitUntilFinished()
            }

            originalNumberOfSubscriptions = 0
            
            if let error = possibleError as? CKError {
                print("** error @ Subscription Start tests \(error.code.rawValue): \(error.localizedDescription)")
            }
            
            firstFetch.fulfill()
        }
        
        wait(for: [firstFetch], timeout: 5)
        mock?.subscribeToChanges(on: .publicDB)
        
        let firstPause = Pause(seconds: 2)
        firstPause.completionBlock = { print("== done waiting for subscription to start") }
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
        secondPause.completionBlock = { print("== done waiting for subscription to end") }
        OperationQueue().addOperation(secondPause)
        
        secondPause.waitUntilFinished()
        let thirdFetch = expectation(description: "All Subscriptions Fetched, for a final time")
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
    
    func testSubscriberErrorCanHandleServerRejectedRequest() {
        let staleAltSub = MCSubscriber(forRecordType: MockRecordable().recordType, on: .publicDB)
        staleAltSub.start()

        // gives time for bad id to subscribe
        let pause0 = Pause(seconds: 5)
        OperationQueue().addOperation(pause0)
        
        // attempts to write subscribe with new id
        pause0.waitUntilFinished()
        mock?.subscribeToChanges(on: .publicDB)
        
        // gives time for mock to deal with conflict
        let pause1 = Pause(seconds: 2)
        OperationQueue().addOperation(pause1)
        
        pause1.waitUntilFinished()
        
        let fetchFinished = expectation(description: "READY_TO_TEST")
        var idMatches = false
        MCDatabase.publicDB.db.fetchAllSubscriptions { possibleSubs, possibleError in
            if let subs = possibleSubs as? [CKQuerySubscription] {
                if let sub = self.mock?.subscription.subscription{
                    XCTAssert(subs.count == 1)
                    if subs.map({$0.subscriptionID}).contains(sub.subscriptionID) {
                        idMatches = true
                    } else {
                        XCTFail()
                    }
                } else {
                    let id = staleAltSub.subscription.subscriptionID
                    XCTAssertFalse(subs.map({$0.subscriptionID}).contains(id))
                }
            }
            
            fetchFinished.fulfill()
        }
        
        wait(for: [fetchFinished], timeout: 5)
        XCTAssert(idMatches)
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
        pause.waitUntilFinished()
        
        print("** deinit MockReceiver")
    }
}
