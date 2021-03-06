//
//  AppDelegate.swift
//  TestApp
//
//  Created by James Lingo on 11/15/17.
//  Copyright © 2017 Escape Chaos. All rights reserved.
//

import UIKit
import CloudKit
import MagicCloud

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MCNotificationConverter {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        MCUserRecord.verifyAccountAuthentication()

        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // This method creates a local notification from remote's userInfo, if it was intended for MagicCloud.
        if convertToLocal(from: userInfo) {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
        
        // This observer demonstrates how to access error notifications and their underlying data.
        let name = Notification.Name(MCErrorNotification)
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { notification in
            
            // Error notifications from MagicCloud should always include the actual CKError as Notification.object.
            if let error = notification.object as? CKError { print("!! CKError: \(error.code.rawValue) / \(error.localizedDescription)") }

            if let info = notification.userInfo {
                let cNote = CKQueryNotification(fromRemoteNotificationDictionary: info)
                let trigger = cNote.notificationType
                if let id = cNote.recordID { self.doSomethingWith(this: trigger, or: id) }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) { }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { /* NEED TO GRACEFULLY DISABLE ANY CLOUD DEPENDENT BEHAVIOR HERE */ }
    
    func doSomethingWith(this: CKNotificationType, or: CKRecordID) { /* YOU COULD DO ADDITIONAL ERROR HANDLING HERE */ }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

