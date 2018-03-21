//
//  MCMirror.swift
//  MagicCloud
//
//  Created by James Lingo on 2/22/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import Foundation
import CloudKit

// MARK: Class

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
        NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: reachability, queue: nil) { _ in

            guard self.reachability.connection != .none else { return }
            self.downloadAll(from: self.db)
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
        
        DispatchQueue(label: "Mirror.init downloadAll ##\(self.name)").async { self.downloadAll(from: self.db) }

        subscribeToChanges(on: db)
    }
    
    /// This deconstructor unregisters subscriptions from database.
    deinit { unsubscribeToChanges() }
}

