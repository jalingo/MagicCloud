//
//  CKErrHandleTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/17/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class MCErrorHandlerTests: XCTestCase {
    
    // MARK: - Properties
    
    let mockOp = Operation()
    
    let mocks = [Recordable]()
        
    let mockRec = MockReceiver()
    
    var testOp: MCErrorHandler<MockReceiver>?
    
    // MARK: - Functions
    
    func loadTestOp(error: CKError) {
        testOp = MCErrorHandler(error: error, originating: mockOp, target: .privateDB, instances: mocks as! [MockReceiver.type], receiver: mockRec)
    }
    
    // MARK: - Functions: Unit Tests
    
    func testErrorHandlerResolvesAuthentication() {
        let error = NSError(domain: CKErrorDomain, code: CKError.notAuthenticated.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        var authenticationErrorDetected = false
        let block: NotifyBlock = { _ in
            authenticationErrorDetected = true
        }
        
        let name = Notification.Name(MCNotification.error(CKError(_nsError: error)).toString())
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: block)
        
        ErrorQueue().addOperation(testOp!)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(authenticationErrorDetected)

        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesVersionConflict() {
        let error = NSError(domain: CKErrorDomain, code: CKError.serverRecordChanged.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        var versionConflictDetected = false
        let block: NotifyBlock = { _ in
            versionConflictDetected = true
        }
        
        let name = Notification.Name(MCNotification.error(CKError(_nsError: error)).toString())
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: block)
        
        ErrorQueue().addOperation(testOp!)

        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(versionConflictDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesBatchErrors() {
        let error = NSError(domain: CKErrorDomain, code: CKError.batchRequestFailed.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        var batchFailureDetected = false
        let block: NotifyBlock = { _ in
            batchFailureDetected = true
        }
        
        let name = Notification.Name(MCNotification.error(CKError(_nsError: error)).toString())
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: block)
        
        ErrorQueue().addOperation(testOp!)

        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(batchFailureDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesRetriableErrors() {
        let error = NSError(domain: CKErrorDomain, code: CKError.networkUnavailable.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        var retriableErrorDetected = false
        let block: NotifyBlock = { _ in
            retriableErrorDetected = true
        }
        
        let name = Notification.Name(MCNotification.error(CKError(_nsError: error)).toString())
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: block)
        
        ErrorQueue().addOperation(testOp!)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(retriableErrorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerResolvesFatalErrors() {
        let error = NSError(domain: CKErrorDomain, code: CKError.badContainer.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        var fatalErrorDetected = false
        let block: NotifyBlock = { _ in
            fatalErrorDetected = true
        }
        
        let name = Notification.Name(MCNotification.error(CKError(_nsError: error)).toString())
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: block)
        
        ErrorQueue().addOperation(testOp!)

        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(fatalErrorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
   
    func testErrorHandlerResolvesSharingErrors() {
        let error = NSError(domain: CKErrorDomain, code: CKError.alreadyShared.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        var sharingErrorDetected = false
        let block: NotifyBlock = { _ in
            sharingErrorDetected = true
        }
        
        let name = Notification.Name(MCNotification.error(CKError(_nsError: error)).toString())
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: block)
        
        ErrorQueue().addOperation(testOp!)
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        XCTAssert(sharingErrorDetected)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testErrorHandlerCanIgnoreUnknowns() {
        XCTAssertNotNil(testOp?.ignoreUnknownItem)
        
        let error = NSError(domain: CKErrorDomain, code: CKError.unknownItem.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        testOp?.ignoreUnknownItem = true
        var unknownIgnored = false
        testOp?.ignoreUnknownItemCustomAction = { unknownIgnored = true }
        
        ErrorQueue().addOperation(testOp!)
        
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
        
        super.tearDown()
    }
}

