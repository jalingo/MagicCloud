//
//  SpecialCompleter.swift
//  MagicCloud
//
//  Created by James Lingo on 3/24/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import Foundation

/// !!
protocol SpecialCompleter {
    
    /// !!
    func specialCompletion(containing: OptionalClosure) -> OptionalClosure
}
