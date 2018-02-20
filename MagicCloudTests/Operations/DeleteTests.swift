//
//  DeleteTests.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class DeleteTests: XCTestCase {
    
    // MARK: - Properties
    
    var testOp: MCDelete<MockReceiver>?

    var mock: MockRecordable?
    
    var mockRec = MockReceiver() {
didSet { print("ø- instantiating MockReceiver") }
    }
    
    var recordDeleted = false
    
    var pauseNeeded = false
    
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
                                        OperationQueue().addOperation(errorHandler)
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
                        OperationQueue().addOperation(errorHandler)
                    }
                } else {
                    print("NSError: \(error!) @ DeleteTests.0")
                }
                
                return
            }

            if let dictionary = results {
                for entry in dictionary {

                    let cleanUpAfterFailure = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [entry.key])
                    if #available(iOS 11.0, *) {
                        cleanUpAfterFailure.configuration.isLongLived = true
                    } else {
                        cleanUpAfterFailure.isLongLived = true
                    }
                    OperationQueue().addOperation(cleanUpAfterFailure)
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
        pauseNeeded = true
        
        let delay: Double = 5
        testOp?.delayInSeconds = delay
    
        let prepOp = MCUpload([mock!], from: mockRec, to: .privateDB)
        let prepCompleted = expectation(description: "record uploaded")
        prepOp.completionBlock = { prepCompleted.fulfill() }
        OperationQueue().addOperation(prepOp)
        
        wait(for: [prepCompleted], timeout: 3)
        let priPause = Pause(seconds: TimeInterval(delay - 1))
        let altPause = Pause(seconds: TimeInterval(delay + 1))
        
        let verifyWait = verifyOperation(ids: [mock!.recordID], failWhenFound: false)
        verifyWait.addDependency(priPause)
        
        let verifyDone = verifyOperation(ids: [mock!.recordID])
        verifyDone.addDependency(altPause)
        
        OperationQueue().addOperation(verifyDone)
        OperationQueue().addOperation(verifyWait)
        OperationQueue().addOperation(testOp!)
        OperationQueue().addOperation(altPause)
        OperationQueue().addOperation(priPause)
        
        verifyWait.waitUntilFinished()
        XCTAssertFalse(recordDeleted)
        
        verifyDone.waitUntilFinished()
        XCTAssert(recordDeleted)
    }
    
    func testDeleteOnPrivate() {
        pauseNeeded = true

        let uploaded = expectation(description: "Mock Object Uploaded")
        let prepOp = MCUpload([mock!], from: mockRec, to: .privateDB)
        prepOp.completionBlock = { uploaded.fulfill() }

        OperationQueue().addOperation(prepOp)
        wait(for: [uploaded], timeout: 2)

        let firstPause = Pause(seconds: 2)
        testOp?.addDependency(firstPause)
        
        let deleted = expectation(description: "Mock Object Deleted")
        testOp?.completionBlock = { deleted.fulfill() }

        OperationQueue().addOperation(testOp!)
        OperationQueue().addOperation(firstPause)
        wait(for: [deleted], timeout: 7)
        
        let secondPause = Pause(seconds: 2)
        let verifyOp = verifyOperation(ids: [mock!.recordID])
        verifyOp.addDependency(secondPause)
        
        OperationQueue().addOperation(verifyOp)
        OperationQueue().addOperation(secondPause)
        
        verifyOp.waitUntilFinished()
        XCTAssert(recordDeleted)
    }
    
    func testDeleteOnPublic() {
        pauseNeeded = true

        let uploaded = expectation(description: "Mock Object Uploaded")
        let prepOp = MCUpload([mock!], from: mockRec, to: .publicDB)
        prepOp.completionBlock = { uploaded.fulfill() }
        
        OperationQueue().addOperation(prepOp)
        wait(for: [uploaded], timeout: 3)
        
        testOp = MCDelete([mock!], of: mockRec, from: .publicDB)
        
        let firstPause = Pause(seconds: 5)
        testOp?.addDependency(firstPause)
        
        let deleted = expectation(description: "Mock Object Deleted")
        testOp?.completionBlock = { deleted.fulfill() }
        
        OperationQueue().addOperation(testOp!)
        OperationQueue().addOperation(firstPause)
        wait(for: [deleted], timeout: 7)
        
        let verifyOp = verifyOperation(ids: [mock!.recordID])
        OperationQueue().addOperation(verifyOp)
        
        verifyOp.waitUntilFinished()
        XCTAssert(recordDeleted)
    }

    func testDeleteSendsLocalNotificationToTriggerMirroringInMultipleReceivers() {
        pauseNeeded = true
        testOp = MCDelete([mock!], of: mockRec, from: .publicDB)

        let altReceiver = MCMirror<MockRecordable>(db: .publicDB)
        mockRec.subscribeToChanges(on: .publicDB)

        // This pause will give prep the time to download to receivers
        let firstPause = Pause(seconds: 5)

        // This q delay gives subscriptions time to error handle...
        DispatchQueue(label: "test q").asyncAfter(deadline: .now() + 5) {
            let prep = MCUpload([self.mock!], from: self.mockRec, to: .publicDB)
            firstPause.addDependency(prep)
            
            OperationQueue().addOperation(firstPause)
            OperationQueue().addOperation(prep)
        }
        
        firstPause.waitUntilFinished()

        XCTAssertEqual(mockRec.silentRecordables.count, altReceiver.silentRecordables.count)
        XCTAssert(mockRec.silentRecordables.count != 0)

        let secondPause = Pause(seconds: 5)
        secondPause.addDependency(testOp!)
        OperationQueue().addOperation(secondPause)
        OperationQueue().addOperation(testOp!)

        secondPause.waitUntilFinished()

        XCTAssertEqual(mockRec.silentRecordables.count, altReceiver.silentRecordables.count)
        XCTAssert(mockRec.silentRecordables.count == 0)
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
        testOp = MCDelete([mock!], of: mockRec, from: .privateDB)
        recordDeleted = false
    }
    
    override func tearDown() {
        mock = nil
        testOp = nil
        
        if pauseNeeded {
            let pause = Pause(seconds: 2)
            OperationQueue().addOperation(pause)
            pause.waitUntilFinished()
        }
        
        super.tearDown()
    }
}
