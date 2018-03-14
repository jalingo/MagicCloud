//
//  ViewController.swift
//  TestApp
//
//  Created by James Lingo on 11/15/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import UIKit
import MagicCloud

// MARK: - Class: ViewController

class ViewController: UIViewController {
    
    // MARK: - Properties

    // Will be nil unless manually set by uncommenting below (left this way for unit testing).
    var mirror: MCMirror<MockRecordable>? // = MCMirror<MockRecordable>(db: .privateDB)
//let alt = MCMirror<MockRecordable>(db: .privateDB)
    let serialQ = DispatchQueue(label: "VC Q")

    /// This property saves EXPECTED subscription state.
    var isSubscribed = true
    
    /// This array stores data recovered from the cloud and is kept synced (while subscription is active).
    /// Can be used as a data model directly, but for increased stability consider saving locally.
    var dataModel: [MockRecordable] {
        get { return mirror?.cloudRecordables ?? [] }
        set { mirror?.cloudRecordables = newValue }
    }

    // MARK: - Properties: IBOutlets
    
    @IBOutlet weak var countDisplay: UILabel!
    
    // MARK: - Functions: IBActions

    @IBAction func newMockTapped(_ sender: UIButton) {
        let mock = MockRecordable(created: Date())
        dataModel.append(mock)
    }
    
    @IBAction func removeMockTapped(_ sender: UIButton) {
        if dataModel.count != 0 { dataModel.removeLast() }
    }
    
    @IBAction func subscribeTapped(_ sender: UIButton) {
        
        isSubscribed ?
        
        // This method unsubscribes from changes to the specified database.
        mirror?.unsubscribeToChanges()
        
        :   // else...
            
        // This method subscribes to changes from the specified database, and prepares handling of events.
        mirror?.subscribeToChanges(on: mirror!.db)
        
        // Switches state.
        isSubscribed = !isSubscribed

        // Title change does not indicate success, but does report expected state.
        isSubscribed ?
            sender.setTitle("Unsubscribe", for: .normal) : sender.setTitle("Subscribe", for: .normal)
    }
    
    // MARK: - Functions: UIViewController
    
    override func viewDidLoad() {
        if let name = mirror?.changeNotification {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { _ in
                DispatchQueue.main.async { self.countDisplay.text = "\(self.dataModel.count)" }
            }
//NotificationCenter.default.addObserver(forName: alt.changeNotification, object: nil, queue: nil) { _ in
//print("                                          DING DING DING DING DING \(self.alt.silentRecordables.count) \(self.alt.name)") }
        }
    }
}

