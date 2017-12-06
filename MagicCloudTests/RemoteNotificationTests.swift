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
    }
    
    override func tearDown() {
        mockRec = nil
        super.tearDown()
    }

    // MARK: - Functions: Tests
    
    func testNotificationReceiverCanConvertRemoteNotificationToLocal() {
        mockRec?.subscribeToChanges(on: .publicDB)
        
        let name = MCNotification.changeNoticed(forType: MockRecordable().recordType, at: .publicDB).toString()
        let mockAddedToDatabase = expectation(forNotification: Notification.Name(name), object: nil, handler: nil)
        
        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY ADDED TO DATABASE")
        wait(for: [mockAddedToDatabase], timeout: 30)
        XCTAssert(mockRec?.recordables.count != 0)
        
        let mockRemovedFromDatabase = expectation(forNotification: Notification.Name(name), object: nil, handler: nil)
        
        print("** WAITING 30 SECONDS FOR MOCK_RECORDABLE TO BE MANUALLY REMOVED FROM DATABASE")
        wait(for: [mockRemovedFromDatabase], timeout: 30)
        XCTAssert(mockRec?.recordables.count == 0)
        
        mockRec?.unsubscribeToChanges(from: .publicDB)

        let pause = Pause(seconds: 2)
        pause.start()
        pause.waitUntilFinished()
    }
}
