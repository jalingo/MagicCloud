//
//  RecievesRecTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class RecievesRecTests: XCTestCase {
    
    // MARK: - Properties

    var mock: MockReceiver?
    
    // MARK: - Functions
    
    // MARK: - Functions: Unit Tests
    
    func testRecieverHasRecordables() { XCTAssertNotNil(mock?.recordables) }
    
    func testRecieverHasAllowDidSet() { XCTAssertNotNil(mock?.allowRecordablesDidSetToUploadDataModel) }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mock = MockReceiver()
    }
    
    override func tearDown() {
        mock = nil
        
        super.tearDown()
    }
}

// MARK: - Mocks

class MockReceiver: ReceivesRecordable {
    
    typealias type = MockRecordable
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables = [type]() {
        didSet { print("MockReciever.recordables didSet: \(recordables.count)") }
    }

    /**
     * This boolean property allows / prevents changes to `recordables` being reflected in
     * the cloud.
     */
    var allowRecordablesDidSetToUploadDataModel: Bool = false
}
