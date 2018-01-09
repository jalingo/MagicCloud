//
//  GetUserRecord.swift
//  MagicCloud
//
//  Created by James Lingo on 11/18/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import CloudKit

// MARK: - Class

/// This struct contains a static var (singleton) which accesses USER's iCloud CKRecordID.
public class MCUserRecord: MCRetrier {
    
    // MARK: - Properties
    
    /// This property is used to hold singleton delivery until recordID is fetched.
    fileprivate let group = DispatchGroup()

    /// This optional property stores USER recordID after it is recovered.
    fileprivate var id: CKRecordID?
    
    /**
        This read-only, computed property should be called async from main thread because it calls to remote database before returning value. If successful returns the User's CloudKit CKRecordID, otherwise returns nil.
     */
    public var singleton: CKRecordID? {
        group.enter()

        retrieveUserRecord()
        
        group.wait()
        return id
    }
    
    // MARK: - Functions
    
    /// This method handles any errors during the record fetch operation.
    fileprivate func handle(_ error: CKError) {
        if retriableErrors.contains(error.code), let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            let queue = DispatchQueue(label: retriableLabel)
            queue.asyncAfter(deadline: .now() + retryAfterValue) { self.retrieveUserRecord() }
        } else {
            
            // Fatal Errors...
            let name = Notification.Name(MCErrorNotification)
            NotificationCenter.default.post(name: name, object: error)
            
            self.group.leave()
        }
    }
    
    /// This method fetches the current USER recordID and stores it in 'id' property.
    fileprivate func retrieveUserRecord() {
        CKContainer.default().fetchUserRecordID { possibleID, possibleError in
            if let error = possibleError as? CKError {
                self.handle(error)
            } else {
                if let id = possibleID { self.id = id }
                self.group.leave()
            }
        }
    }
    
    /// This method checks to see that User is logged in to their iCloud Account.
    /// Should be run in the app delegate, before any other cloud access is attempted.
    public static func verifyAccountAuthentication(application: UIApplication) {
        CKContainer.default().accountStatus { status, possibleError in
            if let error = possibleError as? CKError {
                print("E!!: error @ credential check")
                print("#\(error.errorCode) :: \(error.localizedDescription)")
            }
            
            var msg: String?
            print("## acct status: \(status.rawValue)")
            switch status {
                /* 0 */ case .couldNotDetermine: msg = "This app requires internet access to work properly."
                /* 1 */ case .available: break      // <-- msg will remain nil, no message will be posted.
                /* 2 */ case .restricted: msg = "This app requires internet access and an iCloud account to work properly. Access was denied due to Parental Controls or Mobile Device Management restrictions."
                /* 3 */ case .noAccount: msg = "This app requires internet access and an iCloud account to work properly. From Settings, tap iCloud, authenticate your Apple ID and enable iCloud drive."
            }
            
            if let message = msg {
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                let settings = UIAlertAction(title: "Settings", style: .default) { alert in
                    
                    // This will take the user to settings app if they hit 'Settings'.
                    if let goToSettingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                        DispatchQueue.main.async { UIApplication.shared.open(goToSettingsURL, options: [:], completionHandler: nil) }
                    }
                }
                
                alertController.addAction(settings)
                
                DispatchQueue.main.async {
                    application.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    // This makes initializer public.
    public init() { }
}
