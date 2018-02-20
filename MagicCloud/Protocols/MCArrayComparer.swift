//
//  ArrayComparer.swift
//  MagicCloud
//
//  Created by James Lingo on 2/10/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Protocol

public protocol MCArrayComparer {
    
    /// Each array being compared has to conform to MCRecordable
    typealias Element = MCRecordable
    
    /**
        This method compares passed arguments and returns the results of the comparison with a tuple containing values that need to be modified to resolve conflicts between two arguments.

        - Parameters:
            - original: This argument represents an array before changes have been made.
            - changed: This argument represents an array after changes have been made.
     
        - Returns: Tuple whose value (add) represents new, (edited) modified elements and (remove) represents original elements missing from changed array.
     */
    func check(_ original: [Element], against changed: [Element]) -> (add: [Element], edited: [Element], remove: [Element])
}

// MARK: - Extensions

extension MCArrayComparer {
    public func check(_ original: [Element], against changed: [Element]) -> (add: [Element], edited: [Element], remove: [Element]) {
        let added = changed - original
        let removed = original - changed

        let remainder = original - removed
        let edited = remainder.filter { unedited in
            for change in changed {
                if change == unedited { return !(change.recordFields == unedited.recordFields) }
            }
            
            return false
        }

        return (added, edited, removed)
    }
}

// MARK: - Global Functions

func -(lhs: [MCRecordable], rhs: [MCRecordable]) -> [MCRecordable] {
    return lhs.filter { left in
        return !rhs.contains { $0 == left }
    }
}

func == (lhs: [MCRecordable], rhs: [MCRecordable]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return (lhs - rhs).count == 0
}

func ==(lhs: Dictionary<String, CKRecordValue>, rhs: Dictionary<String, CKRecordValue>) -> Bool {
    guard lhs.count == rhs.count else { return false }

    for key in lhs.keys {
        guard let left = lhs[key], let right = rhs[key] else { return false }
        guard left.description == right.description else { return false }
    }
    
    return true
}
