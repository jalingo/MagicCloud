//
//  MCMirrorTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 2/10/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class MCMirrorTests: XCTestCase {
    
    // MARK: - Properties
    
    var mock: MCMirror<MockRecordable>?
    
    var needToCleanDatabase = false
    
    let q = OperationQueue()

    let mockRecordable = MockRecordable(created: Date())

    // MARK: - Functions
    
    func prepDatabase() -> Int {
        
        if let rec = mock {
            let op = MCUpload([mockRecordable], from: rec, to: .publicDB)
            q.addOperation(op)
            
            op.waitUntilFinished()
            needToCleanDatabase = true
        }
        
        let pause = Pause(seconds: 3)
        q.addOperation(pause)

        pause.waitUntilFinished()
        return 1
    }
    
    func cleanDatabase() -> Int {
        
        if let rec = mock {
            let op = MCDelete([mockRecordable], of: rec, from: .publicDB)
            q.addOperation(op)
        }
        
        let pause = Pause(seconds: 2)
        q.addOperation(pause)
        
        pause.waitUntilFinished()
        return 1
    }

    // MARK: - Functions: XCTest
    
    override func setUp() {
        super.setUp()
        mock = MCMirror<MockRecordable>(db: .publicDB)
    }
    
    override func tearDown() {
        if needToCleanDatabase { let _ = cleanDatabase() }
        
        mock = nil
        super.tearDown()
    }
    
    // MARK: - Functions: Tests
    
    func testMirrorHasDataModel() { XCTAssertNotNil(mock?.silentRecordables) }
    
    func testMirrorHasChangeNotification() { XCTAssertNotNil(mock?.changeNotification) }

    func testDataModelDetectsChanges() {
        let differentMocks = [MockRecordable()]
        mock?.silentRecordables += differentMocks
        
        if let passed = mock?.silentRecordables.contains(differentMocks[0]) {
            XCTAssert(passed)
        } else {
            XCTFail()
        }
    }
    
    func testMirrorMakesAdditions() {
        let mirror = MCMirror<MockRecordable>(db: .publicDB)

        let _ = prepDatabase()
        
        mirror.cloudRecordables.append(MockRecordable(created: Date.distantPast))

        let pause = Pause(seconds: 2)
        q.addOperation(pause)
        
        pause.waitUntilFinished()
        XCTAssert(mirror.silentRecordables.count == 2, "mirror: \(mirror.silentRecordables.count) / 2")
        XCTAssert(mock?.silentRecordables.count == 2, "mock: \(String(describing: mock?.silentRecordables.count)) / 2")
    }
    
    func testMirrorMakesDeletions() {
        let mirror = MCMirror<MockRecordable>(db: .publicDB)

        let _ = prepDatabase()

        mirror.cloudRecordables.removeAll()

        let pause = Pause(seconds: 3)
        q.addOperation(pause)
        
        pause.waitUntilFinished()
        
        XCTAssert(mirror.silentRecordables.count == 0, "mirror: \(mirror.silentRecordables.count) / 0")
        XCTAssert(mock?.silentRecordables.count == 0, "mock: \(String(describing: mock?.silentRecordables.count)) / 0")
    }
    
    func testMirrorMakesAdjustments() {
        let mirror = MCMirror<MockRecordable>(db: .publicDB)

        let _ = prepDatabase()
        
        let pause = Pause(seconds: 5)
        q.addOperation(pause)
        
        pause.waitUntilFinished()
        if mirror.silentRecordables.count != 0 {
            mirror.cloudRecordables[0].recordFields[MockRecordable.key] = Date.distantPast as CKRecordValue }
        let reactionTime = Pause(seconds: 2)
        q.addOperation(reactionTime)

        reactionTime.waitUntilFinished()
        if let date = mock?.silentRecordables[0].recordFields[MockRecordable.key] as? Date {
            XCTAssert(date == Date.distantPast) }
    }
}


