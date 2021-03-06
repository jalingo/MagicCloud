//
//  PartialErrorTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class PartialErrorTests: XCTestCase {
    
    // MARK: - Properties
    
    var testOp: MockPartialResolver?
    
    var error: CKError {
     
        var infoDict: [AnyHashable: Any] {
            var dict = [AnyHashable: Any]()
            
            let info: [AnyHashable : Any] = [CKErrorRetryAfterKey: 0]   // <-- Does the error code match this?
            let error = NSError(domain: CKErrorDomain, code: CKError.limitExceeded.rawValue, userInfo: info as? [String : Any])
            let cloudError = CKError(_nsError: error)
            
            dict[CKPartialErrorsByItemIDKey] = mocks?.map({ [$0.recordID: cloudError] })
            
            return dict
        }
        
        let error = NSError(domain: CKErrorDomain, code: CKError.partialFailure.rawValue, userInfo: infoDict as? [String : Any])
        return CKError(_nsError: error)
    }
    
    var failedOp: MCUpload<MCMirror<MockRecordable>>?
    
    var mocks: [MockRecordable]?
    
    var mockRec = MCMirror<MockRecordable>(db: .privateDB)
    
    var database: MCDatabase { return .privateDB }
    
    // MARK: - Functions
    
    func loadMocks() {
        mocks = [MockRecordable]()
        mocks?.append(MockRecordable())
        mocks?.append(MockRecordable(created: Date.distantPast))
        
        mockRec = MCMirror<MockRecordable>(db: .privateDB)
    }
    
    // MARK: - Functions: Unit Tests
    
    func testPartialErrorResolves() {
    
        // Used to track all records existance.
        var recordsInDatabase = true
        var recordInDatabase = false {
            didSet {
                if !recordInDatabase { recordsInDatabase = false }
            }
        }
    
        // These operations are used in test sequence.
        let prepOp = MCDelete(mocks, of: mockRec, from: database)
        let pause   = Pause(seconds: 3)
        let cleanUp = MCDelete(mocks, of: mockRec, from: database)
        
        // This operation will verify that mock was uploaded, and record it's findings in `recordInDatabase`.
        let mockIDs = mocks!.map({ $0.recordID })
        let verifyOp = CKFetchRecordsOperation(recordIDs: mockIDs)
        verifyOp.fetchRecordsCompletionBlock = { results, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: verifyOp,
                                                      target: self.database,
                                                      instances: self.mocks!,
                                                      receiver: self.mockRec)
                    OperationQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testPartialErrorHandles.0")
                }
                
                return
            }
            
            // This cleans up the database, and removes test record.
            OperationQueue().addOperation(cleanUp)
        }

        verifyOp.perRecordCompletionBlock = { record, id, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: verifyOp,
                                                      target: self.database,
                                                      instances: self.mocks!,
                                                      receiver: self.mockRec)
                    errorHandler.ignoreUnknownItem = true
                    OperationQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testPartialErrorHandles.1")
                }
                
                return
            }
            
            if let identity = id, let identities = self.mocks?.map({ $0.recordID }) {
                recordInDatabase = identities.contains(identity)
            }
        }
        
        /*
         * Test Breakdown:
         * (1) prepOp ensures no mocks in db
         * (2) testOp fulfills failedOp, saving mocks to db
         * (3) pause gives testOp time to complete async
         * (4) verifyOp ensures mocks made it to db
         * (5) cleanUp purges mocks from db
         * (6) Asserts that 'recordsInDatabase'
         */
        
        testOp?.addDependency(prepOp)
        pause.addDependency(testOp!)
        verifyOp.addDependency(pause)
        
        OperationQueue().addOperation(testOp!)
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(prepOp)
        
        verifyOp.waitUntilFinished()
        XCTAssert(recordsInDatabase)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        loadMocks()
        failedOp = MCUpload(mocks, from: mockRec, to: database)
        testOp = MockPartialResolver(error: error, in: failedOp!, with: mocks!, from: mockRec, on: database)
//        testOp = PartialError(error: error, occuredIn: failedOp!, at: mockRec, instances: mocks as! [MockRecordable], target: database)
    }
    
    override func tearDown() {
        mocks = nil
        failedOp = nil
        testOp = nil
        
        super.tearDown()
    }
}

class MockPartialResolver: Operation, MCDatabaseModifier, MCCloudErrorHandler, PartialErrorResolver {

    // MARK: - Properties
    
    var error: CKError
    
    var failedOp: Operation
    
    var ignoreUnknownItem: Bool = false
    
    var ignoreUnknownItemCustomAction: OptionalClosure

    // MARK: - Properties: MCDatabaseModifier & MCCloudErrorHandler
    
    var receiver: MCMirror<MockRecordable>
    
    var recordables: [MockPartialResolver.R.type]
    
    typealias R = MCMirror<MockRecordable>
    
    var database: MCDatabase
    
    // MARK: - Functions
    
    override func main() {
        self.resolvePartial(error, in: failedOp)
    }
    
    init(error: CKError, in op: Operation, with recs: [MockRecordable], from mockRec: MCMirror<MockRecordable>, on db: MCDatabase) {
        self.error = error
        self.failedOp = op
        self.recordables = recs
        self.receiver = mockRec as MCMirror<MockRecordable>
        self.database = db
    }
}
