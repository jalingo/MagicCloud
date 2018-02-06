//
//  Receiver.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit
import Foundation

/**
    This protocol enables conforming types to give access to an array of Recordable, and to prevent / allow that array's didSet to upload said array's changes to the cloud.
 */
public protocol MCReceiverAbstraction: AnyObject { // <-- Do we still need AnyObject? !!
    
    //!!
    var name: String { get }
    
    var serialQ: DispatchQueue { get }
    
    /// Receivers can only work with one type (for error handling).
    associatedtype type: MCRecordable
    
    /// This protected property is an array of recordables used by reciever.
    var recordables: [type] { get set }
    
    /// This property stores the CKQuerySubscription used by the receiver and should not be modified.
    var subscription: MCSubscriber { get set }
    
    /**
        This method subscribes to changes from the specified database, and prepares handling of events. Any changes that are detected will be reflected in recordables array.
     
        Implementation for this method should not be overwritten.
     */
    func subscribeToChanges(on: MCDatabase)
    
    /**
        This method unsubscribes from previous subscription. Implementation for this method should not be overwritten.
     */
    func unsubscribeToChanges()
    
    /// This method empties recordables, and refills it from the specified database.
    /// Implementation for this method should not be overwritten.
    func downloadAll(from: MCDatabase, completion: OptionalClosure)
}

// MARK: - Extensions

public extension MCReceiverAbstraction {
    
    // MARK: - Properties
    
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
                
                let change = LocalChangePackage(id: id, reason: trigger, originatingRec: "unknown", db: db)
                self.respondTo(change)
            }
        }
    }
    
    // MARK: - Functions
    
    /**
        This method responds to the various types of changes to the specified database.
     
        In the event of a record deletion, associated recordable is removed from recordables. If a record is updated, the local copy is removed from recordables and replaced by a fresh download. If a record is created, a new recordable is made from a downloaded record.
    
        - Parameters:
            - trigger: The type of change reported by the database.
            - id: The id for the record that was changed.
            - db: The database that was changed.
     */
    fileprivate func respondTo(_ package: LocalChangePackage) {

        // This guards against notifications resulting from internal changes.
        guard package.originatingRec != self.name else { return }
        
        switch package.reason {
        case .recordDeleted:
            serialQ.sync {
                if let index = recordables.index(where: { $0.recordID.isEqual(package.id) }) { recordables.remove(at: index) }
            }
        case .recordUpdated:
            serialQ.sync {
                if let index = recordables.index(where: { $0.recordID.recordName == package.id.recordName }) {
                    self.recordables.remove(at: index)
                    
                    let op = MCDownload(type: type().recordType,
                                        queryField: "recordID",
                                        queryValues: [CKReference(recordID: package.id, action: .none)],
                                        to: self, from: package.db)
                    OperationQueue().addOperation(op)
                }
            }
        case .recordCreated:
            let op = MCDownload(type: type().recordType,
                                queryField: "recordID",
                                queryValues: [CKReference(recordID: package.id, action: .none)],
                                to: self, from: package.db)
            OperationQueue().addOperation(op)
        }
    }
    
    /// This method is triggered by the remote notification subscribeToChanges(on:) setup.
    func listenForDatabaseChanges() {
        NotificationCenter.default.addObserver(forName: Notification.Name(type().recordType),
                                               object: nil,
                                               queue: nil,
                                               using: databaseChanged)
    }
    
    // MARK: - Functions: ReceivesRecordable
    
    /**
        This method subscribes to changes from the specified database, and prepares handling of events. Any changes that are detected will be reflected in recordables array.
     */
    public func subscribeToChanges(on db: MCDatabase) {
        let recordType = type().recordType
        subscription = MCSubscriber(forRecordType: recordType, on: db)
        subscription.start()
        
        // This turns on listeners for local notifications that respond to remote notifications.
        listenForDatabaseChanges()
    }
    
    /// This method unsubscribes from changes to the specified database.
    public func unsubscribeToChanges() { subscription.end() }
    
    /**
        This method empties recordables, and refills it from the specified database.
        Implementation for this method should not be overwritten.
     */
    public func downloadAll(from db: MCDatabase, completion: OptionalClosure = nil) {
        let empty = type()
print("                                         MCReceiver.downloadAll \(self.name)")
        // This operation will sync database records to recordables array, then runs completion.
        let op = MCDownload(type: empty.recordType, to: self, from: db)
        op.completionBlock = {
print("                                         downloadAll complete  \(self.name)")
            if let block = completion { block() }
        }

        // empties recordables, then downloads from database.
        recordables = []
        OperationQueue().addOperation(op)
        op.waitUntilFinished()
    }
}

// MARK: - Class

open class MCReceiver<T: MCRecordable>: MCReceiverAbstraction {

    // !! For testing purposes...
    public let name = "MCR<\(T.self)> created \(Date())"
    
    // !! needs comments
    
    public typealias type = T

    public var serialQ = DispatchQueue(label: "Receiver Q")
    
    public var recordables: [T] = [T]()
    
    public var subscription: MCSubscriber
    
    let db: MCDatabase
    
    let reachability = Reachability()!
    
    func listenForConnectivityChanges() {
print(#function)
        // This listens for changes in the network (wifi -> wireless -> none)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("EE: could not start reachability notifier")
        }
        
        // This listens for changes in iCloud account (login / out)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.CKAccountChanged, object: nil, queue: nil) { note in
            
            MCUserRecord.verifyAccountAuthentication()
            self.downloadAll(from: self.db)
        }
    }
    
    @objc func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        
        switch reachability.connection {
        case .none: print("Network not reachable")
        default: downloadAll(from: db)
        }
    }
    
    public init(db: MCDatabase) {
        self.db = db

        subscription = MCSubscriber(forRecordType: T().recordType, on: db)
        subscribeToChanges(on: db)
        
        downloadAll(from: db)
        
        listenForConnectivityChanges()
    }
    
    deinit { unsubscribeToChanges() }
}

// !! move back to tests after console prints removed...
public class MockRecordable: MCRecordable {   // <-- remove publix (below, too) after testing remote subscriptions
    
    // MARK: - Properties
    
    fileprivate var _recordID: CKRecordID?
    
    var created = Date()
    
    // MARK: - Properties: Static Values
    
    static let key = "MockValue"
    static let mockType = "MockRecordable"
    
    // MARK: - Properties: Recordable
    
    public var recordType: String { return MockRecordable.mockType }
    
    public var recordFields: Dictionary<String, CKRecordValue> {
        get { return [MockRecordable.key: created as CKRecordValue] }
        set {
            if let date = newValue[MockRecordable.key] as? Date { created = date }
        }
    }
    
    public var recordID: CKRecordID {
        get { return _recordID ?? CKRecordID(recordName: "EmptyRecord") }
        set { _recordID = newValue }
    }
    
    // MARK: - Functions: Constructor
    
    public required init() { }
    
    init(created: Date? = nil) {
        if let date = created { self.created = date }
    }
}
