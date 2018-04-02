//
//  SpecialCompleter.swift
//  MagicCloud
//
//  Created by James Lingo on 3/24/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import Foundation

/// Types conforming to this protocol can call the `specialCompletion:containing` method which returns a completion block that executes injected closure after performing special follow up procedures.
protocol SpecialCompleter {
    
    /// This method returns a completion block that will launch the injected block after performing follow up procedures.
    func specialCompletion(containing: OptionalClosure) -> OptionalClosure
}
