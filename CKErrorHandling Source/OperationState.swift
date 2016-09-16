//
//  OperationState.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/15/16.
//
//

import Foundation

// MARK: - Enum: OperationState

/// This integer enumeration is used to manage the various states of an operation.
enum OperationState: Int {

    // MARK: - Cases
    
    /// An operation's initial state.
    case initialized = 0
    /// An operation is ready to begin evaluating conditions.
    case pending
    /// An operation is evaluating conditions.
    case checkingConditions
    /// An operation has passed condition checks and is ready to execute.
    case ready
    /// An operation is carrying out it's primary task.
    case executing
    /// An operation has finished primary task, and is ready to notify queue.
    case concluding
    /// Operation has concluded all activity.
    case finished
    
    // MARK: - Functions

    /// This function reports whether `to` argument is just after `from` argument in operation sequence.
    func eligibleToTransition(to: OperationState) -> Bool {
        var answer = false
        self.rawValue == to.rawValue + 1 ? (answer = true) : (answer = false)
        return answer
    }
}

// MARK: - Extension: OperationState

extension OperationState: Comparable { }

func ==(left: OperationState, right: OperationState) -> Bool {
    return left.rawValue == right.rawValue
}

func <(left: OperationState, right: OperationState) -> Bool {
    return left.rawValue < right.rawValue
}
