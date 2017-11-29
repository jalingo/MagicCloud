//
//  TypeDefs.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

// MARK: - Closures

public typealias OptionalClosure = (()->())?

// MARK: - Cloud Closures

public typealias QueryBlock = (CKQueryCursor?, Error?) -> Void

public typealias FetchBlock = (CKRecord) -> Void

public typealias ModifyBlock = ([CKRecord]?, [CKRecordID]?, Error?) -> Void

public typealias NotifyBlock = (Notification) -> Void

// MARK: - OperationQueues

class ErrorQueue: OperationQueue {
    
}

class CloudQueue: OperationQueue {
    
}
