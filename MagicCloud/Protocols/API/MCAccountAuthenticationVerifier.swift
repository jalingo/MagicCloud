//
//  MCAccountAuthenticationVerifier.swift
//  MagicCloud
//
//  Created by James Lingo on 3/25/18.
//  Copyright © 2018 Escape Chaos. All rights reserved.
//

import CloudKit
import UIKit

/// Types conforming to this protocol can call the `verifyAccountAuthentication` method and check to see that USER is logged in to their iCloud Account.
protocol MCAccountAuthenticationVerifier { }

extension MCAccountAuthenticationVerifier {
    
    /// This method checks to see that User is logged in to their iCloud Account.
    /// Should be run in the app delegate, before any other cloud access is attempted.
    public static func verifyAccountAuthentication() {
        CKContainer.default().accountStatus { status, possibleError in
            if let error = possibleError as? CKError {
                print("         EE: MCUserRecord error @ credential check")
                print("             MCUserRecord \(error.errorCode) :: \(error.localizedDescription)")
            }
            
            var msg: String?
            
            switch status {
                /* 0 */ case .couldNotDetermine: msg = "This app requires internet access to work properly."
            /* 1 */ case .available: break      // <-- msg will remain nil, no message will be posted.
                /* 2 */ case .restricted: msg = """
                This app requires internet access and an iCloud account to work properly.
                
                Access was denied due to Parental Controls or Mobile Device Management restrictions.
                """
                /* 3 */ case .noAccount: msg = """
                This app requires internet access and an iCloud account to work properly.
                
                From Settings, tap iCloud, authenticate your Apple ID and enable iCloud drive.
                """
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
                    UIApplication.shared.keyWindow?.rootViewController?.present(alertController,
                                                                                animated: true,
                                                                                completion: nil)
                }
            }
        }
    }
}
