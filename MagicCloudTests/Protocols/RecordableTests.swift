//
//  RecordableTests.swift
//
//  Created by j.lingo on 10/9/16.
//  Copyright © 2016 j.lingo. All rights reserved.
//
import XCTest
import CloudKit

class RecordableTests: XCTestCase {
    
    // MARK: - Properties
    
    fileprivate let queue = OperationQueue()
    
    fileprivate var mock: MCRecordable?
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        
        mock = MockRecordable()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Tests: Protocol Conformance
    
    func testRecordableHasRecordType() { XCTAssertNotNil(mock?.recordType) }
    
    func testRecordableHasRecordID() { XCTAssertNotNil(mock?.recordID) }
    
    func testRecordableHasDictionaryOfRecordFields() { XCTAssertNotNil(mock?.recordFields) }
        
    func testRecordableRecordFieldsCanBeSet() {
        let altDate = Date(timeIntervalSince1970: 5)
        let altMock = MockRecordable(created: altDate)
        if let date = altMock.recordFields[MockRecordable.key] as? Date {
            mock?.recordFields[MockRecordable.key] = date as CKRecordValue
            XCTAssert((mock as! MockRecordable).created == altMock.created)
        } else {
            XCTFail()
        }
    }
    
    func testRecordableRequiresBlankInit() {
        XCTAssertNotNil(MockRecordable())
    }
}


// MARK: - Mock

/// Mock instance that only conforms to `Recordable` for testing and prototype development.
public class MockRecordable: MCRecordable {   // <-- remove publix (below, too) after testing remote subscriptions
    
    // MARK: - Properties
    
    fileprivate var _recordID: CKRecordID?
    
    var created = Date()
    
    // MARK: - Properties: Static Values
    
    static let key = "MockValue"
    static let mockType = "MockRecordable"
    
    // MARK: - Properties: Recordable
    
    public var recordType: String { return MockRecordable.mockType }
    
    public var recordFields: Dictionary<String, CKRecordValue> {
        get { return [MockRecordable.key: created as CKRecordValue] }
        set {
            if let date = newValue[MockRecordable.key] as? Date { created = date }
        }
    }

    public var recordID: CKRecordID {
        get { return _recordID ?? CKRecordID(recordName: "EmptyRecord") }
        set { _recordID = newValue }
    }

    // MARK: - Functions: Constructor
    
    public required init() { }
    
    init(created: Date? = nil) {
        if let date = created { self.created = date }
    }
}

extension MockRecordable: Equatable { }

public func ==(left: MockRecordable, right: MockRecordable) -> Bool {
    return left.created == right.created
}
