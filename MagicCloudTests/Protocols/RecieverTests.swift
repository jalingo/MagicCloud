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

    var mock: MCMirror<MockRecordable>?
    
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
    
    func testReceiverHasRecordables() { XCTAssertNotNil(mock?.silentRecordables) }
    
    func testReceiverHasSubscriber() { XCTAssertNotNil(mock?.subscription) }
    
    func testReceiverCanDownloadAll() {
        let _ = prepareDatabase()
        
        let pause = Pause(seconds: 3)
        mock?.downloadAll(from: .publicDB) { pause.start() }
        pause.waitUntilFinished()
        
        if let recordables = mock?.silentRecordables {
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
        let receiver = MCMirror<MockRecordable>(db: .publicDB)
        
        let e = expectation(description: "Async activity completed.")
        
        // This delay allows receiver to establish subscription.
        DispatchQueue(label: "test q").asyncAfter(deadline: .now() + 3) {
            let _ = self.prepareDatabase()
            
            // This delay allows receiver to respond to changes.
            DispatchQueue(label: "q test").asyncAfter(deadline: .now() + 5) { e.fulfill() }
        }
        
        wait(for: [e], timeout: 15)
        XCTAssertNotEqual(receiver.silentRecordables.count, 0)
    }

    // This test requires manual interactions with a USER.
//    func testReceiverWrappersSelfRegulatesRemotely() {
//        let receiver = MCMirror<MockRecordable>(db: .publicDB)
//
//        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY ADDED TO DATABASE")
//        let mockAddedToDatabase = expectation(forNotification: Notification.Name(MockRecordable().recordType), object: nil, handler: nil)
//        wait(for: [mockAddedToDatabase], timeout: 30)
//
//        // Test pauses here to give app time to react and download recordable to receiver.
//        let firstPause = Pause(seconds: 4)
//        OperationQueue().addOperation(firstPause)
//        firstPause.waitUntilFinished()
//
//        XCTAssertNotEqual(receiver.silentRecordables.count, 0)
//
//        let mockRemovedFromDatabase = expectation(forNotification: Notification.Name(MockRecordable().recordType), object: nil, handler: nil)
//
//        // Test pauses here to give external device time to remove mock from the database.
//        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY REMOVED FROM DATABASE")
//        wait(for: [mockRemovedFromDatabase], timeout: 30)
//
//        XCTAssertEqual(receiver.silentRecordables.count, 0)
//    }
    
    func testReceiverReactsCloudAccountChanges() {
        
        // loads mocks into the database
        let _ = prepareDatabase()
        
        // pauses long enough for receiver to download records the first time (to prevent timing issues)
        while mock?.silentRecordables.count == 0 { /* waiting for download to complete */ }
        
        // empties receiver, so that triggered download can be detected
        mock?.silentRecordables = []
        
        // posts the same notification, which should trigger download all
        NotificationCenter.default.post(name: NSNotification.Name.CKAccountChanged, object: nil)
        
        // waits for notification to be reported, and receiver needs time to download records
        while mock?.silentRecordables.count == 0 { /* waiting for download to complete */ }
        
        // now that receiver has had time to download, verify success
        XCTAssert(mock?.silentRecordables.count != 0)
    }
    
    // This test requires manual interactions with a USER.
//    func testReceiverReactsNetworkChanges() {
//        
//        // loads mocks into the database, with enough delay (currently) to accomodate mock?.downloadAll:db:
//        let _ = prepareDatabase()
//
//        // There's an unaccounted for notification (maybe wifi has to wind up in test mode...), but it needs to be waited on to prevent wifiDisabled from triggering before TESTER can make change.
//        let weirdTrigger = expectation(forNotification: .reachabilityChanged, object: nil, handler: nil)
//        wait(for: [weirdTrigger], timeout: 5)
//
//        // empties receiver, so that triggered download can be detected
//        mock?.silentRecordables = []
//
//        // pauses long enough for tester to disable wifi and download to take effect, then tests download occured
//        let wifiDisabled = expectation(forNotification: .reachabilityChanged, object: nil, handler: nil)
//        print("         ** DISABLE WIFI OFF ON TEST DEVICE **")
//        
//        wait(for: [wifiDisabled], timeout: 30)
//        XCTAssert(mock?.silentRecordables.count != 0)
//        
//        let airportMode = expectation(forNotification: .reachabilityChanged, object: nil, handler: nil)
//        print("         ** PLACE TEST DEVICE IN AIRPORT MODE **")
//
//        wait(for: [airportMode], timeout: 30)
//        XCTAssert(mock?.silentRecordables.count != 0)
//        
//        // empties receiver, so that triggered download can be detected
//        mock?.silentRecordables = []
//
//        let signalReturned = expectation(forNotification: .reachabilityChanged, object: nil, handler: nil)
//        print("         ** REMOVE TEST DEVICE FROM AIRPORT MODE **")
//
//        wait(for: [signalReturned], timeout: 30)
//        XCTAssert(mock?.silentRecordables.count != 0)
//    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mock = MCMirror<MockRecordable>(db: .publicDB)
        //MockReceiver()
    }
    
    override func tearDown() {
        let _ = cleanUpDatabase()
        mock = nil

        super.tearDown()
    }
}

// MARK: - Mocks

