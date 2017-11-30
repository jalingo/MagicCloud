//
//  ViewController.swift
//  TestApp
//
//  Created by James Lingo on 11/15/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import UIKit
import MagicCloud

// MARK: Class: ViewController

class ViewController: UIViewController, ReceivesRecordable {
    
    // MARK: - Properties

    /// This property saves EXPECTED subscription state.
    var isSubscribed = true
    
    /// This array stores data recovered from the cloud and is kept synced (while subscription is active).
    /// Can be used as a data model directly, but for increased stability consider saving locally.
    var recordables = [MockRecordable]() {
        didSet {
            DispatchQueue.main.async { self.countDisplay.text = "\(self.recordables.count)" }
        }
    }
    
    /// This property stores the subscriptionID used by the receiver and should not be modified.
    var subscription = Subscriber()

    // MARK: - Properties: IBOutlets
    
    @IBOutlet weak var countDisplay: UILabel!
    
    // MARK: - Functions
    
    // MARK: - Functions: IBActions

    @IBAction func newMockTapped(_ sender: UIButton) {
        let mock = MockRecordable()

        // This operation will save an instance conforming to recordable as a record in the specified cloud database.
        let op = Upload([mock], from: self, to: .publicDB)
        op.start()

        // The Upload operation will not effect local cache; recordables will need to be appended separately.
        recordables.append(mock)
    }
    
    @IBAction func subscribeTapped(_ sender: UIButton) {
        
        isSubscribed ?
        
        // This method unsubscribes from changes to the specified database.
        unsubscribeToChanges(from: .publicDB)
        
        :   // else...
            
        // This method subscribes to changes from the specified database, and prepares handling of events.
        subscribeToChanges(on: .publicDB)
        
        isSubscribed = !isSubscribed

        // Label title is changed based on the assumption of successful change to subscription.
        // Title change does not indicate success, but does report expected state.
        isSubscribed ?
            (sender.titleLabel?.text = "Unsubscribe") : (sender.titleLabel?.text = "Sunscribe")
    }
    
    // MARK: - Functions: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This method empties recordables, and refills it from the specified database.
        downloadAll(from: .publicDB)
        
        // This method subscribes to changes from the specified database, and prepares handling of events.
        subscribeToChanges(on: .publicDB)
    }
}
