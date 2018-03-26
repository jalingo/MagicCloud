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
    
    /// !!
    func decorate() -> Operation {
        let op = CKQueryOperation(query: query)
        op.name = self.name
        setupQuerier(op)

        return op
    }
}

// MARK: - Extension: SpecialCompleter

extension MCDownload: SpecialCompleter {
    
    /// !!
    func specialCompletion(containing: OptionalClosure) -> OptionalClosure {
        // No additional follow up is required...
        return containing }
}
