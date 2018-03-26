//
//  MCUpload Extensions.swift
//  MagicCloud
//
//  Created by James Lingo on 3/24/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Extensions

// MARK: - Extension: OperationDecorator

extension MCUpload: OperationDecorator {
    
    /// This method returns a fully configured Operation, ready to be launched.
    func decorate() -> Operation {
        let op = CKModifyRecordsOperation(recordsToSave: self.records,
                                          recordIDsToDelete: nil)
        op.name = self.name
        setupModifier(op)

        return op
    }
}

// MARK: - Extension: SpecialCompleter

extension MCUpload: SpecialCompleter {
    
    /// !!
    func specialCompletion(containing block: OptionalClosure) -> OptionalClosure {
        return {
            let unchanged: [R.type] = self.receiver.localRecordables - self.recordables as! [R.type]
            self.receiver.localRecordables = unchanged + self.recordables
            block?()
        }
    }
}
