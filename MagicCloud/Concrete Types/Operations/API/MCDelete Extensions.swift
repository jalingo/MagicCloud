//
//  MCDelete Extensions.swift
//  MagicCloud
//
//  Created by James Lingo on 3/24/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Extensions

// MARK: - Extension: OperationDecorator

extension MCDelete: OperationDecorator {
    
    /// This method returns a fully configured Operation, ready to be launched.
    func decorate() -> Operation {
        let op = CKModifyRecordsOperation(recordsToSave: nil,
                                          recordIDsToDelete: recordIDs)
        op.name = self.name
        setupModifier(op)

        return op
    }
}

// MARK: - Extension: SpecialCompleter

extension MCDelete: SpecialCompleter {
    
    /// This method returns a completion block that will launch the injected block after performing follow up procedures.
    /// - Parameter block: Usually the original completion block, this closure will be run after follow up procedures are executed.
    func specialCompletion(containing block: OptionalClosure) -> OptionalClosure {
        return {
            // originating receiver will ignore notification, this manually removes...
            let newVal = self.receiver.silentRecordables.filter { silent in
                !self.recordables.contains(where: { silent.recordID.recordName == $0.recordID.recordName })
            }
            self.receiver.localRecordables = newVal
            
            block?()
        }
    }
}
