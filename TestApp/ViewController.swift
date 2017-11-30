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

class ViewController: UIViewController, MCReceiver {
    
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
    var subscription = MCSubscriber() {
        didSet { print("** subscriptionID: \(subscription)")}
    }

    // MARK: - Properties: IBOutlets
    
    @IBOutlet weak var countDisplay: UILabel!
    
    // MARK: - Functions
    
    // MARK: - Functions: IBActions

    @IBAction func newMockTapped(_ sender: UIButton) {
        let mock = MockRecordable()

        // This operation will save an instance conforming to recordable as a record in the specified database.
        let op = MCUpload([mock], from: self, to: .publicDB)
        op.start()

        // The Upload operation will not effect local cache; recordables needs to be appended separately.
        recordables.append(mock)
    }
    
    @IBAction func removeMockTapped(_ sender: UIButton) {

        // The Delete operation will not effect lcoal cache; recordables needs to be modified separately.
        if let mock = recordables.popLast() {
 
            // This operation will remove these instances if present in the specified database.
            let op = MCDelete([mock], of: self, from: .publicDB)
            op.start()
        }
    }
    
    @IBAction func subscribeTapped(_ sender: UIButton) {
        
        isSubscribed ?
        
        // This method unsubscribes from changes to the specified database.
        unsubscribeToChanges(from: .publicDB)
        
        :   // else...
            
        // This method subscribes to changes from the specified database, and prepares handling of events.
        subscribeToChanges(on: .publicDB)
        
        // Switches state.
        isSubscribed = !isSubscribed

        // Title change does not indicate success, but does report expected state.
        isSubscribed ?
            sender.setTitle("Unsubscribe", for: .normal) : sender.setTitle("Subscribe", for: .normal)
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
