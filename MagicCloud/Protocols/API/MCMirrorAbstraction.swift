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
