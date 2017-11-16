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
     * This boolean property allows / prevents changes to `recordables` being reflected in
     * the cloud.
     */
    var allowRecordablesDidSetToUploadDataModel: Bool { get set }
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var recordables: [type] { get set }
}

/// Wrapper class for ReceivesRecordable
class AnyReceiver<T: Recordable, R: ReceivesRecordable> {
    
    var receiver: R
    
    var allowComponentsDidSetToUploadDataModel: Bool {
        get { return receiver.allowRecordablesDidSetToUploadDataModel }
        set { receiver.allowRecordablesDidSetToUploadDataModel = newValue }
    }
    
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
