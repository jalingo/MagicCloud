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

    var mock: RecievesRecordable?
    
    // MARK: - Functions
    
    // MARK: - Functions: Unit Tests
    
    func testRecieverHasRecordables() { XCTAssertNotNil(mock?.recordables) }
    
    func testRecieverHasAllowDidSet() { XCTAssertNotNil(mock?.allowComponentsDidSetToUploadDataModel) }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mock = MockReciever()
    }
    
    override func tearDown() {
        mock = nil
        
        super.tearDown()
    }
}

// MARK: - Mocks

class MockReciever: RecievesRecordable {
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables = [Recordable]() {
        didSet { print("MockReciever.recordables didSet: \(recordables.count)") }
    }

    /**
     * This boolean property allows / prevents changes to `recordables` being reflected in
     * the cloud.
     */
    var allowComponentsDidSetToUploadDataModel: Bool = false
    
    /**
     * This property registers whether cloud features should be enabled / disabled. Use its
     * didSet method to implement changes to interface.
     */
    var cloudFeaturesEnabled: Bool = true
}
