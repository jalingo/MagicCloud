//
//  MCDownload Extensions.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Extensions

// MARK: - Extension: OperationDecorator

extension MCDownload: OperationDecorator {
    
    /// This method returns a fully configured Operation, ready to be launched.
    func decorate() -> Operation {
        let op = CKQueryOperation(query: query)
        op.name = self.name
        setupQuerier(op)

        return op
    }
}

// MARK: - Extension: SpecialCompleter

extension MCDownload: SpecialCompleter {
    
    /// This method returns a completion block that will launch the injected block after performing follow up procedures.
    /// - Parameter block: Usually the original completion block, this closure will be run after follow up procedures are executed.
    func specialCompletion(containing block: OptionalClosure) -> OptionalClosure {
        // No additional follow up is required...
        return block }
}
