//
//  TestOperationAlert.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/16/16.
//
//

import XCTest

class TestOperationAlert: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Functions (tests)
    
    func testAlertOperationPresentsMessage() {
        var testSuccess = false
        let action: AlertClosure = { action in
            testSuccess = true
        }

        let alert = AlertOperation(title: "Test", message: "Message", context: nil, action: action)

        alert.completionBlock = { XCTAssert(testSuccess) }
  
        let queue = OperationQueue()
        queue.addOperation(alert)
        queue.waitUntilAllOperationsAreFinished()
//        OperationQueue.main.addOperation(alert)
    
    }
    
    func testAlertOperationOnlyPresentsOnMain() {
        XCTFail()
    }
}
