//
//  CKErrHandleTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/17/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class MCErrorHandlerTests: XCTestCase {
    
    // MARK: - Properties
    
    let mockOp = Operation()
    
    let mocks = [MCRecordable]()
        
    var mockRec = MockReceiver()
    
    var testOp: MCErrorHandler<MockReceiver>?
    
    var errorDetected = false
    
    var errorMatch: CKError?
    
    // MARK: - Functions
    
    func loadTestOp(error: CKError) {
        testOp = MCErrorHandler(error: error, originating: mockOp, target: .privateDB, instances: mocks as! [MockReceiver.type], receiver: mockRec)
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
    
    func testErrorHandlerResolvesAuthentication() {
        let error = genError(code: CKError.notAuthenticated.rawValue)
        errorMatch = error
        
        loadTestOp(error: error)
        
        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())
        
        OperationQueue().addOperation(testOp!)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)

        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesVersionConflict() {
        let error = genError(code: CKError.serverRecordChanged.rawValue)
        errorMatch = error
        
        loadTestOp(error: error)
        
        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())

        OperationQueue().addOperation(testOp!)

        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesBatchErrors() {
        let error = genError(code: CKError.batchRequestFailed.rawValue)
        errorMatch = error
        
        loadTestOp(error: error)
        
        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())
        
        OperationQueue().addOperation(testOp!)

        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesRetriableErrors() {
        let error = genError(code: CKError.serverRecordChanged.rawValue)
        errorMatch = error
        
        loadTestOp(error: error)
        
        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())
        
        OperationQueue().addOperation(testOp!)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesFatalErrors() {
        let error = genError(code: CKError.serverRecordChanged.rawValue)
        errorMatch = error
        
        loadTestOp(error: error)
        
        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())
        
        OperationQueue().addOperation(testOp!)

        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
   
    func testErrorHandlerResolvesSharingErrors() {
        let error = genError(code: CKError.serverRecordChanged.rawValue)
        errorMatch = error
        
        loadTestOp(error: error)
        
        let name = Notification.Name(MCErrorNotification)
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: detectionBlock())
        
        OperationQueue().addOperation(testOp!)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(errorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerCanIgnoreUnknowns() {
        XCTAssertNotNil(testOp?.ignoreUnknownItem)

        let error = genError(code: CKError.unknownItem.rawValue)
        loadTestOp(error: error)
        
        testOp?.ignoreUnknownItem = true
        var unknownIgnored = false
        testOp?.ignoreUnknownItemCustomAction = { unknownIgnored = true }
        
        OperationQueue().addOperation(testOp!)
        
        testOp?.waitUntilFinished()
        XCTAssert(unknownIgnored)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
        
        let error = NSError(domain: CKErrorDomain, code: CKError.alreadyShared.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
    }
    
    override func tearDown() {
        testOp = nil
        errorDetected = false
        errorMatch = nil
        
        super.tearDown()
    }
}

