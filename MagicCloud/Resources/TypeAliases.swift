//
//  TypeDefs.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/16/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

// MARK: - Closures

typealias OptionalClosure = (()->())?

// MARK: - Cloud Closures

typealias QueryBlock = (CKQueryCursor?, Error?) -> Void

typealias FetchBlock = (CKRecord) -> Void

typealias ModifyBlock = ([CKRecord]?, [CKRecordID]?, Error?) -> Void

typealias NotifyBlock = (Notification) -> Void
