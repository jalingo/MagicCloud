//
//  Receiver.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/15/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

/**
 * This protocol enables conforming types to give access to an array of Recordable, and
 * to prevent / allow that array's didSet to upload said array's changes to the cloud.
 */
public protocol ReceivesRecordable: AnyObject {
    
    /// Receivers can only work with one type (for error handling).
    associatedtype type: Recordable
    
    /**
        This protected property is an array of recordables used by reciever.
     
        It's didSet is a good place to upload changes, after guarding allowRecordablesDidSet...
     */
    var recordables: [type] { get set }
    
    var subscription: Subscriber { get }
    
    // !!
    // Calls listenForDatabaseChanges() automatically.
    func subscribeToChanges(on: DatabaseType)
    
    // !!
    func unsubscribeToChanges(from: DatabaseType)
    
    /// This method sets trigger to download of all type associated recordables after local notification.
    func listenForDatabaseChanges()
    
    func download(from: DatabaseType, completion: OptionalClosure)
}

public extension ReceivesRecordable {
    
    // MARK: - Properties
    
    fileprivate var databaseChanged: NotifyBlock {
        return { notification in
            // TODO: Switch over to object being a recordID for a specific change
            if let info = notification.userInfo {
                let notice = CKQueryNotification(fromRemoteNotificationDictionary: info)
                let trigger = notice.queryNotificationReason
                let db = DatabaseType.from(scope: notice.databaseScope)
                
                guard let id = notice.recordID as? CKRecordValue else { return }

                /*
                    !! CAUTION: System currently relies on index variable (deletion + update) and type
                                dependency (creation) to prevent notifications from recordables of the
                                wrong type completing a download.
                 
                                Should also not be possible, as receiver's 'recordables' property has a
                                type and should not be able to be appended. This may cause an error, or
                                dummy types may get loaded if type cannot be recovered from remote
                                notification (might happen with 'case .recordCreation').
                 
                                Clarify this through testing (unit tests incapable of testing remote
                                notifications; be sure to use another device).
                 */
                switch trigger {
                case .recordDeleted:
                    if let index = self.recordables.index(where: { $0.recordID.isEqual(id) }) { self.recordables.remove(at: index) }
                case .recordUpdated:
                    if let index = self.recordables.index(where: { $0.recordID.isEqual(id) }) {
                        self.recordables.remove(at: index)
                        
                        let op = Download(type: type().recordType,
                                          queryField: "recordID",
                                          queryValues: [id],
                                          to: self, from: db)
                        
                        OperationQueue().addOperation(op)
                    }
                case .recordCreated:
                    let op = Download(type: type().recordType,
                                      queryField: "recordID",
                                      queryValues: [id],
                                      to: self, from: db)
                    OperationQueue().addOperation(op)
                }
            }
            
//            guard let object = notification.object as? MCNotification else { return }
//
//            switch object {
//            case .changeNoticed(_, let db): self.download(from: db)
//            default: print("** ignoring notification")
//            }
        }
    }
    
    // MARK: - Functions
    
    // !! Automatically triggers download when heard
    public func subscribeToChanges(on db: DatabaseType) {
print("** start listening for remote notifications")
        let empty = type()
        let triggers: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        subscription.start(for: empty.recordType, change: triggers, at: db)
        
        listenForDatabaseChanges()
    }
    
    // !!
    public func unsubscribeToChanges(from type: DatabaseType) { subscription.end(at: type) }
    
    // !!
    public func listenForDatabaseChanges() {
        let empty = type()
print("** listening for local notifications")
        let publicName  = Notification.Name(MCNotification.changeNoticed(forType: empty.recordType, at: .publicDB).toString())
        let privateName = Notification.Name(MCNotification.changeNoticed(forType: empty.recordType, at: .privateDB).toString())
        let sharedName  = Notification.Name(MCNotification.changeNoticed(forType: empty.recordType, at: .sharedDB).toString())
print("** publicName = \(publicName.rawValue)")
        for name in [publicName, privateName, sharedName] { observe(for: name) }
    }

    // !!
    fileprivate func observe(for name: Notification.Name) {
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: databaseChanged)
    }
    
    // !!
    public func download(from db: DatabaseType, completion: OptionalClosure = nil) {
        let empty = type()

        let op = Download(type: empty.recordType, to: self, from: db)
        op.completionBlock = {
print("** download concluding...")
            if let block = completion { block() }
        }
print("** emptying recordables")
        recordables = []
print("** downloading")
        OperationQueue().addOperation(op)
    }
}

/// Wrapper class for ReceivesRecordable
class AnyReceiver<T: Recordable, R: ReceivesRecordable> {
    
    var receiver: R
    
    var recordables: [T] {
        get { return receiver.recordables as? [T] ?? [T]() }      // <-- Returns empty if failed
        set {
            if let recs = newValue as? [R.type] { receiver.recordables = recs }
        }
    }
    
    init(recordable: T.Type, rec: R) {
        receiver = rec
    }
}
