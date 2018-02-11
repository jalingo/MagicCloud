//
//  MCMirrorTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 2/10/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import XCTest

class MCMirrorTests: XCTestCase {
    
    // MARK: - Properties
    
    var mock: MCMirrorAbstraction?
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        mock = MockMirror(receiver: MCReceiver<MockRecordable>(db: .publicDB), results: nil)
    }
    
    override func tearDown() {
        mock = nil
        super.tearDown()
    }
    
    // MARK: - Functions: Tests
    
    func testMirrorHasDataModel() { XCTAssertNotNil(mock?.dataModel) }
    
    func testDataModelDetectsChanges() {
        let differentMocks = [MockRecordable()]
        mock?.dataModel += differentMocks as [MCRecordable]
        
        if let change = (mock as? MockMirror)?.results?.add {
            XCTAssert(change == differentMocks)
        } else {
            XCTFail()
        }
    }
}

struct MockMirror: MCMirrorAbstraction {
    let receiver: MCReceiver<MockRecordable>
    
    var results: (add: [MCRecordable], remove: [MCRecordable])?

    var dataModel: [MCRecordable] {
        get { return receiver.recordables }
        set { results = check(receiver.recordables, against: newValue) }
    }
}


