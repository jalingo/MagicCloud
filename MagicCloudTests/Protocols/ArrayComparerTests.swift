//
//  ArrayComparerTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 2/10/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class ArrayComparerTests: XCTestCase {
    
    // MARK: - Properties
    
    var mock: MockComparer?
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        mock = MockComparer()
    }
    
    override func tearDown() {
        mock = nil
        super.tearDown()
    }
    
    // MARK: - Functions: Tests
    
    func testComparerCanCheck() {
        let mock_0 = MockRecordable(created: Date.distantPast)
        let mock_1 = MockRecordable(created: Date())
        let mock_2 = MockRecordable(created: Date.distantFuture)

        let mock_0e = MockRecordable(created: Date.distantPast)
        mock_0e.recordFields[MockRecordable.key] = Date() as CKRecordValue
        
        let originalMocks = [mock_0, mock_1]
        let changedMocks  = [mock_1, mock_2]
        let editedMocks   = [mock_0e, mock_1]

        if let result = mock?.check(originalMocks, against: changedMocks) {
            XCTAssert(result.add == [mock_2])
            XCTAssert(result.remove == [mock_0])
        } else {
            XCTFail()
        }

        if let result = mock?.check(originalMocks, against: editedMocks) {
            XCTAssert(result.edited == [mock_0e])
            XCTAssert(result.remove == [])
        } else {
            XCTFail()
        }
    }
}

struct MockComparer: MCArrayComparer { }


