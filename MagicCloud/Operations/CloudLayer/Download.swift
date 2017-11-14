//
//  DownloadByType.swift
//  slBackend
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 Promethatech. All rights reserved.
//

import CloudKit

public class Download: Operation {
    
    // MARK: - Properties
    
    /**
     * The maximum number of records to return at one time.
     *
     * For most queries, leave the value of this property set to the default value, which is represented by the **CKQueryOperationMaximumResults** constant. When using that value, the server chooses a limit that aims to provide an optimal number of results that returns as many records as possible while minimizing delays in receiving those records. However, if you know that you want to process a fixed number of results, change the value of this property accordingly.
     */
    var limit: Int?
    
    /// Allows user to set a customized completion block for `.ignoreUnknownItem` situations.
    /// - Caution: Setting this property does not effect `ignoreUnknownItem` property.
    var ignoreUnknownItemCustomAction: OptionalClosure
    
    /// This protocol enables conforming types to give access to an array of Recordable, and to prevent / allow that array’s didSet to upload said array’s changes to the cloud.
    var reciever: ReceivesRecordable
    
    /**
     * A conduit for accessing and for performing operations on the public and private data of an app container.
     *
     * An app container has a public database whose data is accessible to all users and a private database whose data is accessible only to the current user. A database object takes requests for data and applies them to the appropriate part of the container.
     *
     * You do not create database objects yourself, nor should you subclass CKDatabase. Your app’s CKContainer objects provide the CKDatabase objects you use to access the associated data. Use database objects as-is to perform operations on data.
     *
     * The public database is always available, regardless of whether the device has an an active iCloud account. When no iCloud account is available, your app may fetch records and perform queries on the public database, but it may not save changes. (Saving records to the public database requires an active iCloud account to identify the owner of those records.) Access to the private database always requires an active iCloud account on the device.
     * - Note: Interactions with CKDatabase objects occur at a quality of service level of NSQualityOfServiceUserInitiated by default. For information about quality of service, see Prioritize Work with Quality of Service Classes in Energy Efficiency Guide for iOS Apps and Prioritize Work at the Task Level in Energy Efficiency Guide for Mac Apps.
     */
    var db: CKDatabase?
    
    /**
     * A CKQuery object manages the criteria to apply when searching for records in a database. You create a query object as the first step in the search process. The query object stores the search parameters, including the type of records to search, the match criteria (predicate) to apply, and the sort parameters to apply to the results. The second step is to use the query object to initialize a CKQueryOperation object, which you then execute to generate the results.
     *
     * Always designate a record type and predicate when you create a query object. The record type narrows the scope of the search to one type of record, and the predicate defines the conditions for which records of that type are considered a match. Predicates usually compare one or more fields of a record to constant values, but you can create predicates that return all records of a given type or perform more nuanced searches.
     *
     * Because the record type and predicate cannot be changed later, you can use the same CKQuery object to initialize multiple CKQueryOperation objects, each of which targets a different database or zone.
     */
    var query: CKQuery
    
    // MARK: - Functions
    
    fileprivate func decorate(op: CKQueryOperation, for db: CKDatabase, and type: String) {
        if let integer = limit { op.resultsLimit = integer }
        op.recordFetchedBlock = recordFetched(type: type, from: db)
        op.queryCompletionBlock = queryCompletion(op: op, database: db)
    }
    
    fileprivate func recordFetched(type: String, from db: CKDatabase) -> FetchBlock {
        return { record in
print("* \(record.recordID.recordName) fetched from: \(db)")

            let fetched = prepare(type, from: record, in: db)
            
            self.reciever.allowComponentsDidSetToUploadDataModel = false
            self.reciever.recordables.append(fetched)
        }
    }
    
    fileprivate func queryCompletion(op: CKQueryOperation, database: CKDatabase) -> QueryBlock {
        return { cursor, error in
            if let queryCursor = cursor {
                database.add(self.followUp(cursor: queryCursor, op: op))
            } else {
                guard error == nil else {
                    if let cloudError = error as? CKError {
                        print("handling error @ Download.queryCompletion")
                        let errorHandler = MCErrorHandler(error: cloudError,
                                                          originating: op,
                                                          instances: self.reciever.recordables,
                                                          target: database)
                        errorHandler.ignoreUnknownItem = true
                        errorHandler.ignoreUnknownItemCustomAction = self.ignoreUnknownItemCustomAction
                        ErrorQueue().addOperation(errorHandler)
                    } else {
                        print("NSError \(String(describing: error?.localizedDescription)) @ Download.queryCompletion")
                    }
                    
                    return
                }
            }
        }
    }
    
