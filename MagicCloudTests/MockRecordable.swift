//
//  MockRecordable.swift
//  MagicCloudTests
//
//  Created by James Lingo on 2/6/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// This mock class was built for testing MCRecordable.
public class MockRecordable: MCRecordable {
    
    // MARK: - Properties
    
    fileprivate var _recordID: CKRecordID?
    
    var created = Date()
    
    // MARK: - Properties: Static Values
    
    /// "MockValue"
    static let key = "MockValue"

    /// "MockRecordable"
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
        _recordID = CKRecordID(recordName: "Mock Created: \(self.created)")
    }
}
