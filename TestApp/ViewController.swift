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

class ViewController: UIViewController, MCReceiverAbstraction {
    
    // MARK: - Properties
    
    let name = "TestApp VC"
    
    let serialQ = DispatchQueue(label: "VC Q")

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
    var subscription = MCSubscriber(forRecordType: type().recordType, on: .publicDB) 

    // MARK: - Properties: IBOutlets
    
    @IBOutlet weak var countDisplay: UILabel!
    
    // MARK: - Functions
    
    deinit { unsubscribeToChanges() }
    
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
        unsubscribeToChanges()
        
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
