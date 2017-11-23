//
//  NotificationReaderTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 11/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

// !! CAUTION: These tests assume MCNotificationReader is implemented in app delegate.
class NotificationReaderTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockRec: MockReceiver?
    
    var mockRecordables: [MockRecordable] {
        var array = [MockRecordable]()
        
        array.append(MockRecordable(created: Date.distantPast))
        array.append(MockRecordable(created: Date.distantFuture))
        
        return array
    }
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        mockRec = MockReceiver()
    }
    
    override func tearDown() {
        super.tearDown()        
        mockRec = nil
    }

    func prepareDatabase() -> Int {
        let op = Upload(mockRecordables, from: mockRec!, to: .publicDB)
        let pause = Pause(seconds: 3)
        pause.addDependency(op)
        pause.completionBlock = { print("finished prep pause") }
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    func cleanUpDatabase() -> Int {
        let op = Delete(mockRecordables, of: mockRec!, from: .publicDB)
        let pause = Pause(seconds: 2)
        pause.addDependency(op)
        pause.completionBlock = { print("finished cleanUp pause") }
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    // MARK: - Functions: Tests
    
    func testNotificationReceiverCanConvertRemoteNotificationToLocal() {
        mockRec?.subscribeToChanges(on: .publicDB)
        
        let _ = prepareDatabase()
        XCTAssert(mockRec?.recordables.count != 0)
        
        let _ = cleanUpDatabase()
        XCTAssert(mockRec?.recordables.count == 0)
    }
}
