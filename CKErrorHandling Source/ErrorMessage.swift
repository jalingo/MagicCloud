//
//  ErrorMessage.swift
//  Voyage
//
//  Created by Jimmy Lingo on 8/31/16.
//  Copyright © 2016 lingoTECH Solutions. All rights reserved.
//

import UIKit

/**
 * This struct handles error message delivery to USER.
 */
struct ErrorMessage {
    
    /**
     * This method can present a modal error message to the USER's interface on iOS devices.
     */
    static func presentToUserModally(_ message: String?, handler: ((UIAlertAction) -> Void)?) {
        
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel",
            style: .cancel,
            handler: nil))
        
        alert.addAction(UIAlertAction(title: "OK",
            style: .default,
            handler: handler))
        
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?
                .present(alert, animated: true, completion: nil)
        }
    }
}
