//
//  MCMirror.swift
//  MagicCloud
//
//  Created by James Lingo on 2/11/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import Foundation

protocol MCMirrorAbstraction: ArrayComparer {
    var dataModel: [MCRecordable] { get set }
}

open class MCMirror<T: MCRecordable>: MCMirrorAbstraction {
    
    let receiver: MCReceiver<T>
    
    var dataModel: [MCRecordable] {
        get { return receiver.recordables }
        
        set {
            let results = check(receiver.recordables, against: newValue)
            let q = OperationQueue()
            
            if let changes = results.add as? [T] {
                let op = MCUpload(changes, from: receiver, to: receiver.db)
                q.addOperation(op)
            }
            
            if let changes = results.remove as? [T] {
                let op = MCDelete(changes, of: receiver, from: receiver.db)
                q.addOperation(op)
            }
        }
    }
    
    public init(db: MCDatabase) {
        receiver = MCReceiver<T>(db: db)
    }
}