    fileprivate func followUp(cursor: CKQueryCursor, op: CKQueryOperation) -> CKQueryOperation {
        let newOp = CKQueryOperation(cursor: cursor)
   
        newOp.queryCompletionBlock = op.queryCompletionBlock
        newOp.recordFetchedBlock = op.recordFetchedBlock
        newOp.resultsLimit = op.resultsLimit
        
        return newOp
    }
    
    // MARK: - Functions: Operation
    
    public override func main() {
        
        if isCancelled { return }
        
        let op = CKQueryOperation(query: query)
        op.completionBlock = self.completionBlock
        self.completionBlock = nil
        
        if let database = db {
            decorate(op: op, for: database, and: query.recordType)
            op.name = "Download.any: \(database.description)"
            
            if isCancelled { return }
            database.add(op)
        } else {
            let publicDB = CKContainer.default().publicCloudDatabase
            let privateDB = CKContainer.default().privateCloudDatabase
            
            decorate(op: op, for: privateDB, and: query.recordType)
            op.name = "Download.private"

            let pubOp = CKQueryOperation(query: query)
            decorate(op: pubOp, for: publicDB, and: query.recordType)
            pubOp.completionBlock = { privateDB.add(op) }
            pubOp.name = "Download.public"
            
            if isCancelled { return }
            publicDB.add(pubOp)
        }
    }
    
    // MARK: - Functions: Constructors
    
    /**
     * This init constructs a 'Download' operation with a predicate that attempts to match a specified field's value.
     *
     * - parameter type: Every 'Download' op targets a specifc recordType and this parameter is how it's injected.
     *
     * - parameter queryField: 'K' in "%K = %@" predicate, where K represents CKRecord Field.
     *
     * - parameter queryValues: '@' in "%k = %@" predicate, where @ represents an array of possible matching CKRecordValue's.
     *
     * - parameter to: Instance conforming to 'RecievesRecordable' that will ultimately recieve the results of the query.
     *
     * - parameter from: 'CKDatabase' that will be searched for records. Leave nil to search default of both private and public.
     */
    init(type: String, queryField: String, queryValues: [CKRecordValue], to rec: ReceivesRecordable, from database: CKDatabase? = nil) {
        let predicate = NSPredicate(format: "%K IN %@", queryField, queryValues)
        query = CKQuery(recordType: type, predicate: predicate)
        
        reciever = rec
        db = database
        
        super.init()
    }
    
    /**
     * This init constructs a 'Download' operation with a predicate that attempts to collect records associated with owner.
     *
     * - parameter type: Every 'Download' op targets a specifc recordType and this parameter is how it's injected.
     *
     * - parameter ownedBy: The instance confroming to 'Recordable' that represents the ownerships aspect of the relation database.
     *
     * - parameter to: Instance conforming to 'RecievesRecordable' that will ultimately recieve the results of the query.
     *
     * - parameter from: 'CKDatabase' that will be searched for records. Leave nil to search default of both private and public.
     */
    init(type: String, ownedBy: Recordable, to rec: ReceivesRecordable, from database: CKDatabase? = nil) {
        let ref = CKReference(recordID: ownedBy.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "%K CONTAINS %@", OWNER_KEY, ref)
        query = CKQuery(recordType: type, predicate: predicate)
        
        reciever = rec
        db = database
        
        super.init()
    }
    
    /**
     * This init constructs a 'Download' operation with a predicate that collects all records of the specified type.
     *
     * - parameter type: Every 'Download' op targets a specifc recordType and this parameter is how it's injected.
     *
     * - parameter to: Instance conforming to 'RecievesRecordable' that will ultimately recieve the results of the query.
     *
     * - parameter from: 'CKDatabase' that will be searched for records. Leave nil to search default of both private and public.
     */
    init(type: String, to rec: ReceivesRecordable, from database: CKDatabase? = nil) {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        query = CKQuery(recordType: type, predicate: predicate)
        
        reciever = rec
        db = database
        
        super.init()
    }
}
