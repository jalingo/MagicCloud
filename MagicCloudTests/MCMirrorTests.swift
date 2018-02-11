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

protocol MCMirrorAbstraction: ArrayComparer {
    var dataModel: [MCRecordable] { get set }
}

struct MockMirror: MCMirrorAbstraction {
    let receiver: MCReceiver<MockRecordable>
    
    var results: (add: [MCRecordable], remove: [MCRecordable])?

    var dataModel: [MCRecordable] {
        get { return receiver.recordables }
        set { results = check(receiver.recordables, against: newValue) }
    }
}

class MCMirror<T: MCRecordable>: MCMirrorAbstraction {

    let receiver: MCReceiver<T>
    
    var dataModel: [MCRecordable] {
        get { return receiver.recordables }
        
        set {
            let results = check(receiver.recordables, against: newValue)
            let q = OperationQueue()
            
            if let changes = results.add as? [T] {
                let op = MCUpload(changes, from: receiver, to: receiver.db)
                q.addOperation(op)
            }
            
            if let changes = results.remove as? [T] {
                let op = MCDelete(changes, of: receiver, from: receiver.db)
                q.addOperation(op)
            }
        }
    }
    
    init(db: MCDatabase) {
        receiver = MCReceiver<T>(db: db)
    }
}
