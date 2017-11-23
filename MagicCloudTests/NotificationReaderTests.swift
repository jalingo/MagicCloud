//
//  NotificationReaderTests.swift
//  MagicCloudTests
//
//  Created by James Lingo on 11/21/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import XCTest
import CloudKit

class NotificationReaderTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockRec: MockReceiver?
    
    // MARK: - Functions
    
    override func setUp() {
        super.setUp()
        mockRec = MockReceiver()
    }
    
    override func tearDown() {
        super.tearDown()
        mockRec = nil
    }

    // MARK: - Functions: Tests
    
    func testNotificationReceiverCanConvertRemoteNotificationToLocal() {
        mockRec?.subscribeToChanges(on: .publicDB)
        
        
        
        
    }
}

protocol NotificationReader {
    static func createLocal(from info: [AnyHashable: Any])
}

struct MCNotificationReader: NotificationReader {

    // !!
    static func handle(_ error: CKError, for info: [AnyHashable: Any]) {
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
