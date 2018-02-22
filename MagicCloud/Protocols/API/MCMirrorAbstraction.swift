//
//  MCMirror.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit
import Foundation

// MARK: Protocol

/**
    This protocol enables conforming types to give access to an array of Recordable, and to match array's contents to the cloud.
 */
public protocol MCMirrorAbstraction: AnyObject, MCArrayComparer {
    
    // MARK: - Properties

    /// Receivers can only work with one type (for error handling).
    associatedtype type: MCRecordable

    /// This read-only, computed property returns unique string identifier for the receiver.
    var name: String { get }

    /// This read-only, computed property returns the Notificaion.Name that will be posted anytime silentRecordables is updated. This notification does not trigger any activity internal to Magic Cloud, but allows apps implementing the framework to know when receivers have been updated, both from the cloud and locally.
    var changeNotification: Notification.Name { get }

    /// This read-only, computed property returns a serial dispatch queue for local changes to recordables.
    var serialQ: DispatchQueue { get }
    
    /// This read-only property stores the cloud database being mirrored.
    var db: MCDatabase { get }
    
    /// Changes made to this array will NOT be reflected to the cloud and NOT broadcast to other local receivers. Can still be observed using `changeNotification` property.
    var silentRecordables: [type] { get set }
    
    /// Changes made to this array will NOT be reflected to the cloud and WILL broadcast to other local receivers.
    var localRecordables: [type] { get set }
    
    /// Changes made to this array WILL be reflected to the cloud and WILL broadcast to other local receivers.
    var cloudRecordables: [type] { get set }
    
    /// This property stores the CKQuerySubscription used by the receiver and should not be modified.
    var subscription: MCSubscriber { get set }

    // MARK: - Functions
    
    /**
        This method subscribes to changes from the specified database, and prepares handling of events. Any changes that are detected will be reflected in recordables array.
     
        Implementation for this method should not be overwritten.
     
        - Parameter on: An argument representing the database that receiver receives recordables from.
     */
    func subscribeToChanges(on: MCDatabase)
    
    /**
        This method unsubscribes from previous subscription. Implementation for this method should not be overwritten.
     */
    func unsubscribeToChanges()
    
    /// This method empties recordables, and refills it from the specified database.
    /// Implementation for this method should not be overwritten.
    /// - Parameter from: An argument representing the database that receiver receives recordables from.
    /// - Parameter completion: If not nil, a closure that will be executed upon completion (no passed args).
    func downloadAll(from: MCDatabase, completion: OptionalClosure)
}

// MARK: - Class

/// This open (can be sub-classed) class serves as the primary concrete adopter of MCReceiverAbstraction. Gives access to an array of Recordable, and keeps that array matching database records.
open class MCMirror<T: MCRecordable>: MCMirrorAbstraction {

    // MARK: - Properties

    /// This read-only, constant property stores database records will be received from.
    public let db: MCDatabase
    
    /// This read-only, constant stores Reachability class for detecting network connection changes.
    let reachability = Reachability()!

    // MARK: - Properties: MCReceiverAbstraction
    
    /// This read-only, computed property returns unique string identifier for the receiver.
    public let name = "MCR<\(type.self)> \(Date().timeIntervalSince1970)"
    
    /// Receivers can only work with one type (for error handling).
    public typealias type = T

    /// This read-only, computed property returns a serial dispatch queue for local changes to recordables.
    public var serialQ = DispatchQueue(label: "Receiver Q")

    /// Changes made to this array will NOT be reflected to the cloud and NOT broadcast to other local receivers. Can still be observed using `changeNotification` property.
    public var silentRecordables: [type] = [type]() {
        didSet { NotificationCenter.default.post(name: changeNotification, object: nil) }
    }
    
    /// This property stores the CKQuerySubscription used by the receiver and should not be modified.
    public var subscription: MCSubscriber
    
    // MARK: - Functions

    /// This void method setups notification observers to listen for changes to both network connectivity (wifi, cell, none) and iCloud Account authentication.
    func listenForConnectivityChanges() {
        
        // This listens for changes in the network (wifi -> wireless -> none)
        NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: nil, queue: nil) { _ in
print(" heard")
        }
        
        // This is required for reachability configuration...
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("EE: could not start reachability notifier")
        }
        
        // This listens for changes in iCloud account (logged in / out)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.CKAccountChanged, object: nil, queue: nil) { note in
print(" heard again")
            MCUserRecord.verifyAccountAuthentication()
            self.downloadAll(from: self.db)
        }
    }
    
    /// This void method handles network changes based on new status.
    /// - Parameter note: The notification that reported network connection change.
    @objc func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        
        switch reachability.connection {
        case .none: print("Network not reachable")
        default: downloadAll(from: db)
        }
    }
    
    /**
        This open (can be sub-classed) class serves as the primary concrete adopter of MCReceiverAbstraction. Gives access to an array of Recordable, and keeps that array matching database records.
     
        - Parameter db: An argument representing the database that receiver receives recordables from.
     */
    public init(db: MCDatabase) {
        self.db = db
        subscription = MCSubscriber(forRecordType: type().recordType, on: db)

        listenForConnectivityChanges()

        let g = DispatchGroup()
        g.enter()
        downloadAll(from: db) { g.leave() }

        g.wait()
        subscribeToChanges(on: db)
    }
    
    /// This deconstructor unregisters subscriptions from database.
    deinit { unsubscribeToChanges() }
}

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
print("     CLOUD SET @ \(self.name) | \(results)")
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
print("     LOCAL SET @ \(self.name) | \(results)")
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
print("   responding \(package.originatingRec) -> \(self.name) | \(package.ids.count)")
        // This guards against notifications resulting from internal changes.
        guard package.originatingRec != self.name && package.ids.count != 0 else { return }
print("   passed \(package.reason.rawValue)")
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
