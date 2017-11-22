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
    func subscribeToChanges(for: String, on: DatabaseType, consequence: OptionalClosure)
    
    func unsubscribeToChanges(from: DatabaseType)
    
    /// This method sets trigger to download of all type associated recordables after local notification.
    func listenForDatabaseChanges()
    
    func download(from: DatabaseType, completion: OptionalClosure)
}

extension ReceivesRecordable {
    
    // MARK: - Properties
    
    var databaseChanged: NotifyBlock {
        return { notification in
            guard let object = notification.object as? MCNotification else { return }
            
            switch object {
            case .changeAt(let db): self.download(from: db)
            default: print("** ignoring notification")
            }
        }
    }
    
    // MARK: - Functions
    
    // !! Automatically triggers download when heard
    func subscribeToChanges(for type: String, on db: DatabaseType, consequence: OptionalClosure = nil) {
print("** start listening")
        let triggers: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        subscription.start(for: type, change: triggers, at: db)
        
        listenForDatabaseChanges()
    }
    
    // !!
    func unsubscribeToChanges(from type: DatabaseType) { subscription.end(at: type) }
    
    // !!
    func listenForDatabaseChanges() {
        let name = Notification.Name(MCNotification.changeNotice.toString())
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: databaseChanged)
    }
    
    // !!
    func download(from db: DatabaseType, completion: OptionalClosure = nil) {
        let empty = type()
print("** downloading")
        let op = Download(type: empty.recordType, to: self, from: db)
        op.completionBlock = {
print("** download concluding...")
            if let block = completion { block() }
        }
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
