//
//  CloudOps.swift
//  Voyage
//
//  Created by Jimmy Lingo on 9/1/16.
//  Copyright © 2016 lingoTECH Solutions. All rights reserved.
//

import CloudKit

/**
 *
 */
struct CloudOps {
    
    // MARK: - Properties

    /// This property contains the database (public / private) strategies will interact with.
    var database: CKDatabase
    
    // MARK: - Functions
    
    /**
     * This method is a basic upload operation for instances conforming to the 'Recordable' protocol. Multiple handlers
     * allow for implementation to be responsive to each operation as well as the batch as a whole.
     *
     * - WARNING: If unique error handling is required, do not use this method. Complex or synchronous uploads should 
     * be implemented separately.
     *
     * - parameter recordablesToUpdate: An array of a single type, conforming to 'Recordable' protocol that will be 
     * uploaded to database.
     *
     * - parameter successHandler: An optional closure that will execute each time a record is successfully uploaded.
     *
     * - parameter failureHandler: An optional closure that will execute each time a record in the batch fails.
     *
     * - parameter completionHandler: An optional closure that will execute at the end of the entire batch completes.
     */
    func uploadRecordables<T: Recordable>(recordablesToUpdate: [T], successHandler: OptionalClosure, failureHandler: OptionalClosure, completionHandler: OptionalClosure = nil) {
        
        let records = recordablesToUpdate.map() { $0.record }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        operation.perRecordCompletionBlock = { record, error in
        
            // Error Handling
            guard error == nil else {
                
                // Recover the specific recordable object effected (for error handler)
                var currentRecordable: T?
                for recordable in recordablesToUpdate {
                    if recordable.recordID == record?.recordID { currentRecordable = recordable }
                }
                
                // This should occur in any situation where record is not nil, otherwise error is '.unknownItem' needs no handling.
                if let recordableToUpdate = currentRecordable {
                    
                    // Prepare for selector in the event of a retry.
                    let executableBlock = {
                        self.uploadRecordables(recordablesToUpdate: [recordableToUpdate],
                                               successHandler: successHandler,
                                               failureHandler: failureHandler,
                                               completionHandler: completionHandler)
                    }
                    
                    // Generic error handling
                    let errorHandler = CloudErrorStrategies(originatingMethodInAnEnclosure: executableBlock,
                                                            database: self.database)
                    errorHandler.handle(error!,
                                        recordableObject: recordableToUpdate,
                                        failureHandler: failureHandler,
                                        successHandler: successHandler)
                }
                
                return
            }
            
            // After saving without error, executes successHandler each time...
            if let handler = successHandler { handler() }
        }
        
        operation.completionBlock = completionHandler
     
        let queue = OperationQueue()
        queue.addOperation(operation)
        queue.sync {
            print("upload operation completed.")
        }
    }
    
    /**
     * This method is a basic remove operation for instances conforming to the 'Recordable' protocol. Multiple handlers
     * allow for implementation to be responsive to each transaction, as well as the batch as a whole.
     *
     * - WARNING: If unique error handling is required, do not use this method. Complex or synchronous uploads should
     * be implemented separately.
     *
     * - parameter recordablesToDelete: An array of a single type, conforming to 'Recordable' protocol that will be
     * removed from database.
     *
     * - parameter successHandler: An optional closure that will execute each time a record is successfully deleted.
     *
     * - parameter failureHandler: An optional closure that will execute each time a record in the batch fails.
     *
     * - parameter completionHandler: An optional closure that will execute at the end of the entire batch completes.
     */
    func removeRecordables<T: Recordable>(recordablesToDelete: [T], successHandler: OptionalClosure, failureHandler: OptionalClosure, completionHandler: OptionalClosure = nil) {
        
        let records = recordablesToDelete.map() { $0.recordID }
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: records)

