//
//  ErrorHandlingQueue.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/21/16.
//
//

import Foundation

class ErrorHandlingQueue: OperationQueue {
    
    override var name: String? {
        get { return "ErrorHandlingQueue" }
        set { }     // <-- For our purposes, `name` is (essentially) read-only now.
    }
}
