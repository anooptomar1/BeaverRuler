//
//  AppDelegate.swift
//  BeaverRuler
//
//  Created by Sasha on 8/16/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit
import Appodeal
import Fabric
import Crashlytics
import FacebookCore
import StoreKit
import Firebase
import OneSignal
import YandexMobileMetrica

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {

    var window: UIWindow?
    var appRater: APAppRater?
    var pushNotificationHelper:PushNotificationHelper?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        FirebaseApp.configure()
        let adTypes: AppodealAdType = [.nativeAd, .interstitial]
        Appodeal.initialize(withApiKey: "982a00948cdaa99b8e99b8f83a35d8afaa5fbb697ed398a7", types: adTypes)
        

        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "2b24c120-7fa4-4582-b2c9-50a7a9196175",
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        
        appRater = APAppRater.sharedInstance
        pushNotificationHelper = PushNotificationHelper.sharedInstance
        
        SKPaymentQueue.default().add(self)
        initializeAppmetrica()
        
        return true
    }
    
     func initializeAppmetrica()
    {
        let configuration = YMMYandexMetricaConfiguration.init(apiKey: "20c6566e-e9b1-4a2c-96b1-ac1c0810c093")
        let isFirstApplicationLaunch = APAppRater.sharedInstance.getAppLaunchCount() < 2
        configuration?.handleFirstActivationAsUpdateEnabled = isFirstApplicationLaunch == false
        YMMYandexMetrica.activate(with: configuration!)
        YMMYandexMetrica.setLoggingEnabled(true)
        YMMYandexMetrica.setTrackLocationEnabled(true)
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return SDKApplicationDelegate.shared.application(application, open: url, options: options)
    }

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
        AppEventsLogger.activate(application)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - SKPaymentTransactionObserver
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }

}

