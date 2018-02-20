//
//  ViewController.swift
//  TestApp
//
//  Created by James Lingo on 11/15/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import UIKit
import MagicCloud
import CloudKit     // <-- Still Needed, in most cases.

// MARK: - Class: ViewController

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    // Will be nil unless manually set by uncommenting below
    var mirror: MCMirror<MockRecordable>? // = MCMirror<MockRecordable>(db: .publicDB)
    
    let serialQ = DispatchQueue(label: "VC Q")

    /// This property saves EXPECTED subscription state.
    var isSubscribed = true
    
    /// This array stores data recovered from the cloud and is kept synced (while subscription is active).
    /// Can be used as a data model directly, but for increased stability consider saving locally.
    var dataModel: [MockRecordable] {
        get { return mirror?.cloudRecordables  ?? [] }
        set {
            mirror?.cloudRecordables = newValue
            DispatchQueue.main.async { self.countDisplay.text = "\(self.dataModel.count)" }
        }
    }

    // MARK: - Properties: IBOutlets
    
    @IBOutlet weak var countDisplay: UILabel!
    
    // MARK: - Functions: IBActions

    @IBAction func newMockTapped(_ sender: UIButton) {
        let mock = MockRecordable()
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
}


// MARK: - Mock

/// Mock instance that only conforms to `Recordable` for testing and prototype development.
 class MockRecordable: MCRecordable {
    
    // MARK: - Properties
    
    var created = Date()
    
    // MARK: - Properties: Static Values
    
    static let key = "MockValue"
    static let mockType = "MockRecordable"
    
    // MARK: - Properties: Recordable
    
    var recordType: String { return MockRecordable.mockType }
    
    var recordFields: Dictionary<String, CKRecordValue> {
        get { return [MockRecordable.key: created as CKRecordValue] }
        set {
            if let date = newValue[MockRecordable.key] as? Date { created = date }
        }
    }
    
    var recordID: CKRecordID {
        get {
            return CKRecordID(recordName: "MockIdentifier: \(String(describing: created))")
        }
        
        set {
            var str = newValue.recordName
            if let range = str.range(of: "MockIdentifier: ") {
                str.removeSubrange(range)
                if let date = DateFormatter().date(from: str) { created = date }
            }
        }
    }
    
    // MARK: - Functions: Constructor
    
    public required init() { }
    
    init(created: Date? = nil) {
        if let date = created { self.created = date }
    }
}
