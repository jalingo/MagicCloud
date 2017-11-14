//
//  PauseTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest

class PauseTests: XCTestCase {
 
    // MARK: - Properties

    var mockOp: Pause?

    let duration = 2
    
    var inProgress = true
    
    // MARK: - Functions
    
    // MARK: - Functions: Unit Tests
    
    func testPauseDuration() {
        
        let expect = expectation(description: "wait for pause")
        
        mockOp?.completionBlock = { expect.fulfill() }
        OperationQueue().addOperation(mockOp!)
        
        wait(for: [expect], timeout: 3)
    }

    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mockOp = Pause(seconds: TimeInterval(duration))
    }
    
    override func tearDown() {
        mockOp = nil
        
        super.tearDown()
    }
}
