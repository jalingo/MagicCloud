//
//  CloudErrorOps.swift
//  Voyage
//
//  Created by Jimmy Lingo on 8/31/16.
//  Copyright © 2016 lingoTECH Solutions. All rights reserved.
//

import CloudKit
import UIKit

/// This global type alias represents completion handlers with success and retry indicators passed as Bools.
typealias ErrorCompletion = ((Bool, Bool?)->())?
/// This global type alias represents completion handlers and other executable blocks.
typealias OptionalClosure = (()->())?
/// This global type alias represents completion handlers and other executable blocks.
typealias NonOptionalClosure = (()->())

/**
 * This class handles the various possible CKErrors in a uniform and thorough way. Must create a new 
 * instance for each error resolution to ensure property 'executableBlock' doesn't get overwritten before 
 * func 'executeBlock' is called.
 */
class CloudErrorOps {
    
    // MARK: - Properties

    /// This property stores the targeted database.
    fileprivate let database: CKDatabase

    // TODO: Replace the executableBlock below with Operation holder (only operations should be generating errors).
    
    /// This property and 'reRunMethodOriginatingError' func allow the use of selector syntax with arguments.
    fileprivate let executableBlock: NonOptionalClosure
    
    // MARK: - Functions
    
    /// This func and 'executableBlock' property allow the use of selector syntax with arguments.
    @objc fileprivate func reRunMethodOriginatingError() { executableBlock() }
    
    // MARK: - Functions (constructor)
    
    // TODO: switch below from block to operation.

    /**
     * - parameter originatingMethodInAnEnclosure: This closure should reference the method requiring 
     *      error handling. 
     *
     * - parameter database: Database which was interacted with when the error occured.
     */
//    init(sourceOfError: CKOperation, database: CKDatabase) {
    init(originatingMethodInAnEnclosure: NonOptionalClosure, database: CKDatabase) {
        executableBlock = originatingMethodInAnEnclosure
        self.database = database
    }
    
    // MARK: - Functions (errorHandling)
    
    /**
     * This method comprehensiviley handles any cloud errors that could occur while in operation. Any 
     * unique handling should be attempted first, then remaining errors passed here for standardized 
     * response (e.g. if func needs to know if a record was found, completion block in fetch operation 
     * deals with '.unknownItem' explicitly while passing other errors to this method).
     *
     * - WARNING: If cloud functions can be gracefully disabled, then private func 'dealWithAuthenticationError'
     *      must be edited to include such changes.
     *
     * - parameter error: NSError, not optional to force check for nil / check for success before calling 
     *      method.
     *
     * - parameter recordableObject: This instance conforming to Recordable protocol generated the record 
     *      which generated said error(s).
     *
     * - parameter methodOriginatingErrorSelector: Selector that points to the func generating the error 
     *      in case a retry attempt is warranted. If left nil, no retries will be attempted, regardless 
     *      of error type.
     *
     * - parameter completionHandler: An executable block that will be called at conclusion of a
     *      error resolution.
     */
    func handle<T: Recordable>(_ error: Error, recordableObject: T, completionHandler: ErrorCompletion = nil) {
        
        if let cloudError = error as? CKError {
            switch cloudError.code {
                
            // This case requires a message to USER (with USER action to resolve), graceful disabling 
            // cloud and retry attempt.
            case .notAuthenticated:
                dealWithAuthenticationError(cloudError, completionHandler: completionHandler)
                
            // This case requires conflict resolution between the various records returned in error 
            // dictionary, but no retry.
            case .serverRecordChanged: dealWithVersionConflict(cloudError,
                                                               recordableObject: recordableObject,
                                                               completionHandler: completionHandler)
                
            // This case requires isolating the specific error(s) and handling them individually.
            case .partialFailure: dealWithPartialError(cloudError, completionHandler: completionHandler)
                
            // These cases require retry attempts, but without error messages or USER actions.
            case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .resultsTruncated:
                retryAfterError(cloudError, completionHandler: completionHandler)
                
            // TODO: Handle CKErrorLimitExceeded, need to balkanize operations.
                
            // These cases require no message to USER or retry attempts.
            default:
                print("Fatal CKError: \(cloudError)")
                if let block = completionHandler { block(false, nil) }
            }
        } else {
            print("NOT a CKError: \(error)")
        }
    }
    
