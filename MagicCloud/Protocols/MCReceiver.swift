//
//  Receiver.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/**
    This protocol enables conforming types to give access to an array of Recordable, and
    to prevent / allow that array's didSet to upload said array's changes to the cloud.
 */
public protocol MCReceiver: AnyObject {
    
    /// Receivers can only work with one type (for error handling).
    associatedtype type: MCRecordable
    
    /// This protected property is an array of recordables used by reciever.
    var recordables: [type] { get set }
    
    /// This property stores the subscriptionID used by the receiver and should not be modified.
    var subscription: MCSubscriber { get }
    
    /**
        This method subscribes to changes from the specified database, and prepares handling of events.
        Any changes that are detected will be reflected in recordables array.
     
        Implementation for this method should not be overwritten.
     */
    func subscribeToChanges(on: MCDatabaseType)
    
    /// This method unsubscribes from changes to the specified database.
    /// Implementation for this method should not be overwritten.
    func unsubscribeToChanges(from: MCDatabaseType)
    
    /// This method empties recordables, and refills it from the specified database.
    /// Implementation for this method should not be overwritten.
    func downloadAll(from: MCDatabaseType, completion: OptionalClosure)
}

public extension MCReceiver {
    
    // MARK: - Properties
    
    /// This closure contains behavior responding to database change notification.
    fileprivate var databaseChanged: NotifyBlock {
        return { notification in
            if let info = notification.userInfo {
                let notice = CKQueryNotification(fromRemoteNotificationDictionary: info)
                let trigger = notice.queryNotificationReason
                let db = MCDatabaseType.from(scope: notice.databaseScope)
                
                guard let id = notice.recordID else { return }

                self.respondTo(trigger, for: id, on: db)
            }
        }
    }
    
    // MARK: - Functions
    
    /**
        This method responds to the various types of changes to the specified database. In the event of a record
        deletion, associated recordable is removed from recordables. If a record is updated, the local copy is
        removed from recordables and replaced by a fresh download. If a record is created, a new recordable is
        made from a downloaded record.
    
        - Parameters:
            - trigger: The type of change reported by the database.
            - id: The id for the record that was changed.
            - db: The database that was changed.
     */
    fileprivate func respondTo(_ trigger: CKQueryNotificationReason, for id: CKRecordID, on db: MCDatabaseType) {
        switch trigger {
        case .recordDeleted:
            if let index = self.recordables.index(where: { $0.recordID.isEqual(id) }) { self.recordables.remove(at: index) }
        case .recordUpdated:
            if let index = self.recordables.index(where: { $0.recordID.recordName == id.recordName }) {
                self.recordables.remove(at: index)
                
                let op = Download(type: type().recordType,
                                  queryField: "recordID",
                                  queryValues: [CKReference(recordID: id, action: .none)],
                                  to: self, from: db)
                OperationQueue().addOperation(op)
            }
        case .recordCreated:
            let op = Download(type: type().recordType,
                              queryField: "recordID",
                              queryValues: [CKReference(recordID: id, action: .none)],
                              to: self, from: db)
            OperationQueue().addOperation(op)
        }
    }
    
    /// This method is triggered by the remote notification subscribeToChanges(on:) setup.
    fileprivate func listenForDatabaseChanges() {
        NotificationCenter.default.addObserver(forName: Notification.Name(type().recordType),
                                               object: nil,
                                               queue: nil,
                                               using: databaseChanged)
    }
    
    // MARK: - Functions: ReceivesRecordable
    
    /// This method subscribes to changes from the specified database, and prepares handling of events.
    /// Any changes that are detected will be reflected in recordables array.
    public func subscribeToChanges(on db: MCDatabaseType) {
        let empty = type()
        let triggers: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        subscription.start(for: empty.recordType, change: triggers, at: db)
        
        listenForDatabaseChanges()
    }
    
    /// This method unsubscribes from changes to the specified database.
    public func unsubscribeToChanges(from db: MCDatabaseType) { subscription.end(at: db) }
    
    // !!
    public func downloadAll(from db: MCDatabaseType, completion: OptionalClosure = nil) {
        let empty = type()

        let op = Download(type: empty.recordType, to: self, from: db)
        op.completionBlock = {
            if let block = completion { block() }
        }

        // empties recordables, before downloading
        recordables = []
        OperationQueue().addOperation(op)
    }
}
