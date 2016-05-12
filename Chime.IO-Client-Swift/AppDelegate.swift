//
//  AppDelegate.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/18/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import CWStatusBarNotification
import RxSwift
import UIKit

enum AppNotification: String {
    case WillLogout = "AppWillLogOut"
    case DidLogout = "AppDidLogOut"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let disposeBag = DisposeBag()
    private let sn = CWStatusBarNotification()
    private let snDuration = 2.0
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // show connection status
        sn.notificationAnimationInStyle = .Top
        sn.notificationAnimationOutStyle = .Top
        SharingManager.defaultManager.chioStatusOA.subscribeOn(MainScheduler.instance).subscribeNext {
            switch $0 {
            case .Connecting:
                self.sn.notificationLabel?.backgroundColor = UIColor.orangeColor()
                if self.sn.notificationIsShowing {
                    self.sn.notificationLabel?.text = "Connecting..."
                } else {
                    self.sn.displayNotificationWithMessage("Connecting..", completion: {})
                }
            case .Connected:
                self.sn.notificationLabel?.backgroundColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
                if self.sn.notificationIsShowing {
                    self.sn.notificationLabel?.text = "Connected"
                    dispatch_after(dispatch_time(
                        DISPATCH_TIME_NOW, Int64(self.snDuration * Double(NSEC_PER_SEC))),
                    dispatch_get_main_queue()) {
                        self.sn.dismissNotification()
                    }
                } else {
                    self.sn.displayNotificationWithMessage("Connected!", forDuration: self.snDuration)
                }
            default:
                self.sn.notificationLabel?.backgroundColor = UIColor.darkGrayColor()
                if self.sn.notificationIsShowing {
                    self.sn.notificationLabel?.text = "Not Connected"
                } else {
                    self.sn.displayNotificationWithMessage("Not Connected", completion: {})
                }
            }
        }.addDisposableTo(disposeBag)
        
        // connect to server
        ChIO.sharedInstance.connect()
        
        // will-logout handler
        NSNotificationCenter.defaultCenter()
            .rx_notification(AppNotification.WillLogout.rawValue)
            .asObservable()
            .subscribeNext { _ in ChIO.sharedInstance.logout() }
            .addDisposableTo(disposeBag)
        
        // main
        let navController = UINavigationController(rootViewController: LoginViewController())
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

