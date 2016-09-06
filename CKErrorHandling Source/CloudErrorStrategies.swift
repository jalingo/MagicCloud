//
//  CloudErrorStrategies.swift
//  Voyage
//
//  Created by Jimmy Lingo on 8/31/16.
//  Copyright © 2016 lingoTECH Solutions. All rights reserved.
//

import CloudKit
import UIKit

/// This global type alias represents a completion handlers with a success indicator passed as Bool.
typealias ErrorCompletion = ((Bool)->())?
/// This global type alias represents completion handlers and other executable blocks.
typealias OptionalClosure = (()->())?
/// This global type alias represents completion handlers and other executable blocks.
typealias NonOptionalClosure = (()->())

// Must create a new instance for each error resolution to ensure property 'executableBlock' doesn't get overwritten before func 'executeBlock' is called.
class CloudErrorStrategies {
    
    // MARK: - Properties

    var database: CKDatabase
    
    /// This property and 'reRunMethodOriginatingError' func allow the use of selector syntax with arguments.
    var executableBlock: NonOptionalClosure
    
    // MARK: - Functions
    
    /// This func and 'executableBlock' property allow the use of selector syntax with arguments.
    @objc fileprivate func reRunMethodOriginatingError() { executableBlock() }
    
    // MARK: - Functions (constructor)
    
    init(originatingMethodInAnEnclosure: NonOptionalClosure, database: CKDatabase) {
        executableBlock = originatingMethodInAnEnclosure
        self.database = database
    }
    
    // MARK: - Functions (errorHandling)
    
    /**
     * This method comprehensiviley handles any cloud errors that could occur while in operation. Any unique
     * handling should be attempted first, then remaining errors passed here for standardized response (e.g. if 
     * func needs to know if a record was found, completion block in fetch operation deals with '.unknownItem' 
     * explicitly while passing other errors to this method.
     *
     * - WARNING: If cloud functions can be gracefully disabled, then private func 'dealWithAuthenticationError'
     *            must be edited to include such changes.
     *
     * - parameter error: NSError, not optional to force check for nil / check for success before calling method.
     *
     * - parameter recordableObject: This instance conforming to Recordable protocol generated the record which 
     * generated said error(s).
     *
     * - parameter methodOriginatingErrorSelector: Selector that points to the func generating the error in case 
     * a retry attempt is warranted. If left nil, no retries will be attempted, regardless of error type.
     *
     * - parameter successHandler: An executable block that will be called at conclusion of a SUCCESSFUL error 
     * resolution.
     *
     * - parameter failureHandler: An executable block that will be called at conclusion of a FAILED error resolution.
     */
    func handle<T: Recordable>(_ error: Error, recordableObject: T, failureHandler: OptionalClosure = nil, successHandler: OptionalClosure = nil) {
        
        if let cloudError = error as? CKError {
            switch cloudError.code {
                
            // This case requires a message to USER (with USER action to resolve), graceful disabling cloud and retry attempt.
            case .notAuthenticated: dealWithAuthenticationError(cloudError,
                                                                successHandler: successHandler,
                                                                failureHandler: failureHandler)
                
            // This case requires conflict resolution between the various records returned in error dictionary, but no retry.
            case .serverRecordChanged: dealWithVersionConflict(cloudError,
                                                               recordableObject: recordableObject,
                                                               successHandler: successHandler,
                                                               failureHandler: failureHandler)
                
            // This case requires isolating
            case .partialFailure: dealWithPartialError(cloudError,
                                                       successHandler: successHandler,
                                                       failureHandler: failureHandler)
                
            // These cases require retry attempts, but without error messages or USER actions.
            case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .resultsTruncated:
                retryAfterError(cloudError, successHandler: successHandler, failureHandler: failureHandler)
                
            // These cases require no message to USER or retry attempts.
            default:
                print("CKError: \(cloudError)")
                if let block = failureHandler { block() }
            }
        } else {
            print("NOT a CKError: \(error)")
        }
    }
    
