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
    
    /// This method decorates a modify operation.
    func decorate() -> Operation {
        let op = CKModifyRecordsOperation(recordsToSave: nil,
                                          recordIDsToDelete: recordIDs)
        op.name = self.name
        uniformSetup(op)
        
        return op
    }
}

// MARK: - Extension: SpecialCompleter

extension MCDelete: SpecialCompleter {
    
    /// !!
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
