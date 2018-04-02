//
//  ConsoleErrorPrinter.swift
//  MagicCloud
//
//  Created by James Lingo on 3/26/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit

/// Types conforming to this instance can call the `printAbout:error:from:to:with` method that prints a description of the error situation to the console.
protocol ConsoleErrorPrinter { }

extension ConsoleErrorPrinter {
    
    /// This void method prints a description of the error situation to the console.
    ///
    /// - Parameters:
    ///     - error: The cloud error that needs to be resolved.
    ///     - originatingOp: The operation that generated the error, and (if needed) this operation will be copied and relaunched.
    ///     - database: This argument enumerates the scope of the database being interacted with when error was thrown.
    ///     - recordables: This array contains the recordables that were being manipulated when the error occured. Use an empty array if fetching or querying when operation failed.
    func printAbout(_ error: CKError, from originatingOp: Operation, to database: MCDatabase, with recordables: [MCRecordable]) {
        print("""
            
             !E- ERROR: \(error.code) \(error.localizedDescription) \(error)
             !E-  for \(String(describing: originatingOp.name))
             !E-  w/recordables: \(recordables.map({$0.recordID}))
             !E-  on: \(database)
            
            """)
    }
}
