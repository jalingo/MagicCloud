//
//  AlertOperation.swift
//  CKErrorHandler
//
//  Created by j.lingo on 9/16/16.
//
//

import Foundation
import UIKit

/// This global type alias represents completion handlers for UIAlertActions.
typealias AlertClosure = ((UIAlertAction) -> Void)?

/**
 * This sub-class of Operation can be used to present a UIAlertController to USER.
 */
class AlertOperation: Operation {
    
    fileprivate let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    
    fileprivate var targetController: UIViewController?
    
    fileprivate var okAction: AlertClosure
    
    override func main() {
        
        if isCancelled { return }
        
        alertController.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: nil))

        
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: .default,
                                                handler: okAction))

        if isCancelled { return }

        DispatchQueue.main.async { [weak self] in
            if let me = self {
                me.targetController?.present(me.alertController,
                                             animated: true,
                                             completion: nil)
            }
        }
    }
    
    init(title: String = "Alert", message: String, context: UIViewController?, action: AlertClosure) {
        alertController.title = title
        alertController.message = message
        targetController = context ?? UIApplication.shared.keyWindow?.rootViewController
        okAction = action
        
        super.init()
    }
    
    // This init without dependencies has been overridden to make it private and inaccessible.
    fileprivate override init() { }
}