    /**
     * This method handles USER authentication error by presenting an error message to USER with instructions 
     * on how to resolve, switching USER to Settings app, and then retrying error (retrying error may be 
     * problematic, if it causes USER to recieve multiple error messages during resolution attempt; needs 
     * to be alpha tested with a device).
     *
     * If cloud capabilities aren't integral to core app performance (i.e. it can be disabled) than whatever 
     * changes to the UI that are needed to ensure 'graceful' disabling of cloud features should also occur 
     * here.
     */
    fileprivate func dealWithAuthenticationError(_ error: CKError, completionHandler: ErrorCompletion) {
        
        // TODO: Gracefully disable any functionality requiring cloud authentication here...    // <-- !!
        
        // Message presented to USER, and app switched to 'Settings'
        let message = "Your device needs to be logged in to your iCloud Account in order for Voyager to work correctly. After clicking 'OK' you will be taken to Voyager Settings. From there you can back out and select iCloud Settings to log in."
        ErrorMessage.presentToUserModally(message) { action in
            
            // This will take the user to settings app if they hit 'Ok'.
            if let goToSettingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                DispatchQueue.main.async {
                    UIApplication.shared.openURL(goToSettingsURL)
                }
            }
            
            // TODO: This will attempt to retry original cloud interaction... //<-- This shouldn't happen until notified account change and not as a retry !!
        }
    }
    
    /**
     * This method recovers the original (record that app expected to find in the database), the attempt 
     * (record that app tried to upload during failure), and the current (record that is in the database)
     * records and determines which individual fields in current can be matched to the attempt based on 
     * current values' differences from the original. Field will only be updated if current field value 
     * was not an update to the original record and the attempt is not the same as the current.
     *
     * - parameter error: The CKError requiring version conflict to be resolved.
     *
     * - parameter recordableObject: The instance conforming to 'Recordable' protocol that was interacting 
     *      with the cloud database when the version conflict occured.
     *
     * - parameter completionHandler: After version conflict is dealt with, this executable block will be 
     *      passed a boolean argument indicating whether conflict was resolved successfully (true) or not 
     *      (false) and then run.
     */
    fileprivate func dealWithVersionConflict<T: Recordable>
        (_ error: CKError, recordableObject: T, completionHandler: ErrorCompletion) {
        
        guard let original = error.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord,
            let current = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
            let attempt = error.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord
            else {
                // Error not dealt with, completion failed.
                if let handler = completionHandler { handler(false, nil) }
                return
        }
        
        // This for loop goes through every record field, attempting version conflict resolution.
        for entry in recordableObject.dictionaryOfKeysAndAssociatedValueTypes {
            if let originalValue = original[entry.key] as? entry.Type,
                let currentValue = current[entry.key] as? entry.Type,
                let attemptValue = attempt[entry.key] as? entry.Type {
                
                if currentValue == originalValue && currentValue != attemptValue {
                    current[entry.key] = attemptValue as? CKRecordValue
                }
            }
        }
        
        // Uploads current record with changes made and new changeTag.
        let operation = CKModifyRecordsOperation(recordsToSave: [current], recordIDsToDelete: nil)
        operation.perRecordCompletionBlock = { record, error in
            guard error == nil else {
                let errorHandler = CloudErrorOps(originatingMethodInAnEnclosure: self.executableBlock,
                                                 database: self.database)
                errorHandler.handle(error!,
                                    recordableObject: recordableObject,
                                    completionHandler: completionHandler)
                return
            }
            
            // After successful update, run success handler.
            if let handler = completionHandler { handler(true, nil) }
        }

        // Add operation to queue with successful completion handler.
        let queue = OperationQueue()
        
        if let handler = completionHandler {
            operation.completionBlock = { handler(true, nil) }
        }
        
        queue.addOperation(operation)
        
    }
    
    /**
     * This method takes partial errors (resulting from batch attempt) and isolates to the failed transactions.
     * After isolation, they can be passed back to through the error handling system individually.
     */
    fileprivate func dealWithPartialError(_ error: CKError, completionHandler: ErrorCompletion) {
        guard let dictionary = error.userInfo[CKPartialErrorsByItemIDKey] else {
            if let handler = completionHandler { handler(false, nil) }
            return
        }
        
        // TODO: Isolate errors from batch, and handle individually.
    }
    
    /**
     * Certain errors require a retry attempt (e.g. ZoneBusy), so this method recovers retry time from 
     * userInfo dictionary and then schedules another attempt.
     */
    fileprivate func retryAfterError(_ error: CKError, completionHandler: ErrorCompletion) {
        guard let handler = completionHandler else { return }
        
        if let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            DispatchQueue.main.async {
                if let controller = UIApplication.shared.keyWindow?.rootViewController {
                    Timer.scheduledTimer(timeInterval: retryAfterValue,
                                         target: controller,
                                         selector: #selector(self.reRunMethodOriginatingError),
                                         userInfo: nil,
                                         repeats: false)
                    
                    handler(false, true)  // <-- Indicates failure with retry underway.
                } else {
                    handler(false, false) // <-- Indicates failure without retry attempt.
                }
            }
        } else {
            handler(false, false)         // <-- Indicates failure without retry attempt.
        }
    }
}

