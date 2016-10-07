//
//  UnauthenticErrorOperation.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/20/16.
//
//

import Foundation
import UIKit

/**
 * This class handles USER authentication error by presenting an error message to USER with instructions
 * on how to authenticate, and then switching USER to Settings app if they tap 'OK' from the message.
 *
 * If cloud capabilities aren't integral to core app performance (i.e. it can be disabled) than whatever
 * changes to the UI that are needed to ensure 'graceful' disabling of cloud features should also occur
 * here.
 */
class UnauthenticErrorOperation: Operation {
    
    override func main() {
        if isCancelled { return }
        
        // TODO: Gracefully disable any functionality requiring cloud authentication here...    
        let gracefulDisable = DisableCloudOperation()
        
        // Message presented to USER, and app switched to 'Settings' when USER taps 'OK'.
        let message = "Your device needs to be logged in to your iCloud Account in order for Voyager to work correctly. After clicking 'OK' you will be taken to Voyager Settings. From there you can back out and select iCloud Settings and log in to an iCloud account."
        let alertOp = AlertOperation(title: "Error", message: message, context: nil) { action in
            if let goToSettingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                DispatchQueue.main.async {
                    // TODO: Find documentation for the option dictionary argument...
                    UIApplication.shared.open(goToSettingsURL, completionHandler: nil)
                }
            }
        }
        
        if isCancelled { return }
        
        // Fires operation, with alert waiting until cloud functionality completes disablement.
        let queue = ErrorQueue()
        alertOp.addDependency(gracefulDisable)
        queue.addOperation(gracefulDisable)
        queue.addOperation(alertOp)
    }
}
