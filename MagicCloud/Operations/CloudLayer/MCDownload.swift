//
//  MCDownload.swift
//  MagicCloud
//
//  Created by Jimmy Lingo on 5/21/17.
//  Copyright © 2017 PromethaTech. All rights reserved.
//

import CloudKit

/**
    Downloads records from specified database, converts them back to recordables and then loads them into associated receiver. Destination is the receiver's 'recordables' property, an array of receiver's associated type, but array is NOT emptied or otherwise prepared before appending results.
 */
public class MCDownload<R: MCReceiver>: Operation {

    // MARK: - Properties
    
    /**
        The maximum number of records to return at one time.
     
        For most queries, leave the value of this property set to the default value, which is represented by the **CKQueryOperationMaximumResults** constant. When using that value, the server chooses a limit that aims to provide an optimal number of results that returns as many records as possible while minimizing delays in receiving those records. However, if you know that you want to process a fixed number of results, change the value of this property accordingly.
     */
    var limit: Int?
    
    /// This property stores a customized completion block triggered by `Unknown Item` errors.
    var unknownItemCustomAction: OptionalClosure
    
    /**
        A CKQuery object manages the criteria to apply when searching for records in a database. You create a query object as the first step in the search process. The query object stores the search parameters, including the type of records to search, the match criteria (predicate) to apply, and the sort parameters to apply to the results. The second step is to use the query object to initialize a CKQueryOperation object, which you then execute to generate the results.
     
        Always designate a record type and predicate when you create a query object. The record type narrows the scope of the search to one type of record, and the predicate defines the conditions for which records of that type are considered a match. Predicates usually compare one or more fields of a record to constant values, but you can create predicates that return all records of a given type or perform more nuanced searches.
     
        Because the record type and predicate cannot be changed later, you can use the same CKQuery object to initialize multiple CKQueryOperation objects, each of which targets a different database or zone.
     */
    var query: CKQuery
    
    /// This is the receiver that downloaded records will be sent to as instances conforming to Recordable.
    let receiver: R
    
    /**
        A conduit for accessing and for performing operations on the public and private data of an app container.
     
        An app container has a public database whose data is accessible to all users and a private database whose data is accessible only to the current user. A database object takes requests for data and applies them to the appropriate part of the container.
     
        You do not create database objects yourself, nor should you subclass CKDatabase. Your app’s CKContainer objects provide the CKDatabase objects you use to access the associated data. Use database objects as-is to perform operations on data.
     
        The public database is always available, regardless of whether the device has an an active iCloud account. When no iCloud account is available, your app may fetch records and perform queries on the public database, but it may not save changes. (Saving records to the public database requires an active iCloud account to identify the owner of those records.) Access to the private database always requires an active iCloud account on the device.
     */
    let database: MCDatabaseType
    
    // MARK: - Functions
     
    /// This method configures a CKQueryOperation with settings, appropriate completion blocks and name.
    fileprivate func decorate(op: CKQueryOperation) {
        if let integer = limit { op.resultsLimit = integer }
    
        op.recordFetchedBlock = recordFetched()
        op.queryCompletionBlock = queryCompletion(op: op)
        
        op.name = "Download @ \(database)"
    }
    
    /// This method supplies a completion block for CKQueryOperation.recordFetchedBlock.
    fileprivate func recordFetched() -> FetchBlock {
        return { record in
            let fetched = prepare(type: R.type.self, from: record)            
            if let new = fetched as? R.type { self.receiver.recordables.append(new) }
        }
    }
    
    /// This method supplies a completion block for CKQueryOperation.queryCompletionBlock.
    fileprivate func queryCompletion(op: CKQueryOperation) -> QueryBlock {
        return { cursor, error in
            if let queryCursor = cursor {
                self.database.db.add(self.followUp(cursor: queryCursor, op: op))
            } else {
                guard error == nil else {
                    if let cloudError = error as? CKError {
                        let errorHandler = MCErrorHandler(error: cloudError,
                                                          originating: op,
                                                          target: self.database, instances: [],
                                                          receiver: self.receiver)
                        errorHandler.ignoreUnknownItem = true
                        errorHandler.ignoreUnknownItemCustomAction = self.unknownItemCustomAction
                        OperationQueue().addOperation(errorHandler)
                    } else {
                        print("NSError \(String(describing: error?.localizedDescription)) @ Download.queryCompletion")
                    }
                    
                    return
                }
            }
        }
    }
    
    /// This method creates an operation that can finish an incomplete query from a CKQueryCursor.
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

        // This passes the completion block down to the end of the operation.
        op.completionBlock = self.completionBlock
        self.completionBlock = nil
        
        decorate(op: op)
        database.db.add(op)
    }
    
    // MARK: - Functions: Constructors
    
    /**
        This init constructs a 'MCDownload' operation with a predicate that attempts to match a specified field's value.
     
        - parameter type: Every 'MCDownload' op targets a specifc recordType and this parameter is how it's injected.
        - parameter queryField: 'K' in "%K = %@" predicate, where K represents CKRecord Field.
        - parameter queryValues: '@' in "%K = %@" predicate, where @ represents an array of possible matching CKRecordValue's.
        - parameter to: Instance conforming to 'RecievesRecordable' that will ultimately recieve the results of the query.
        - parameter from: 'CKDatabase' that will be searched for records. Leave nil to search default of both private and public.
     */
    public init(type: String, queryField: String, queryValues: [CKRecordValue], to rec: R, from db: MCDatabaseType) {
        let predicate = NSPredicate(format: "%K IN %@", queryField, queryValues)
        query = CKQuery(recordType: type, predicate: predicate)
        receiver = rec
        database = db
        
        super.init()
    }
    
    /**
        This init constructs a 'MCDownload' operation with a predicate that attempts to collect records associated with owner.
     
        - parameter type: Every 'MCDownload' op targets a specifc recordType and this parameter is how it's injected.
        - parameter ownedBy: The instance confroming to 'Recordable' that represents the ownerships aspect of the relation database.
        - parameter to: Instance conforming to 'RecievesRecordable' that will ultimately recieve the results of the query.
        - parameter from: 'CKDatabase' that will be searched for records. Leave nil to search default of both private and public.
     */
    public init(type: String, ownedBy: MCRecordable, to rec: R, from db: MCDatabaseType) {
        let ref = CKReference(recordID: ownedBy.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "%K CONTAINS %@", OWNER_KEY, ref)
        query = CKQuery(recordType: type, predicate: predicate)
        receiver = rec
        database = db
        
        super.init()
    }
    
    /**
        This init constructs a 'MCDownload' operation with a predicate that collects all records of the specified type.
     
        - parameter type: Every 'MCDownload' op targets a specifc recordType and this parameter is how it's injected.
        - parameter to: Instance conforming to 'RecievesRecordable' that will ultimately recieve the results of the query.
        - parameter from: 'CKDatabase' that will be searched for records. Leave nil to search default of both private and public.
     */
    public init(type: String, to rec: R, from db: MCDatabaseType) {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        query = CKQuery(recordType: type, predicate: predicate)
        receiver = rec
        database = db
        
        super.init()
    }
}
