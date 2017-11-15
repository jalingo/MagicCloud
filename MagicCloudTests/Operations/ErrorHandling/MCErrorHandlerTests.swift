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
    
    let db = CKContainer.default().privateCloudDatabase
    
    let mockRec = MockReceiver()
    
    var testOp: MCErrorHandler<MockReceiver>?
    
    // MARK: - Functions
    
    func loadTestOp(error: CKError) {
        let database = DatabaseType.from(scope: db.databaseScope)
        testOp = MCErrorHandler(error: error, originating: mockOp, target: database, instances: mocks as! [MockReceiver.type], receiver: mockRec)
    }
    
    // MARK: - Functions: Unit Tests
    
    func testErrorHandlerResolvesAuthentication() {
        let error = NSError(domain: CKErrorDomain, code: CKError.notAuthenticated.rawValue, userInfo: nil)
        loadTestOp(error: CKError(_nsError: error))
        
        var authenticationErrorDetected = false
        let block: NotifyBlock = { _ in
            authenticationErrorDetected = true
        }
        
        let observer = NotificationCenter.default.addObserver(forName: MCNotification.notAuthenticated, object: nil, queue: nil, using: block)
        
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
        
        let observer = NotificationCenter.default.addObserver(forName: MCNotification.serverRecordChanged, object: nil, queue: nil, using: block)
        
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
        
        let observer = NotificationCenter.default.addObserver(forName: MCNotification.batchIssue, object: nil, queue: nil, using: block)
        
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
        
        let observer = NotificationCenter.default.addObserver(forName: MCNotification.retriable, object: nil, queue: nil, using: block)
        
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
        
        let observer = NotificationCenter.default.addObserver(forName: MCNotification.fatalError, object: nil, queue: nil, using: block)
        
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
        
        let observer = NotificationCenter.default.addObserver(forName: MCNotification.sharingError, object: nil, queue: nil, using: block)
        
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

/// This mock overrides main with the only change to implementation being that
/// a notification is launched rather than the follow up operation.
//class MockErrorHandler: MCErrorHandler {
//
//    override func main() {
//        if ignoreUnknownItem && error.code == .unknownItem {
//print("** unknownItem detected")
//            if let action = ignoreUnknownItemCustomAction { action() }
//            return
//        }
//
//        if isCancelled { return }
//
//        var name: Notification.Name
//        switch error.code {
//
//        // This error occurs when USER is not logged in to an iCloud account on their device.
//        case .notAuthenticated: name = MCNotification.notAuthenticated
//
//        // This error occurs when record's change tag indicates a version conflict.
//        case .serverRecordChanged: name = MCNotification.serverRecordChanged
//
//        // These errors occur when a batch of requests fails or partially fails.
//        case .limitExceeded, .batchRequestFailed, .partialFailure:
//            name = MCNotification.batchIssue
//
//        // These errors occur as a result of environmental factors, and originating operation should
//        // be retried after a set amount of time.
//        case .networkUnavailable, .networkFailure,
//             .serviceUnavailable, .requestRateLimited,
//             .resultsTruncated,   .zoneBusy:
//            name = MCNotification.retriable
//
//        // These errors are related to the use of CKSharedDatabase, and have to be handled uniquely.
//        case .alreadyShared, .tooManyParticipants: name = MCNotification.sharingError
//
//        // These fatal errors do not require any further handling, except for a USER notification.
//        default:
//            name = MCNotification.fatalError
//        }
//
//        NotificationCenter.default.post(name: name, object: nil, userInfo: nil)
//    }
//}

