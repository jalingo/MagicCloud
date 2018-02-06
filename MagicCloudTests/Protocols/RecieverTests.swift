//
//  RecievesRecTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
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
    
    func countSubscriptions(after secs: Double = 0) -> Int? {
        let group = DispatchGroup()
        group.enter()
        
        var number: Int?
        DispatchQueue(label: "TEST").asyncAfter(deadline: .now() + secs) {
            MCDatabase.publicDB.db.fetchAllSubscriptions { possibleSubs, possibleError in
                var subs = String(describing: possibleSubs?.count)
                let sub = subs.remove(at: subs.index(after: subs.index(of: "(")!))
                let error = String(describing: possibleError?.localizedDescription)
                
                print("""
                    ## ----------------- ##
                    ## After \(secs) seconds ##
                    ## Sub Count = \(sub)     ##
                    ## Errors = \(error)      ##
                    ## ----------------- ##
                    """)
                
                number = possibleSubs?.count
                group.leave()
            }
        }

        group.wait()
        return number
    }
    
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

    func testReceiverHasAssociatedTypeRecordable() { XCTAssertNotNil(mock?.recordables) }
    
    func testReceiverHasSubscriber() { XCTAssertNotNil(mock?.subscription) }
    
    func testReceiverCanDownloadAll() {
        let _ = prepareDatabase()
        
        let pause = Pause(seconds: 3)
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
                op.completionBlock = { print("@fetchAllSubscriptions \(subscriptions.count)") }
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
                self.mock?.unsubscribeToChanges()
            }
            
            secondFetch.fulfill()
        }
        
        wait(for: [secondFetch], timeout: 5)
        guard originalNumberOfSubscriptions != nil, modifiedNumberOfSubscriptions != nil else { XCTFail(); return }
        XCTAssertNotEqual(originalNumberOfSubscriptions, modifiedNumberOfSubscriptions)
        
        mock?.unsubscribeToChanges()
        
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
                self.mock?.unsubscribeToChanges()
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
        let pause1 = Pause(seconds: 5)
        OperationQueue().addOperation(pause1)
        
        pause1.waitUntilFinished()
        
        let fetchFinished = expectation(description: "READY_TO_TEST")
        var idMatches = false
        MCDatabase.publicDB.db.fetchAllSubscriptions { possibleSubs, possibleError in
            if let subs = possibleSubs as? [CKQuerySubscription] {
                if let sub = self.mock?.subscription.subscription{
                    XCTAssert(subs.count == 1)
                    if let first = subs.first,
                        sub.recordType == first.recordType,
                        sub.querySubscriptionOptions == first.querySubscriptionOptions { idMatches = true }
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
    
    func testReceiverWrapperSelfRegulatesLocally() {
print("ø- instantiating receiver")
        let receiver = MCReceiver<MockRecordable>(db: .publicDB)
        
        let e = expectation(description: "Async activity completed.")
        
        // This delay allows receiver to establish subscription.
        DispatchQueue(label: "test q").asyncAfter(deadline: .now() + 3) {
            let _ = self.prepareDatabase()
            
            // This delay allows receiver to respond to changes.
            DispatchQueue(label: "q test").asyncAfter(deadline: .now() + 5) { e.fulfill() }
        }
        
        wait(for: [e], timeout: 15)
        XCTAssertNotEqual(receiver.recordables.count, 0)
    }
    
    func testReceiverWrappersSelfRegulatesRemotely() {
print("ø- instantiating receiver")
        let receiver = MCReceiver<MockRecordable>(db: .publicDB)

        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY ADDED TO DATABASE")
        let mockAddedToDatabase = expectation(forNotification: Notification.Name(MockRecordable().recordType), object: nil, handler: nil)
        wait(for: [mockAddedToDatabase], timeout: 30)
        
        // Test pauses here to give app time to react and download recordable to receiver.
        let firstPause = Pause(seconds: 4)
        OperationQueue().addOperation(firstPause)
        firstPause.waitUntilFinished()
        
        XCTAssertNotEqual(receiver.recordables.count, 0)
        
        let mockRemovedFromDatabase = expectation(forNotification: Notification.Name(MockRecordable().recordType), object: nil, handler: nil)
        
        // Test pauses here to give external device time to remove mock from the database.
        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY REMOVED FROM DATABASE")
        wait(for: [mockRemovedFromDatabase], timeout: 30)
        
        XCTAssertEqual(receiver.recordables.count, 0)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
print("ø- instantiating MockReceiver")
        mock = MockReceiver()
    }
    
    override func tearDown() {
        let _ = cleanUpDatabase()
        mock = nil

        super.tearDown()
    }
}

// MARK: - Mocks

class MockReceiver: MCReceiverAbstraction {

    let name = "MockReceiver"
    
    typealias type = MockRecordable

    var subscription = MCSubscriber(forRecordType: type().recordType)

    let serialQ = DispatchQueue(label: "MockRec Q")    

    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables = [type]() {
        didSet {
            print("** newRecordable = \(String(describing: recordables.last?.recordID.recordName))")
            print("** recordables didSet = \(recordables.count)")
        }
    }

    deinit {
        unsubscribeToChanges()

        let pause = Pause(seconds: 3)
        OperationQueue().addOperation(pause)
        pause.waitUntilFinished()

        print("** deinit MockReceiver complete")
    }
}

