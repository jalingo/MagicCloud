//
//  UploadTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit
import XCTest

class UploadTests: XCTestCase {
    
    // MARK: - Properties
    
    let start = Date()
    
    let time = TimeInterval(exactly: 3)
    
    var testOp: Upload<MockReceiver>?
    
    var mocks: [MockRecordable]?
    
    var mockRec = MockReceiver()
    
    // MARK: - Functions
    
    func loadMockRecordables() {
        mocks = [MockRecordable]()
        mocks?.append(MockRecordable(created: Date.distantPast))
        mocks?.append(MockRecordable(created: start))
        mocks?.append(MockRecordable(created: Date.distantFuture))
    }
    
    // MARK: - Functions: Unit Tests
    
    func testUploadIsOp() { XCTAssertNotNil(testOp?.isFinished) }
    
    func testUploadHasRecordables() { XCTAssertNotNil(testOp?.recordables) }
    
    func testUploadWorksWithPublic() {
        
        var recordsInDatabase = true    // <-- Used to track all records existance.
        var recordInDatabase = false {
            didSet {
                if !recordInDatabase { recordsInDatabase = false }
            }
        }

        testOp = Upload(mocks, from: mockRec, to: .publicDB)

        // This operation will be used to ensure cloud database is sanitized of test mock.
        let prepOp = Delete(mocks, from: mockRec, to: .publicDB)
        prepOp.name = "UploadTests.prepOp: Public"

        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks, from: mockRec, to: .publicDB)
        cleanUp.name = "UploadTests.cleanUp: Public"

        // These pauses give the cloud database a reasonable amount of time to update between interactions.
        let firstPause = Pause(seconds: 3)
        let secondPause = Pause(seconds: 3)

        // This operation will verify that mock was uploaded, and record it's findings in `recordInDatabase`.
        let mockIDs = mocks!.map({ $0.recordID })
        let verifyOp = CKFetchRecordsOperation(recordIDs: mockIDs)
        verifyOp.name = "UploadTests.verifyOp: Public"
        verifyOp.fetchRecordsCompletionBlock = { results, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    let errorHandler = MCErrorHandler(error: cloudError,
                                                      originating: verifyOp,
                                                      target: .publicDB,
                                                      instances: self.mocks!,
                                                      receiver: self.mockRec)
                    errorHandler.ignoreUnknownItem = true
                    errorHandler.ignoreUnknownItemCustomAction = { recordInDatabase = false }
                    ErrorQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPublic.0")
                }
                
                return
            }
            
            // This cleans up the database, and removes test record.
            CloudQueue().addOperation(cleanUp)
        }

        verifyOp.perRecordCompletionBlock = { record, id, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    if cloudError.code == CKError.unknownItem {
                        recordInDatabase = false
                    } else {
                        let errorHandler = MCErrorHandler(error: cloudError,
                                                          originating: verifyOp,
                                                          target: .publicDB,
                                                          instances: self.mocks!,
                                                          receiver: self.mockRec)
                        errorHandler.ignoreUnknownItem = true
                        errorHandler.ignoreUnknownItemCustomAction = { recordInDatabase = false }
                        ErrorQueue().addOperation(errorHandler)
                    }
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPublic.1")
                }
                
                return
            }
        }

        // This is the actual test sequence (prepare -> pause -> upload -> pause -> verify w/ cleanUp).
        firstPause.addDependency(prepOp)
        testOp?.addDependency(firstPause)
        secondPause.addDependency(testOp!)
        verifyOp.addDependency(secondPause)
        
        CloudQueue().addOperation(firstPause)
        CloudQueue().addOperation(testOp!)
        CloudQueue().addOperation(secondPause)
        DatabaseType.publicDB.db.add(verifyOp)
        CloudQueue().addOperation(prepOp)   // <-- Starts operation chain.
        
        // Waits for operations to complete and then evaluates test.
        verifyOp.waitUntilFinished()
        XCTAssert(recordsInDatabase)
    }
    
    func testUploadWorksWithPrivate() {
        let database = CKContainer.default().privateCloudDatabase
        
        var recordsInDatabase = true    // <-- Used to track all records existance.
        var recordInDatabase = false {
            didSet {
                if !recordInDatabase { recordsInDatabase = false }
            }
        }
        
        // This operation will be used to ensure cloud database is sanitized of test mock.
        let prepOp = Delete(mocks!, from: mockRec, to: .privateDB)
        
        // This operation will be used to clean up the database after the test finishes.
        let cleanUp = Delete(mocks!, from: mockRec, to: .privateDB)
        
        // These pauses give the cloud database a reasonable amount of time to update between interactions.
        let firstPause = Pause(seconds: 3)
        let secondPause = Pause(seconds: 3)
        
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
                    errorHandler.ignoreUnknownItem = true
                    errorHandler.ignoreUnknownItemCustomAction = { recordInDatabase = false }
                    ErrorQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPrivate.0")
                }
                
                return
            }
            
            // This cleans up the database, and removes test record.
            CloudQueue().addOperation(cleanUp)
        }
        
        verifyOp.perRecordCompletionBlock = { record, id, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    if cloudError.code == CKError.unknownItem {
                        recordInDatabase = false
                    } else {
                        let errorHandler = MCErrorHandler(error: cloudError,
                                                          originating: verifyOp,
                                                          target: .privateDB,
                                                          instances: self.mocks!,
                                                          receiver: self.mockRec)
                        errorHandler.ignoreUnknownItem = true
                        errorHandler.ignoreUnknownItemCustomAction = { recordInDatabase = false }
                        ErrorQueue().addOperation(errorHandler)
                    }
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPrivate.1")
                }
                
                return
            }
        }
        
        // This is the actual test sequence (prepare -> pause -> upload -> pause -> verify w/ cleanUp).
        firstPause.addDependency(prepOp)
        testOp?.addDependency(firstPause)
        secondPause.addDependency(testOp!)
        verifyOp.addDependency(secondPause)
        
        CloudQueue().addOperation(firstPause)
        CloudQueue().addOperation(testOp!)
        CloudQueue().addOperation(secondPause)
        database.add(verifyOp)
        CloudQueue().addOperation(prepOp)   // <-- Starts operation chain.
        
        // Waits for operations to complete and then evaluates test.
        verifyOp.waitUntilFinished()
        XCTAssert(recordsInDatabase)
    }

//    func testPerformance() {
//        self.measure {
//            let cleanUp = Delete(self.mocks!)
//            
//            self.testOp = Upload(self.mocks!)
//            cleanUp.addDependency(self.testOp!)
//            
//            CloudQueue().addOperation(cleanUp)
//            
//            let expect = self.expectation(description: "upload perf tests")
//            self.testOp?.completionBlock = { expect.fulfill() }
//            CloudQueue().addOperation(self.testOp!)
//            
//            self.wait(for: [expect], timeout: 2)
//            print("perf test completed")
//        }
//    }
    
    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        loadMockRecordables()
        testOp = Upload(mocks!, from: mockRec, to: .privateDB)
    }
    
    override func tearDown() {
        testOp = nil
        mocks = nil
        
        // This gives time between tests, for all database requests from previous interactions to be served.
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 5)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        super.tearDown()
    }
}
