//
//  ReachabilityChanger.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import Foundation

@objc protocol ReachabilityChanger {
    
    /// This void method handles network changes based on new status.
    /// - Parameter note: The notification that reported network connection change.
    func reachabilityChanged(_ note: Notification)
}
