//
//  ErrorQueue.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/21/16.
//
//

import Foundation

class ErrorQueue: OperationQueue {
    
    override var name: String? {
        get { return "ErrorQueue" }
        set { }     // <-- For our purposes, `name` is (essentially) read-only now.
    }
}
