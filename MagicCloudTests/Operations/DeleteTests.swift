//
//  DeleteTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import XCTest
import CloudKit

class DeleteTests: XCTestCase {
    
    // MARK: - Properties
    
    var testOp: Delete<MockReceiver>?

    var mock: MockRecordable?
    
    var mockRec = MockReceiver()
    
    var recordDeleted = false
    
    // MARK: - Functions
    
    fileprivate func verifyOperation(ids: [CKRecordID], failWhenFound: Bool = true) -> CKFetchRecordsOperation {
        let op = CKFetchRecordsOperation(recordIDs: ids)
        
        op.fetchRecordsCompletionBlock = { results, error in
            guard error == nil else {
                if let cloudError = error as? CKError {
                    if cloudError.code == .unknownItem {
                        self.recordDeleted = true   // <-- This is what test expects to happen (if op wasn't a batch).
                    } else if cloudError.code == .partialFailure {
                        if let dictionary = cloudError.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
                            for entry in dictionary {
                                if let cError = entry.value as? CKError {
                                    if cError.code == .unknownItem {
                                        self.recordDeleted = true          // <-- This is what test expects to happen.
                                    } else {
                                        let errorHandler = MCErrorHandler(error: cError,
                                                                          originating: op,
                                                                          target: .privateDB,
                                                                          instances: [self.mock!],
                                                                          receiver: self.mockRec)
                                        errorHandler.ignoreUnknownItem = true
                                        ErrorQueue().addOperation(errorHandler)
                                    }
                                }
                            }
                        }
                    } else {
                        let errorHandler = MCErrorHandler(error: cloudError,
                                                          originating: op,
                                                          target: .privateDB,
                                                          instances: [self.mock!],
                                                          receiver: self.mockRec)
                        errorHandler.ignoreUnknownItem = true
                        ErrorQueue().addOperation(errorHandler)
                    }
                } else {
                    print("NSError: \(error!) @ DeleteTests.0")
                }
                
                return
            }
print("!! Records FOUND: \(String(describing: results?.count))")
            if let dictionary = results {
                for entry in dictionary {
                    print("key: \(entry.key)")
                    print("value: \(entry.value)")

                    let cleanUpAfterFailure = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [entry.key])
                    if #available(iOS 11.0, *) {
                        cleanUpAfterFailure.configuration.isLongLived = true
                    } else {
                        cleanUpAfterFailure.isLongLived = true
                    }
                    CloudQueue().addOperation(cleanUpAfterFailure)
                }
            }
            
            if failWhenFound { XCTFail() }
            
        }
        
        return op
    }
    
    // MARK: - Functions: Unit Tests
    
    func testDeleteIsOp() { XCTAssertNotNil(testOp?.isFinished) }
    
    func testDeleteHasRecordables() { XCTAssertNotNil(testOp?.recordables) }
    
    func testDeleteHasDelay() { XCTAssertNotNil(testOp?.delayInSeconds) }
    
    func testDeleteDelaysLaunch() {
        let delay: UInt64 = 5
        testOp?.delayInSeconds = delay
    
        let prepOp = Upload([mock!], from: mockRec, to: .privateDB)
        let prepCompleted = expectation(description: "record uploaded")
        prepOp.completionBlock = { prepCompleted.fulfill() }
        CloudQueue().addOperation(prepOp)
        
        wait(for: [prepCompleted], timeout: 3)
        let priPause = Pause(seconds: TimeInterval(delay - 1))
        let altPause = Pause(seconds: TimeInterval(delay + 1))
        
        let verifyWait = verifyOperation(ids: [mock!.recordID], failWhenFound: false)
        verifyWait.addDependency(priPause)
        
        let verifyDone = verifyOperation(ids: [mock!.recordID])
        verifyDone.addDependency(altPause)
        
        CloudQueue().addOperation(verifyDone)
        CloudQueue().addOperation(verifyWait)
        CloudQueue().addOperation(testOp!)
        CloudQueue().addOperation(altPause)
        CloudQueue().addOperation(priPause)
        
        verifyWait.waitUntilFinished()
        XCTAssertFalse(recordDeleted)
        
        verifyDone.waitUntilFinished()
        XCTAssert(recordDeleted)
    }
    
    func testDeleteOnPrivate() {
        let uploaded = expectation(description: "Mock Object Uploaded")
        let prepOp = Upload([mock!], from: mockRec, to: .privateDB)
        prepOp.completionBlock = { uploaded.fulfill() }

        CloudQueue().addOperation(prepOp)
        wait(for: [uploaded], timeout: 2)

        let firstPause = Pause(seconds: 2)
        testOp?.addDependency(firstPause)
        
        let deleted = expectation(description: "Mock Object Deleted")
        testOp?.completionBlock = { deleted.fulfill() }

        CloudQueue().addOperation(testOp!)
        CloudQueue().addOperation(firstPause)
        wait(for: [deleted], timeout: 4)
        
        let secondPause = Pause(seconds: 2)
        let verifyOp = verifyOperation(ids: [mock!.recordID])
        verifyOp.addDependency(secondPause)
        
        CloudQueue().addOperation(verifyOp)
        CloudQueue().addOperation(secondPause)
        
        verifyOp.waitUntilFinished()
        XCTAssert(recordDeleted)
    }
    
    func testDeleteOnPublic() {
        let uploaded = expectation(description: "Mock Object Uploaded")
        let prepOp = Upload([mock!], from: mockRec, to: .publicDB)
        prepOp.completionBlock = { uploaded.fulfill() }
        
        CloudQueue().addOperation(prepOp)
        wait(for: [uploaded], timeout: 3)
        
        testOp = Delete([mock!], from: mockRec, to: .publicDB)
        
        let firstPause = Pause(seconds: 5)
        testOp?.addDependency(firstPause)
        
        let deleted = expectation(description: "Mock Object Deleted")
        testOp?.completionBlock = { deleted.fulfill() }
        
        CloudQueue().addOperation(testOp!)
        CloudQueue().addOperation(firstPause)
        wait(for: [deleted], timeout: 7)
        
        let verifyOp = verifyOperation(ids: [mock!.recordID])
        CloudQueue().addOperation(verifyOp)
        
        verifyOp.waitUntilFinished()
        XCTAssert(recordDeleted)
    }

//    func testPerformance() {
//        self.measure {
//            self.testOp = Delete([self.mock!])
//            let prepOp = Upload([self.mock!])
//            self.testOp?.addDependency(prepOp)
//            CloudQueue().addOperation(prepOp)
//            CloudQueue().addOperation(self.testOp!)
//            self.testOp?.waitUntilFinished()
//            print("performance test completed")
//        }
//    }

    // MARK: - Functions: XCTestCase
    
    override func setUp() {
        super.setUp()

        mock = MockRecordable()
        mockRec = MockReceiver()
        testOp = Delete([mock!], from: mockRec, to: .privateDB)
        recordDeleted = false
    }
    
    override func tearDown() {
        mock = nil
        testOp = nil
        
        let group = DispatchGroup()
        group.enter()
        
        let pause = Pause(seconds: 2)
        pause.completionBlock = { group.leave() }
        OperationQueue().addOperation(pause)
        
        group.wait()
        super.tearDown()
    }
}