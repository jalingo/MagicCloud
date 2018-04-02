//
//  MCRecordableReceiver.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol MCRecordableReceiver: MCDatabaseOperation {
    
    /// This association refers to the type of `MCRecordable` that operation is manipulating in the cloud database.
    associatedtype R: MCMirrorAbstraction
    
    /// This is the MCMirror that contains the recordables that are being uploaded to database.
    var receiver: R { get }
}
