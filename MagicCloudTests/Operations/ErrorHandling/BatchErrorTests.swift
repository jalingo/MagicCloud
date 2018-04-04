//
//  BatchErrorTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class BatchErrorTests: XCTestCase {
    
    // MARK: - Properties
    
    var mocks: [MockRecordable]?
    
    var mockOp: MockOperation?
    
    var mockRec = MCMirror<MockRecordable>(db: .privateDB)
    
    var errorMatch: CKError?
    
    var errorDetected = false
    
    let db: MCDatabase = .privateDB
    
    // MARK: - Functions
    
    func loadMocks() {
        mocks = [MockRecordable]()
        mocks?.append(MockRecordable())
        mocks?.append(MockRecordable(created: Date.distantPast))
        
        mockRec = MCMirror<MockRecordable>(db: db)
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

        let testOp = MockBatchErrorResolver(error: error, with: mocks!, in: mockOp!, from: mockRec)
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

        let testOp = MockBatchErrorResolver(error: error, with: mocks!, in: mockOp!, from: mockRec)
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

        let testOp = MockBatchErrorResolver(error: error, with: mocks!, in: mockOp!, from: mockRec)
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

class MockBatchErrorResolver: Operation, MCDatabaseModifier, MCCloudErrorHandler, BatchErrorResolver {
    
    // MARK: - Properties

    var error: CKError
    
    var failedOp: Operation
    
    // MARK: - Properties: MCDatabaseModifier, MCCloudErrorHandler
    
    var ignoreUnknownItem: Bool = false
    
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    var receiver: MCMirror<MockRecordable>
    
    var recordables: [MockBatchErrorResolver.R.type]
    
    typealias R = MCMirror<MockRecordable>
    
    var database: MCDatabase
    
    // MARK: - Functions
    
    override func main() { self.resolveBatch(error, in: failedOp) }
    
    init(error err: CKError, with recs: [MockRecordable], in op: Operation, from rec: MCMirror<MockRecordable>) {
        error = err
        failedOp = op
        receiver = rec
        database = rec.db
        recordables = recs
    }
}
