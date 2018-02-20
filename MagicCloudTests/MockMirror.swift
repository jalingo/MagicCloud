//
//  MockMirror.swift
//  MagicCloudTests
//
//  Created by James Lingo on 2/15/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

class MockReceiver: MCMirrorAbstraction {
    
    let db: MCDatabase = .publicDB
    
    let name = "MockReceiver"
    
    typealias type = MockRecordable
    
    var subscription = MCSubscriber(forRecordType: type().recordType)
    
    let serialQ = DispatchQueue(label: "MockRec Q")
    
    /**
     * This protected property is an array of recordables used by reciever.
     */
    var silentRecordables = [type]() {
        didSet {
            print("** newRecordable = \(String(describing: silentRecordables.last?.recordID.recordName))")
            print("** recordables didSet = \(silentRecordables.count)")
            
            NotificationCenter.default.post(name: changeNotification, object: nil)
        }
    }
    
    let reachability = Reachability()!
    
    func listenForConnectivityChangesOnPublic() {
        
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
            self.downloadAll(from: .publicDB)
        }
    }
    
    @objc func reachabilityChanged(_ note: Notification) {
        
        let reachability = note.object as! Reachability
        
        switch reachability.connection {
        case .none: print("Network not reachable")
        default: downloadAll(from: .publicDB)
        }
    }
    
    deinit {
        unsubscribeToChanges()
        
        let pause = Pause(seconds: 3)
        OperationQueue().addOperation(pause)
        pause.waitUntilFinished()
        
        print("** deinit MockReceiver complete")
    }
}
