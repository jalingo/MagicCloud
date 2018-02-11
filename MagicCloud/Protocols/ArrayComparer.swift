//
//  ArrayComparer.swift
//  MagicCloud
//
//  Created by James Lingo on 2/10/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

protocol ArrayComparer {
    typealias T = MCRecordable
    
    func check(_ original: [T], against changed: [T]) -> (add: [T], remove: [T])
}

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
        print("                 edited = \(edited.map({ $0.recordID.recordName }))")
        return (added + edited, removed)
    }
}

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
