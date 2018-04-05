//
//  MCMirrorAbstraction Extension.swift
//  MagicCloud
//
//  Created by James Lingo on 4/5/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Extensions

public extension MCMirrorAbstraction {
    
    // MARK: - Properties
    
    /// Defaults to a Notification.Name constructed from MCMirrorAbstraction.name property.
    public var changeNotification: Notification.Name { return Notification.Name(name) }
    
    /// Defaults to a computed property to get `silentRecordables` & set `newValue` to cloud database (which will trigger set for `localRecordables`.
    public var cloudRecordables: [type] {
        get { return silentRecordables }
        
        set {
            let results = check(silentRecordables, against: newValue)
            
            guard results.add.count != 0 || results.remove.count != 0 || results.remove.count != 0 else { return }
            
            let q = OperationQueue()
            
            var delay: Double?
            
            if let changes = results.add + results.edited as? [type] {
                let op = MCUpload(changes, from: self, to: db)          // <- op guards against zero count internal
                q.addOperation(op)
                
                delay = 0.5
            }
            
            if let changes = results.remove as? [type] {
                let op = MCDelete(changes, of: self, from: self.db)     // <- op guards against zero count internal
                if let delay = delay { op.delayInSeconds = delay }
                q.addOperation(op)
            }
        }
    }
    
    /// Defaults to a computed property to get `silentRecordables` & set `newValue` to a `LocalChangePackage` that is broadcast through `NotificationCenter.default` (observe by `recordType` name) and set to `silentRecordables`.
    public var localRecordables: [type] {
        get { return silentRecordables }
        set {
            let results = check(silentRecordables, against: newValue)
            
            if let changes = results.add    as? [type] { notify(changes, because: .recordCreated) }
            if let changes = results.remove as? [type] { notify(changes, because: .recordDeleted) }
            if let changes = results.edited as? [type] { notify(changes, because: .recordUpdated) }
            
            silentRecordables = newValue
        }
    }
    
    /// This closure contains behavior responding to database change notification.
    fileprivate var databaseChanged: NotifyBlock {
        return { notification in
            if let change = notification.object as? LocalChangePackage {
                self.respondTo(change)
            } else if let info = notification.userInfo {
                let notice = CKQueryNotification(fromRemoteNotificationDictionary: info)
                let trigger = notice.queryNotificationReason
                let db = MCDatabase.from(scope: notice.databaseScope)
                
                guard let id = notice.recordID else { return }
                
                let change = LocalChangePackage(ids: [id], reason: trigger, originatingRec: "Remote", db: db)
                self.respondTo(change)
            }
        }
    }
    
    // MARK: - Functions
    
    /**
     This fileprivate, void method posts a notification to default NotificationCenter with recordable's type as name and a LocalChangePackage as the object, constructed from the arguments passed.
     
     - Parameters:
     - changes: An array of associated type to be either added, overwritten or removed from local storage.
     - reason: The CKQueryNotificationReason indicating whether changes should be added, overwritten or removed from local storage.
     */
    fileprivate func notify(_ changes: [type], because reason: CKQueryNotificationReason) {
        guard changes.count != 0 else { return }
        
        let name = Notification.Name(type().recordType)
        let package = LocalChangePackage(ids: changes.map { $0.recordID }, reason: reason, originatingRec: self.name, db: db)
        
        NotificationCenter.default.post(name: name, object: package)
    }
    
    /**
     This method responds to the various types of changes to the specified database.
     
     In the event of a record deletion, associated recordable is removed from recordables. If a record is updated, the local copy is removed from recordables and replaced by a fresh download. If a record is created, a new recordable is made from a downloaded record.
     
     - Parameter package: LocalChangePackage recovered from notification.
     */
    fileprivate func respondTo(_ package: LocalChangePackage) {
        
        // This guards against notifications resulting from internal changes.
        guard package.originatingRec != self.name && package.ids.count != 0 else { return }
        
        switch package.reason {
        case .recordDeleted:
            serialQ.sync {
                let missingRecordables = package.ids.map { $0.recordName }
                let reducedSet = silentRecordables.filter { !missingRecordables.contains($0.recordID.recordName) }
                silentRecordables = reducedSet
            }
        case .recordUpdated:
            serialQ.sync {
                let editedRecordables = package.ids.map { $0.recordName }
                let reducedSet = silentRecordables.filter { !editedRecordables.contains($0.recordID.recordName) }
                silentRecordables = reducedSet
                
                let refs = package.ids.map { CKReference(recordID: $0, action: .none) }
                let op = MCDownload(type: type().recordType,
                                    queryField: "recordID",
                                    queryValues: refs,
                                    to: self, from: self.db)
                OperationQueue().addOperation(op)
            }
        case .recordCreated:
            let op = MCDownload(type: type().recordType,
                                queryField: "recordID",
                                queryValues: package.ids.map { CKReference(recordID: $0, action: .none) },
                                to: self, from: self.db)
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
    
    // MARK: - Functions: MCMirrorAbstraction
    
    /// This method subscribes to changes from the specified database, and prepares handling of events. Any changes that are detected will be reflected in recordables array.
    /// Implementation for this method should not be overwritten.
    public func subscribeToChanges(on db: MCDatabase) {
        let recordType = type().recordType
        subscription = MCSubscriber(forRecordType: recordType, on: db)
        subscription.start()
        
        // This turns on listeners for local notifications that respond to remote notifications.
        listenForDatabaseChanges()
    }
    
    /**
     This method unsubscribes from previous subscription.
     Implementation for this method should not be overwritten.
     */
    public func unsubscribeToChanges() { subscription.end() }
    
    /// This method empties recordables, and refills it from the specified database.
    /// Implementation for this method should not be overwritten.
    /// - Parameter from: An argument representing the database that receiver receives recordables from.
    /// - Parameter completion: If not nil, a closure that will be executed upon completion (no passed args).
    public func downloadAll(from db: MCDatabase, completion: OptionalClosure = nil) {
        let empty = type()
        
        // This operation will sync database records to recordables array, then runs completion.
        let op = MCDownload(type: empty.recordType, to: self, from: db)
        op.completionBlock = {
            if let block = completion { block() }
        }
        
        // empties recordables, then downloads from database.
        silentRecordables = []
        OperationQueue().addOperation(op)
        op.waitUntilFinished()
    }
}
