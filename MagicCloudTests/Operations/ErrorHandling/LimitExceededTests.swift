//
//  LimitExceededTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class LimitExceededTests: XCTestCase {
    
    // MARK: - Properties
    
    var testOp: LimitExceeded<MockReceiver>?
    
    var mock: Upload<MockReceiver>?
    
    var mockRec = MockReceiver()
    
    var mocks: [MockRecordable]?
    
    var error: CKError {
        let error = NSError(domain: CKErrorDomain, code: CKError.limitExceeded.rawValue, userInfo: nil)
        return CKError(_nsError: error)
    }
    
    // MARK: - Functions
    
    func loadMocks() {
        mocks = [MockRecordable]()
        mocks?.append(MockRecordable())
        mocks?.append(MockRecordable(created: Date.distantPast))
    }
    
    // MARK: - Functions: Unit Tests
    
    func testLimitExceededResolves() {

        // Used to track all records existance.
        var recordsInDatabase = true
        var recordInDatabase = false {
            didSet {
                if !recordInDatabase { recordsInDatabase = false }
            }
        }
        
        // Creates mock error situation.
        testOp = LimitExceeded(error: error, occuredIn: mock!, rec: mockRec, instances: mocks!, target: .privateDB)
        
        // These operations are used in test sequence.
        let prepOp = Delete(mocks, of: mockRec, from: .privateDB)
        let pause   = Pause(seconds: 3)
        let cleanUp = Delete(mocks, of: mockRec, from: .privateDB)

        // This operation will verify that mock was uploaded, and record it's findings in `recordInDatabase`.
        let mockIDs = mocks!.map({ $0.recordID })
        let verifyOp = CKFetchRecordsOperation(recordIDs: mockIDs)
        verifyOp.fetchRecordsCompletionBlock = { results, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: verifyOp,
                                                      target: .privateDB,
                                                      instances: self.mocks!,
                                                      receiver: self.mockRec)
                    ErrorQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testLimitExceededHandles.0")
                }
                
                return
            }
            
            // This cleans up the database, and removes test record.
            CloudQueue().addOperation(cleanUp)
        }
        
        verifyOp.perRecordCompletionBlock = { record, id, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: verifyOp,
                                                      target: .privateDB,
                                                      instances: self.mocks!,
                                                      receiver: self.mockRec)
                    errorHandler.ignoreUnknownItem = true
                    ErrorQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testLimitExceededHandles.1")
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

        ErrorQueue().addOperation(testOp!)
        ErrorQueue().addOperation(pause)
        CloudQueue().addOperation(verifyOp)
        CloudQueue().addOperation(prepOp)
        
        verifyOp.waitUntilFinished()
        XCTAssert(recordsInDatabase)
    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()
     
        loadMocks()
        mock = Upload(mocks!, from: mockRec, to: .privateDB)
    }
    
    override func tearDown() {
        mocks = nil
        mock = nil
        
        super.tearDown()
    }
}
