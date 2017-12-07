//
//  BatchErrorTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class BatchErrorTests: XCTestCase {
    
    // MARK: - Properties
    
    var mocks: [MCRecordable]?
    
    var mockOp: MockOperation?
    
    var mockRec = MockReceiver()
    
    var errorMatch: CKError?
    
    var errorDetected = false
    
    let db: MCDatabase = .privateDB
    
    // MARK: - Functions
    
    func loadMocks() {
        mocks = [MCRecordable]()
        mocks?.append(MockRecordable())
        mocks?.append(MockRecordable(created: Date.distantPast))
        
        mockRec = MockReceiver()
    }
    
    func genError(code: Int) -> CKError {
        let error = NSError(domain: CKErrorDomain, code: code, userInfo: nil)
        return CKError(_nsError: error)
    }
    
    func detectionBlock() -> NotifyBlock {
        return { notification in
            if let error = notification.object as? CKError { self.errorDetected = (error == self.errorMatch) }
        }
    }
    
    // MARK: - Functions: Unit Tests
    
    func testBatchErrorHandlesPartialError() {
        let error = genError(code: CKError.partialFailure.rawValue)
        errorMatch = error

        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())

        let testOp = BatchError(error: error, occuredIn: mockOp!, target: db, receiver: mockRec, instances: mocks as! [MockRecordable])
        OperationQueue().addOperation(testOp)

        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)

        NotificationCenter.default.removeObserver(observer)
    }
    
    func testBatchErrorHandlesLimitExceeded() {
        let error = genError(code: CKError.limitExceeded.rawValue)
        errorMatch = error

        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())

        let testOp = BatchError(error: error, occuredIn: mockOp!, target: db, receiver: mockRec, instances: mocks as! [MockRecordable])
        OperationQueue().addOperation(testOp)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testBatchErrorHandlesBatchRequestFail() {
        let error = genError(code: CKError.batchRequestFailed.rawValue)
        errorMatch = error

        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())

        let testOp = BatchError(error: error, occuredIn: mockOp!, target: db, receiver: mockRec, instances: mocks as! [MockRecordable])
        OperationQueue().addOperation(testOp)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
//    func testPerformance() {
//        self.measure {
//            let error = self.genError(code: CKError.batchRequestFailed.rawValue)
//            let op = MockBatchError(error: error, occuredIn: self.mockOp, instances: self.mocks!, target: self.db)
//            
//            ErrorQueue().addOperation(op)
//            op.waitUntilFinished()
//            print("Performance Test Completed")
//        }
//    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mockOp = MockOperation()
        errorDetected = false
        loadMocks()
    }
    
    override func tearDown() {
        mockOp = nil
        mocks = nil
        errorMatch = nil
        
        super.tearDown()
    }    
}

// MARK: - Mocks

class MockOperation: Operation { }

