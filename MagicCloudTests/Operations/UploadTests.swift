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
    
    var testOp: MCUpload<MockReceiver>?
    
    var mocks: [MockRecordable]?
    
    var mockRec = MockReceiver()
    
    var databaseNeedsCleanUp = false
    
    var firstRun = true
    
    // MARK: - Functions
    
    func loadMockRecordables() {
        mocks = [MockRecordable]()
        
        let first = MockRecordable(created: Date.distantPast)
        first.recordID = CKRecordID(recordName: "Distant-Past")
        mocks?.append(first)

        let second = MockRecordable(created: start)
        second.recordID = CKRecordID(recordName: "Present")
        mocks?.append(second)
        
        let third = MockRecordable(created: Date.distantFuture)
        third.recordID = CKRecordID(recordName: "Distant-Future")
        mocks?.append(third)
    }
    
    func cleanUpDatabase() {
        // This gives time between tests, for all database requests from previous interactions to be served.
        let pause = Pause(seconds: 3)
        let clean = MCDelete(mocks, of: mockRec, from: .publicDB)
        pause.addDependency(clean)
        
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(clean)
        pause.waitUntilFinished()
    }
    
    // MARK: - Functions: Unit Tests
    
    func testUploadIsOp() { XCTAssertNotNil(testOp?.isFinished) }
    
    func testUploadHasRecordables() { XCTAssertNotNil(testOp?.recordables) }
    
    func testUploadWorksWithPublic() {
        databaseNeedsCleanUp = true
        
        var recordsInDatabase = true    // <-- Used to track all records existance.
        var recordInDatabase = false {
            didSet {
                if !recordInDatabase { recordsInDatabase = false }
            }
        }

        testOp = MCUpload(mocks, from: mockRec, to: .publicDB)

        let pause = Pause(seconds: 3)

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
                    OperationQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPublic.0")
                }
                
                return
            }
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
                        OperationQueue().addOperation(errorHandler)
                    }
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPublic.1")
                }
                
                return
            }
        }

        pause.addDependency(testOp!)
        verifyOp.addDependency(pause)
        
        OperationQueue().addOperation(pause)
        MCDatabase.publicDB.db.add(verifyOp)
        OperationQueue().addOperation(testOp!)          // <-- Starts operation chain.
        
        // Waits for operations to complete and then evaluates test.
        verifyOp.waitUntilFinished()
        XCTAssert(recordsInDatabase)
    }
    
    func testUploadWorksWithPrivate() {
        databaseNeedsCleanUp = true
        
        var recordsInDatabase = true    // <-- Used to track all records existance.
        var recordInDatabase = false {
            didSet {
                if !recordInDatabase { recordsInDatabase = false }
            }
        }
        
        let pause = Pause(seconds: 3)
        
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
                    OperationQueue().addOperation(errorHandler)
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPrivate.0")
                }
                
                return
            }
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
                        OperationQueue().addOperation(errorHandler)
                    }
                } else {
                    print("NSError: \(error!) @ testUploadWorksWithPrivate.1")
                }
                
                return
            }
        }
        
        pause.addDependency(testOp!)
        verifyOp.addDependency(pause)
        
        OperationQueue().addOperation(pause)
        MCDatabase.privateDB.db.add(verifyOp)
        OperationQueue().addOperation(testOp!)              // <-- Starts operation chain.

        // Waits for operations to complete and then evaluates test.
        verifyOp.waitUntilFinished()
        XCTAssert(recordsInDatabase)
    }

    func testUploadSendsLocalNotificationToTriggerMirroringInMultipleReceivers() {
        databaseNeedsCleanUp = true
        
        let altReceiver = MockReceiver()
        altReceiver.subscribeToChanges(on: .privateDB)

        mockRec.subscribeToChanges(on: .privateDB)
        
        // This q delay gives subscriptions time to error handle...
        let pause = Pause(seconds: 3)
        DispatchQueue(label: "test q").asyncAfter(deadline: .now() + 3) {
            pause.addDependency(self.testOp!)
            OperationQueue().addOperation(pause)
            OperationQueue().addOperation(self.testOp!)
        }
        
        pause.waitUntilFinished()
        XCTAssertEqual(mockRec.recordables.count, altReceiver.recordables.count)
        XCTAssert(mockRec.recordables.count != 0)
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
        testOp = MCUpload(mocks!, from: mockRec, to: .privateDB)
        
        if firstRun { cleanUpDatabase() }
        firstRun = false
    }
    
    override func tearDown() {
        testOp = nil
        mocks = nil
        
        if databaseNeedsCleanUp { cleanUpDatabase() }
        super.tearDown()
    }
}

