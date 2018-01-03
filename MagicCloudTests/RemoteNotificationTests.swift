//
//  NotificationReaderTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 11/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

// CAUTION: These tests assume MCNotificationReader is implemented in app delegate.
// CAUTION: These tests require database manipulation from an external device to work.
class RemoteNotificationTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockRec: MockReceiver?
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        mockRec = MockReceiver()
        
        // These methods are for detecting phantom subscription issue.
        countSubscriptions()
        countSubscriptions(after: 7.0)
    }
    
    override func tearDown() {
        mockRec = nil
        super.tearDown()
    }
    
    func countSubscriptions(after secs: Double = 0) {
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
            }
        }
    }

    // MARK: - Functions: Tests
    
    func testNotificationReceiverCanConvertRemoteNotificationToLocal() {
        mockRec?.subscribeToChanges(on: .publicDB)
        
        let mockAddedToDatabase = expectation(forNotification: Notification.Name(MockRecordable().recordType), object: nil, handler: nil)
        
        // Test pauses here to give external device time to add a mock to the database.
        // Ensure mock is using the appropriate identifier, or deletion will fail locally.
        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY ADDED TO DATABASE")
        wait(for: [mockAddedToDatabase], timeout: 30)

        // Test pauses here to give app time to react and download recordable to receiver.
        let firstPause = Pause(seconds: 4)
        OperationQueue().addOperation(firstPause)
        firstPause.waitUntilFinished()
        
        let firstResult = mockRec?.recordables.count
print("-- firstResult \(String(describing: firstResult))")
        XCTAssert(firstResult == 1)
        
        let mockRemovedFromDatabase = expectation(forNotification: Notification.Name(MockRecordable().recordType), object: nil, handler: nil)
        
        // Test pauses here to give external device time to remove mock from the database.
        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY REMOVED FROM DATABASE")
        wait(for: [mockRemovedFromDatabase], timeout: 30)
        
        // Test pauses here to give app time to react and delete recordable from receiver.
        let secondPause = Pause(seconds: 2)
        OperationQueue().addOperation(secondPause)
        secondPause.waitUntilFinished()
        
        if let lastResult = firstResult {
print("-- lastResult \(String(describing: lastResult))")
print("-- count \(String(describing: mockRec?.recordables.count))")
            XCTAssert(mockRec?.recordables.count == lastResult - 1)
        } else {
            XCTFail()
        }
        
        mockRec?.unsubscribeToChanges()

        let pause = Pause(seconds: 2)
        OperationQueue().addOperation(pause)
        pause.waitUntilFinished()
    }
}
