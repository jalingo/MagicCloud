//
//  CloudQueue.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/15/16.
//
//

import Foundation

class CloudQueue: OperationQueue {
    
    override var name: String? {
        get { return "CloudQueue" }
        set { }     // <-- For our purposes, `name` is now read-only.
    }
}