    /**
     * This method handles USER authentication error by presenting an error message to USER with instructions on 
     * how to resolve, switching USER to Settings app, and then retrying error (retrying error may be problematic, 
     * if it causes USER to recieve multiple error messages during resolution attempt; needs to be alpha tested 
     * with a device).
     *
     * If cloud capabilities aren't integral to core app performance (i.e. it can be disabled) than whatever changes 
     * to the UI that are needed to ensure 'graceful' disabling of cloud features should also occur here.
     */
    fileprivate func dealWithAuthenticationError(_ error: CKError, successHandler: OptionalClosure, failureHandler: OptionalClosure) {
        
        // Gracefully disable any functionality requiring cloud authentication here...
        
        // Message presented to USER, and app switched to 'Settings'
        let message = "Your device needs to be logged in to your iCloud Account in order for Voyager to work correctly. After clicking 'OK' you will be taken to Voyager Settings. From there you can back out and select iCloud Settings to log in."
        ErrorMessage.presentToUserModally(message) { action in
            
            // This will take the user to settings app if they hit 'Ok'.
            if let goToSettingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                DispatchQueue.main.async {
                    UIApplication.shared.openURL(goToSettingsURL)
                }
            }
            
            // This will attempt to retry original cloud interaction... //<-- This shouldn't happen until notified account change and not as a retry !!
        }
    }
    
    /**
     * This method recovers the original (record that app expected to find in the database), the attempt (record that
     * app tried to upload during failure), and the current (record that is in the database) records and determines
     * which individual fields in current can be matched to the attempt based on current values' differences from the
     * original. Field will only be updated if current field value was not an update to the original record and the 
     * attempt is not the same as the current.
     */
    fileprivate func dealWithVersionConflict<T: Recordable>(_ error: CKError, recordableObject: T, successHandler: OptionalClosure, failureHandler: OptionalClosure) {
        
        guard let original = error.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord,
            let current = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
            let attempt = error.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord
            else { return }     // <-- If we're triggering completion handler
        
        // This for loop goes through every record field, attempting version conflict resolution.
        for entry in T.dictionaryOfKeysAndAssociatedValueTypes {
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
                let errorHandler = CloudErrorStrategies(originatingMethodInAnEnclosure: self.executableBlock,
                                                        database: self.database)
                errorHandler.handle(error!,
                                    recordableObject: recordableObject,
                                    failureHandler: failureHandler,
                                    successHandler: successHandler)
                return
            }
            
            // After successful update, run success handler.
            if let handler = successHandler { handler() }
        }
        
        let queue = DispatchQueue(label: "modifyRecords", attributes: .serial)
        
    }
    
    /**
     *
     */
    fileprivate func dealWithPartialError(_ error: CKError, successHandler: OptionalClosure, failureHandler: OptionalClosure) {
        guard let dictionary = error.userInfo[CKPartialErrorsByItemIDKey] else {
            if let handler = failureHandler { handler() }
            return
        }
        
        //
    }
    
    /**
     * Certain errors require a retry attempt (e.g. ZoneBusy), so this method recovers retry time from userInfo dictionary
     * and then schedules another attempt.
     */
    fileprivate func retryAfterError(_ error: CKError, successHandler: OptionalClosure, failureHandler: OptionalClosure) {
        
        // Need to setup a notification that will trigger completionHandler...
        let predicate = NSPredicate(format: <#T##String#>, <#T##args: CVarArg...##CVarArg#>)
        let subsription = CKSubscription(recordType: <#T##String#>, predicate: <#T##NSPredicate#>, options: <#T##CKSubscriptionOptions#>)
        
        
        if let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            DispatchQueue.main.async {
                if let controller = UIApplication.shared.keyWindow?.rootViewController {
                    Timer.scheduledTimer(timeInterval: retryAfterValue,
                                         target: controller,
                                         selector: #selector(self.reRunMethodOriginatingError),
                                         userInfo: nil,
                                         repeats: false)
                }
            }
        }
        

    }
}

