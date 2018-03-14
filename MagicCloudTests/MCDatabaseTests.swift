//
//  MCDatabaseTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 3/10/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//
import XCTest
import CloudKit

class MCDatabaseTests: XCTestCase {
    
    // MARK: - Properties
    
    // MARK: - Functions
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Functions: Unit Tests
    
    func testMCDatabaseHasPublicCase() {
        let test = MCDatabase.publicDB
        XCTAssert(MCDatabase.publicDB.description == test.description)
    }
    
    func testMCDatabaseHasPrivateCase() {
        let test = MCDatabase.privateDB
        XCTAssert(MCDatabase.privateDB.description == test.description)
    }
    
    func testMCDatabaseHasSharedCase() {
        let test = MCDatabase.sharedDB
        XCTAssert(MCDatabase.sharedDB.description == test.description)
    }
    
    func testMCDatabaseConstructsFromScope() {
        let scope = CKDatabaseScope.public
        let test = MCDatabase.from(scope: scope)
        
        XCTAssert(test.scope == scope)
    }
    
    func testMCDatabaseSupportsCustomContainers() {
        let container = CKContainer(identifier: "test")
        let custom = MCDatabase.custom(.privateDB, container)
        
        XCTAssert(custom.db == container.privateCloudDatabase)
    }
    
    func testMCDatabaseHasDatabaseAccessor() {
        let test = MCDatabase.publicDB
        XCTAssert(test.db == CKContainer.default().publicCloudDatabase)
    }
    
    func testMCDatabaseHasScope() {
        let test: MCDatabase? = .privateDB
        XCTAssertNotNil(test?.scope)
    }
    
    func testMCDatabaseIsCustomStringConvertible() { XCTAssert(MCDatabase.privateDB is CustomStringConvertible) }
}

