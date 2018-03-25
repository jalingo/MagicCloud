//
//  GetUserRecord.swift
//  MagicCloud
//
//  Created by James Lingo on 11/18/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit
import UIKit

// MARK: - Class

/// This struct contains a static var (singleton) which accesses USER's iCloud CKRecordID.
public class MCUserRecord: UserRecordRetriever, MCAccountAuthenticationVerifier {
    
    // MARK: - Properties
    
    /// This read-only, computed property should be called async from main thread because it calls to remote database before returning value. If successful returns the User's CloudKit CKRecordID, otherwise returns nil.
    public var singleton: CKRecordID? {
        group.enter()

        retrieveUserRecord()
        
        group.wait()
        return id
    }
    
    // MARK: - Properties: UserRecordRetriever
    
    /// This property is used to hold singleton delivery until recordID is fetched.
    let group = DispatchGroup()
    
    // MARK: - Properties: UserRecordErrorHandler
    
    /// This optional property stores USER recordID after it is recovered.
    var id: CKRecordID?
    
    // MARK: - Functions
    
    // This makes initializer public.
    /// This struct contains a static var (singleton) which accesses USER's iCloud CKRecordID.
    public init() { }
}