        operation.perRecordCompletionBlock = { record, error in
            
            // Error Handling
            guard error == nil else {
                
                // Recover the specific recordable object effected (for error handler)
                var currentRecordable: T?
                for recordable in recordablesToDelete {
                    if recordable.recordID == record?.recordID { currentRecordable = recordable }
                }
                
                // This should occur in any situation where record is not nil, otherwise error is '.unknownItem' and 
                // needs no handling.
                if let recordableToRemove = currentRecordable {
                    
                    // Prepare for selector in the event of a retry.
                    let executableBlock = {
                        self.uploadRecordables(recordablesToUpdate: [recordableToRemove],
                                               successHandler: successHandler,
                                               failureHandler: failureHandler,
                                               completionHandler: completionHandler)
                    }
                    
                    // Generic error handling
                    let errorHandler = CloudErrorStrategies(originatingMethodInAnEnclosure: executableBlock,
                                                            database: self.database)
                    errorHandler.handle(error!,
                                        recordableObject: recordableToRemove,
                                        failureHandler: failureHandler,
                                        successHandler: successHandler)
                }

                return
            }
            
            // After deleting without error, executes successHandler each time...
            if let handler = successHandler { handler() }
        }
        
        operation.completionBlock = completionHandler

        let queue = OperationQueue()
        queue.addOperation(operation)
        queue.sync {
            print("download operation completed.")
        }
    }
    
    /**
     * This method is a basic fetch operation for instances conforming to the 'Recordable' protocol. Multiple handlers
     * allow for implementation to be responsive to each transaction, as well as the batch as a whole.
     *
     * - WARNING: If unique error handling is required, do not use this method. Complex or synchronous uploads should
     * be implemented separately.
     *
     * - parameter recordablesToFetch: An array of a single type, conforming to 'Recordable' protocol that will be
     * fetched from database and saved to recordables' record storage.
     *
     * - parameter successHandler: An optional closure that will execute each time a record is successfully fetched.
     *
     * - parameter failureHandler: An optional closure that will execute each time a record in the batch fails.
     *
     * - parameter completionHandler: An optional closure that will execute at the end of the entire batch completes.
     */
//    func fetchRecordables<T: Recordable>(recordablesToFetch: [T], successHandler: OptionalClosure, failureHandler: OptionalClosure, completionHandler: OptionalClosure = nil) -> [T] {
//        
//        var updatedRecoverables = [T]()
//        
//        let records = recordablesToFetch.map() { $0.recordID }
//        let operation = CKFetchRecordsOperation(recordIDs: records)
//        
//        operation.perRecordCompletionBlock = { record, recordID, error in
//            
//            // Recover the specific recordable object effected
//            var currentRecordable: T?
//            var recordablesIndex: Int?
//            for recordable in recordablesToFetch {
//                if recordable.recordID == recordID {
//                    currentRecordable = recordable
//                    recordablesIndex = recordablesToFetch.index(where: { $0.recordID == recordable.recordID })
//                }
//            }
//            
//            // Error Handling (must occur after currentRecordable is identified).
//            guard error == nil else {
//                
//                // This should occur in any situation where record is not nil, otherwise error is '.unknownItem' and
//                // needs no handling.
//                if let recordableToFetch = currentRecordable {
//                    
//                    // Prepare for selector in the event of a retry.
//                    let executableBlock = {
//                        self.uploadRecordables(recordablesToUpdate: [recordableToFetch],
//                                               successHandler: successHandler,
//                                               failureHandler: failureHandler,
//                                               completionHandler: completionHandler)
//                    }
//                    
//                    // Generic error handling
//                    let errorHandler = CloudErrorStrategies(originatingMethodInAnEnclosure: executableBlock,
//                                                            database: self.database)
//                    errorHandler.handle(error!,
//                                        recordableObject: recordableToFetch,
//                                        failureHandler: failureHandler,
//                                        successHandler: successHandler)
//                }
//                
//                return
//            }
//            
//            if let recordFetched = record, let index = recordablesIndex {
//                var recordable = recordablesToFetch[index]
//                recordable.record = recordFetched
//                updatedRecoverables.append(recordable)
//            }
//            
//            // After fetching without error, executes successHandler each time...
//            if let handler = successHandler { handler() }
//        }
//        
//        
//        operation.completionBlock = completionHandler
//        operation.start()
//    }
    
    // MARK: - Functions (constructor)
    
    init(database: CKDatabase) {
        self.database = database
    }
}
