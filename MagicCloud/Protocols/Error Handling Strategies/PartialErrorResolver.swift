//
//  PartialErrorResolver.swift
//  MagicCloud
//
//  Created by James Lingo on 3/26/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types conforming to this protocol can call the `resolvePartial:error:in` method that takes partial errors (resulting from batch attempt) and isolates to the failed transactions. After isolation, they can be passed back to through the error handling system individually.
protocol PartialErrorResolver: MCCloudErrorHandler {
    
    /// This property stores a customized completion block triggered by `Unknown Item` errors.
    var ignoreUnknownItem: Bool { get set }
    
    
     /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations. Setting this property with a non-nil value sets `ignoreUnknownItem` property to true.
    var ignoreUnknownItemCustomAction: OptionalClosure { get set }
    
    /// This void method takes partial errors (resulting from batch attempt) and isolates to the failed transactions. After isolation, they can be passed back to through the error handling system individually.
    /// !!
    func resolvePartial(_ error: CKError, in operation: Operation)
}

extension PartialErrorResolver where Self: Operation & MCDatabaseModifier {
    
    /// This void method takes partial errors (resulting from batch attempt) and isolates to the failed transactions. After isolation, they can be passed back to through the error handling system individually.
    /// !!
    func resolvePartial(_ error: CKError, in operation: Operation) {
        if let dictionary = error.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
            for entry in dictionary {
                if let partialError = entry.value as? CKError {
                    if ignoreUnknownItem && partialError.code == .unknownItem { return }
                    
                    self.handle(partialError,
                                in: operation,
                                whileIgnoringUnknownItem: self.ignoreUnknownItem,
                                ignoreUnknownAction: self.ignoreUnknownItemCustomAction)
                }
            }
        }
    }
}

extension PartialErrorResolver where Self: Operation & MCDatabaseQuerier {
    
    /// This void method takes partial errors (resulting from batch attempt) and isolates to the failed transactions. After isolation, they can be passed back to through the error handling system individually.
    /// !!
    func resolvePartial(_ error: CKError, in operation: Operation) {
        if let dictionary = error.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
            for entry in dictionary {
                if let partialError = entry.value as? CKError {
                    if ignoreUnknownItem && partialError.code == .unknownItem { return }
                    self.handle(partialError, in: operation)
                }
            }
        }
    }
}
