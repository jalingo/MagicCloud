//
//  RetriableErrorTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/22/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class RetriableErrorTests: XCTestCase {
    
    // MARK: - Properties

    let notifier = Notification(name: Notification.Name(rawValue: "RetriableTestNotification"))

    var testOp: RetriableError<MockReceiver>?
    
    var mockRec = MockReceiver()
    
    var error: CKError? {
        if let interval = TimeInterval(exactly: 0.2) {
            let info: [AnyHashable: Any] = [CKErrorRetryAfterKey: interval]
            let error = NSError(domain: CKErrorDomain, code: CKError.zoneBusy.rawValue, userInfo: info as? [String : Any])
            return CKError(_nsError: error)
        } else {
            return nil
        }
    }    
    
    // MARK: - Functions
    
    func loadTestOp() {
        let mockOp = FailedOp(notify: notifier)
        if let error = error {
            testOp = RetriableError(error: error, originating: mockOp, target: .privateDB, receiver: mockRec)
        } else {
            print("** RetriableErrorTests.loadTestOp FAILED")
        }
    }
    
    // MARK: - Functions: Unit Tests
    
    func testRetriableErrorResolves() {
        var opWasRetried = false
        
        NotificationCenter.default.addObserver(forName: notifier.name, object: nil, queue: nil) { _ in
            opWasRetried = true
        }
        
        OperationQueue().addOperation(testOp!)
        
        let expect = expectation(forNotification: NSNotification.Name(rawValue: notifier.name.rawValue), object: nil, handler: nil)
        wait(for: [expect], timeout: 3)
        XCTAssert(opWasRetried)
    }
    
//    func testPerformance() {
//        self.measure {
//            self.loadTestOp()
//            ErrorQueue().addOperation(self.testOp!)
//            
//            self.testOp?.waitUntilFinished()
//            print("Performance Test Completed")
//        }
//    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mockRec = MockReceiver()
        loadTestOp()
    }
    
    override func tearDown() {
        testOp = nil
        
        super.tearDown()
    }
}
