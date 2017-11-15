//
//  PartialErrorTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class PartialErrorTests: XCTestCase {
    
    // MARK: - Properties
    
    var testOp: PartialError?
    
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
    
    var failedOp: Upload?
    
    var mocks: [Recordable]?
    
    var database: CKDatabase {
        return CKContainer.default().privateCloudDatabase
    }
    
    // MARK: - Functions
    
    func loadMocks() {
        mocks = [Recordable]()
        mocks?.append(MockRecordable())
        mocks?.append(MockRecordable(created: Date.distantPast))
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
        let prepOp = Delete(mocks!)
        let pause   = Pause(seconds: 3)
        let cleanUp = Delete(mocks!)
        
        // This operation will verify that mock was uploaded, and record it's findings in `recordInDatabase`.
        let mockIDs = mocks!.map({ $0.recordID })
        let verifyOp = CKFetchRecordsOperation(recordIDs: mockIDs)
        verifyOp.fetchRecordsCompletionBlock = { results, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: verifyOp,
                                                      instances: self.mocks!,
                                                      target: self.database)
                    ErrorQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testPartialErrorHandles.0")
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
                                                      instances: self.mocks!,
                                                      target: self.database)
                    errorHandler.ignoreUnknownItem = true
                    ErrorQueue().addOperation(errorHandler)
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
        failedOp = Upload(mocks!)
        testOp = PartialError(error: error, occuredIn: failedOp!, instances: mocks!, target: database)
    }
    
    override func tearDown() {
        mocks = nil
        failedOp = nil
        testOp = nil
        
        super.tearDown()
    }
}
