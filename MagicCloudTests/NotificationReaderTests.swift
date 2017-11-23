//
//  NotificationReaderTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 11/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

// !! CAUTION: These tests assume MCNotificationReader is implemented in app delegate.
class NotificationReaderTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockRec: MockReceiver?
    
    var mockRecordables: [MockRecordable] {
        var array = [MockRecordable]()
        
        array.append(MockRecordable(created: Date.distantPast))
        array.append(MockRecordable(created: Date.distantFuture))
        
        return array
    }
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        mockRec = MockReceiver()
    }
    
    override func tearDown() {
        super.tearDown()        
        mockRec = nil
    }

    func prepareDatabase() -> Int {
        let op = Upload(mockRecordables, from: mockRec!, to: .publicDB)
        let pause = Pause(seconds: 3)
        pause.addDependency(op)
        pause.completionBlock = { print("finished prep pause") }
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    func cleanUpDatabase() -> Int {
        let op = Delete(mockRecordables, of: mockRec!, from: .publicDB)
        let pause = Pause(seconds: 2)
        pause.addDependency(op)
        pause.completionBlock = { print("finished cleanUp pause") }
        OperationQueue().addOperation(pause)
        OperationQueue().addOperation(op)
        
        pause.waitUntilFinished()
        return 0
    }
    
    // MARK: - Functions: Tests
    
    func testNotificationReceiverCanConvertRemoteNotificationToLocal() {
        mockRec?.subscribeToChanges(on: .publicDB)
        
        let _ = prepareDatabase()
        XCTAssert(mockRec?.recordables.count != 0)
        
        let _ = cleanUpDatabase()
        XCTAssert(mockRec?.recordables.count == 0)
    }
}

protocol NotificationReader {
    static func createLocal(from info: [AnyHashable: Any])
}

struct MCNotificationReader: NotificationReader {

    // !!
    fileprivate static func handle(_ error: CKError, for info: [AnyHashable: Any]) {
        switch error.code {
        case .networkUnavailable, .networkFailure,
             .serviceUnavailable, .requestRateLimited,
             .resultsTruncated,   .zoneBusy:
            if let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
                let pause = Pause(seconds: retryAfterValue)
                pause.completionBlock = { MCNotificationReader.createLocal(from: info) }
                pause.start()
            }
        case .unknownItem: break
        case .partialFailure:
            if let dictionary = error.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
                for entry in dictionary {
                    if let partialError = entry.value as? CKError { handle(partialError, for: info) }
                }
            }
        default:
            let name = Notification.Name(MCNotification.error(error).toString())
            NotificationCenter.default.post(name: name, object: error)
        }
    }
    
    // !!
    static func createLocal(from info: [AnyHashable: Any]) {
        // Pull a CKNotification from userInfo, containing triggers and ckrecordID
        let remote = CKQueryNotification(fromRemoteNotificationDictionary: info)
        let database = DatabaseType.from(scope: remote.databaseScope)
        
        guard let id = remote.recordID else { return }
        
        let op = CKFetchRecordsOperation(recordIDs: [id])
        op.fetchRecordsCompletionBlock = { possibleResults, possibleError in
            if let error = possibleError as? CKError { MCNotificationReader.handle(error, for: info) }
            
            guard let results = possibleResults else { return }
          
            if let type = results[id]?.recordType {
                let change = MCNotification.changeNoticed(forType: type, at: database)
                let local = Notification.Name(change.toString())
                
                NotificationCenter.default.post(name: local, object: change)
            }
        }
        
        database.db.add(op)
    }
}
