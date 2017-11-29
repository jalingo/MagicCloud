//
//  NotificationReader.swift
//  MagicCloud
//
//  Created by James Lingo on 11/22/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

public struct NotificationReader {
    
    // !!
    fileprivate static func handle(_ error: CKError, for info: [AnyHashable: Any]) {
print("** error @ NotificationReader \(error)")
       switch error.code {
        case .networkUnavailable, .networkFailure,
             .serviceUnavailable, .requestRateLimited,
             .resultsTruncated,   .zoneBusy:
            if let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
                let pause = Pause(seconds: retryAfterValue)
                pause.completionBlock = { NotificationReader.createLocal(from: info) }
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
    public static func createLocal(from info: [AnyHashable: Any]) {
//        let converter = MockNotificationConverter()
//        converter.toLocal(from: info)
        
        // Pull a CKNotification from userInfo, containing triggers and ckrecordID
        let remote = CKQueryNotification(fromRemoteNotificationDictionary: info)
        
        // recover record type from remote?
//        remote.subscriptionID
        
        let database = DatabaseType.from(scope: remote.databaseScope)
print("** creating local notification")
        guard let id = remote.recordID else { return }
print("** recordID found \(id.recordName)")
        let op = CKFetchRecordsOperation(recordIDs: [id])
        op.qualityOfService = .userInteractive
        op.fetchRecordsCompletionBlock = { possibleResults, possibleError in
print("** completing fetch")
            if let error = possibleError as? CKError { NotificationReader.handle(error, for: info) }

            guard let results = possibleResults else { return }
print("** results found \(results.count)")
            if let type = results[id]?.recordType {     // <-- Will not fetch if change was deletion...
print("** type \(type) found")
                let change = MCNotification.changeNoticed(forType: type, at: database)
                let local = Notification.Name(change.toString())
print("** name: \(local)")
                NotificationCenter.default.post(name: local, object: change)
            }
        }

        database.db.add(op)
    }
}

public protocol NotificationConverter {
    associatedtype type: Recordable
    func toLocal(from info: [AnyHashable: Any])
}

public extension NotificationConverter {
    
    public func toLocal(from info: [AnyHashable: Any]) {
        // Pull a CKNotification from userInfo, containing triggers and ckrecordID
        let remote = CKQueryNotification(fromRemoteNotificationDictionary: info)
        let database = DatabaseType.from(scope: remote.databaseScope)
print("** creating local notification = \(DatabaseType.from(scope: remote.databaseScope))")
//        guard let id = remote.recordID else { return }
        
        let change = MCNotification.changeNoticed(forType: type().recordType, at: database)
        let local = Notification.Name(change.toString())
print("** name: \(local)")
        NotificationCenter.default.post(name: local, object: change)
    }
}

struct MockNotificationConverter: NotificationConverter {
    typealias type = MockRecordable
}
