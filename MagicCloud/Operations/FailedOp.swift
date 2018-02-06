//
//  FailedOp.swift
//  slBackend
//
//  Created by Jimmy Lingo on 6/4/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import Foundation

/// This mock operation is used for testing, but must be a part of the main build to interact with 'Duplicate'
class FailedOp: Operation {
    
    let notification: Notification
    
    override func main() {
        NotificationCenter.default.post(name: notification.name, object: nil)
    }
    
    init(notify: Notification) { notification = notify }
    
}
