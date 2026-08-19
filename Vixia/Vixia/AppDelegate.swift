//
//  AppDelegate.swift
//  Vixia
//
//  Created by myx mac on 2026/8/5.
//

import UIKit
import IQKeyboardManagerSwift
#if canImport(AdjustSdk)
import AdjustSdk
#endif
import FBSDKCoreKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AdjustDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true

        // MARK: - BPackage Begin
        StoreKit1PurchaseManager.bPackageShared.bPackageStartObserving()

        APackageBAnalyticsAdapter.bPackageShared.bPackageInitializeFacebook(
            bPackageApplication: application,
            bPackageLaunchOptions: launchOptions
        )

        let bPackageAppID = BPackageProfile.bPackageConfiguration.bPackageAppID
        let bPackageDeviceID = BPackageStorage.bPackageShared.bPackageStableDeviceID(
            bPackageAppID: bPackageAppID
        )
        Adjust.addGlobalCallbackParameter(bPackageDeviceID, forKey: "ta_distinct_id")
        if let bPackageAdjustConfig = ADJConfig(
            appToken: BPackageThirdPartyProfile.bPackageAdjustAppToken,
            environment: ADJEnvironmentSandbox
        ) {
            bPackageAdjustConfig.delegate = self
            bPackageAdjustConfig.logLevel = .info
            bPackageAdjustConfig.enableSendingInBackground()
            bPackageAdjustConfig.enableCostDataInAttribution()
            Adjust.initSdk(bPackageAdjustConfig)
        }

        UNUserNotificationCenter.current().delegate = self
        // MARK: - BPackage End

        // Register the StoreKit V1 transaction observer at app launch so
        // interrupted consumable purchases can finish on the next launch.
        _ = PurchaseManager.shared
        return true
    }

    // MARK: - BPackage Begin

    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        Adjust.adid { bPackageAdID in
            Task { @MainActor in
                let bPackageNormalizedAdID = bPackageAdID ?? ""
                APackageBAnalyticsAdapter.bPackageShared.bPackageUpdateAttribution(
                    bPackageAttribution: attribution,
                    bPackageAdID: bPackageNormalizedAdID
                )
                BPackage.bPackageShared.bPackageAdjustAttributionChanged(
                    bPackageResult: APackageBAnalyticsAdapter.bPackageShared.bPackageAttributionResult,
                    bPackageAdID: bPackageNormalizedAdID
                )
            }
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        BPackageAppDelegateSupport.bPackageDidRegisterForRemoteNotifications(
            bPackageDeviceToken: deviceToken
        )
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        BPackageLogger.bPackageShared.bPackageLog("推送错误", error.localizedDescription)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        StoreKit1PurchaseManager.bPackageShared.bPackageStopObserving()
    }

    // MARK: - BPackage End

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

// MARK: - BPackage Notifications

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        BPackageLogger.bPackageShared.bPackageLog("推送", "用户点击通知")
        completionHandler()
    }
}
