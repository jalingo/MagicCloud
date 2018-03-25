//
//  ConnectivityChangeListener.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import Foundation

protocol ConnectivityChangeListener: AnyObject {
    
    /// This read-only, constant stores Reachability class for detecting network connection changes.
    var reachability: Reachability { get }
}

extension ConnectivityChangeListener where Self: MCMirrorAbstraction & ReachabilityChanger {
    
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
}
