//
//  FatalErrorOperation.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/20/16.
//
//

import Foundation
import CloudKit

/**
 * In general, Fatal cloud errors have no resolution (i.e. the system can take no action to correct
 * the error, as it would for a retriable error or a version conflict). With no resolution possible,
 * this operation simply notifies the USER with an alert message containing a localized description
 * of the error.
 */
class FatalErrorOperation: Operation {
    
    var error: CKError?
    
    override func main() {
        if isCancelled { return }
        
        let title = "Error Message"
        
        if let msg = error?.localizedDescription {
            let alert = AlertOperation(title: title, message: msg, context: nil, action: nil)
        
            if isCancelled { return }
            
            let queue = OperationQueue()
            queue.addOperation(alert)
        }
    }
    
    init(error: CKError) {
        self.error = error
        super.init()
    }
    
    // This init without dependencies has been overridden to make it private and inaccessible.
    fileprivate override init() { }
}
