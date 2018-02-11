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
print("-- first ---")
        if let result = mock?.check(originalMocks, against: changedMocks) {
print("                 added = \(result.add.count)")
            XCTAssert(result.add == [mock_2])
            XCTAssert(result.remove == [mock_0])
        } else {
            XCTFail()
        }
print("-- second --")
        if let result = mock?.check(originalMocks, against: editedMocks) {
print("                 added = \(result.add.count)")
            XCTAssert(result.add == [mock_0e])
            XCTAssert(result.remove == [])
        } else {
            XCTFail()
        }
    }
}

struct MockComparer: ArrayComparer { }

protocol ArrayComparer {
    typealias T = MCRecordable
    
    func check(_ original: [T], against changed: [T]) -> (add: [T], remove: [T])
}

extension ArrayComparer {
    
    func check(_ original: [T], against changed: [T]) -> (add: [T], remove: [T]) {
        let added = changed - original
        let removed = original - changed
        
        let remainder = original - removed
        let edited = remainder.filter { unedited in
            for change in changed {
                if change == unedited {
                    return !(change.recordFields == unedited.recordFields)
                }
            }
            
            return false
        }
print("                 edited = \(edited.map({ $0.recordID.recordName }))")
        return (added + edited, removed)
    }
}

func -(lhs: [MCRecordable], rhs: [MCRecordable]) -> [MCRecordable] {
    return lhs.filter { left in
        return !rhs.contains { $0 == left }
    }
}

func == (lhs: [MCRecordable], rhs: [MCRecordable]) -> Bool {
print("                 lhs = \(lhs), rhs = \(rhs)")
    guard lhs.count == rhs.count else { return false }
print("                 passed guard, then = \((lhs - rhs).count)")
    return (lhs - rhs).count == 0
}

func ==(lhs: Dictionary<String, CKRecordValue>, rhs: Dictionary<String, CKRecordValue>) -> Bool {
    guard lhs.count == rhs.count else { return false }

    for key in lhs.keys {
        guard let left = lhs[key], let right = rhs[key] else { return false }
        guard left.description == right.description else { return false }
    }
    
    return true
}
