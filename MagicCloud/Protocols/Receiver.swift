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
    
    // Need to grab / make tests from SBA
    
    // these specified by receiver type
    var notifyCreated: String { get }
    
    var notifyUpdated: String { get }
    
    var notifyDeleted: String { get }
    
    // these are used by listeners. Required in conforming instance as storage, but should not be intefered
    var createdID: String? { get set }
    
    var updatedID: String? { get set }
    
    var deletedID: String? { get set }
    
    func startListening(on: DatabaseType, consequence: OptionalClosure)
    
    func stopListening(on: DatabaseType, completion: OptionalClosure)
    
    func download(from: DatabaseType, completion: OptionalClosure)
}

extension ReceivesRecordable {
    
    var notifyCreated: String {
        let empty = type()
        return "\(empty.recordType) created"
    }

    var notifyUpdated: String {
        let empty = type()
        return "\(empty.recordType) updated"
    }

    var notifyDeleted: String {
        let empty = type()
        return "\(empty.recordType) deleted"
    }
    
    // !! Automatically triggers download when heard
    func startListening(on type: DatabaseType, consequence: OptionalClosure = nil) {
        createdID = setupListener(for: notifyCreated, change: .firesOnRecordCreation, at: type) {
            self.download(from: type, completion: consequence)
        }
        
        deletedID = setupListener(for: notifyDeleted, change: .firesOnRecordDeletion, at: type) {
            self.download(from: type, completion: consequence)
        }
        
        updatedID = setupListener(for: notifyUpdated, change: .firesOnRecordUpdate, at: type) {
            self.download(from: type, completion: consequence)
        }
    }
    
    // !!
    func stopListening(on type: DatabaseType, completion: OptionalClosure = nil) { // <-- Remove completion??
        if let str = createdID { disableListener(subscriptionID: str, at: type) }
        if let str = deletedID { disableListener(subscriptionID: str, at: type) }
        if let str = updatedID { disableListener(subscriptionID: str, at: type) }
    }
    
    func download(from db: DatabaseType, completion: OptionalClosure = nil) {
        let empty = type()
        let op = Download(type: empty.recordType, to: self, from: db)
        op.completionBlock = completion
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
