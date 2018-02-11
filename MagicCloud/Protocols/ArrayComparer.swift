//
//  ArrayComparer.swift
//  MagicCloud
//
//  Created by James Lingo on 2/10/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: Protocol

protocol ArrayComparer {
    
    /// Each array being compared has to conform to MCRecordable
    typealias T = MCRecordable
    
    /**
        This method compares passed arguments and returns the results of the comparison with a tuple containing values that need to be modified to resolve conflicts between two arguments.

        - Parameters:
            - original: This argument represents an array before changes have been made.
            - changed: This argument represents an array after changes have been made.
     
        - Returns: Tuple whose first value (add) represents new and modified elements, and whose second value (remove) represents original elements missing from changed array.
     */
    func check(_ original: [T], against changed: [T]) -> (add: [T], remove: [T])
}

// MARK: - Extensions

extension ArrayComparer {
    func check(_ original: [T], against changed: [T]) -> (add: [T], remove: [T]) {
        let added = changed - original
        let removed = original - changed
        
        let remainder = original - removed
        let edited = remainder.filter { unedited in
            for change in changed {
                if change == unedited {
                    return !(change.recordFields == unedited.recordFields)
                }
            }
            
            return false
        }

        return (added + edited, removed)
    }
}

// MARK: - Global Functions

func -(lhs: [MCRecordable], rhs: [MCRecordable]) -> [MCRecordable] {
    return lhs.filter { left in
        return !rhs.contains { $0 == left }
    }
}

func == (lhs: [MCRecordable], rhs: [MCRecordable]) -> Bool {
    print("                 lhs = \(lhs), rhs = \(rhs)")
    guard lhs.count == rhs.count else { return false }
    print("                 passed guard, then = \((lhs - rhs).count)")
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
