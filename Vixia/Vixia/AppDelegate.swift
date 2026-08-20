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

        // MARK: - CAResBottleMyRY Begin
        StoreKit1PurchaseManager.CABootHousePotionRY.CASpellBrushSecureRY()

        APackageBAnalyticsAdapter.CABootHousePotionRY.CAPickColonialBirthRY(
            CALaptopSwapWindowRY: application,
            CAIdahoUntilSixRY: launchOptions
        )

        let CAMaxKeyMonkeyRY = CASeabedOneSpellRY.CAIdahoHoorayEnhanceRY.CAMaxKeyMonkeyRY
        let CASayOrangeIndexRY = CAChairDearSlowRY.CABootHousePotionRY.CAInfoMouseHoorayRY(
            CAMaxKeyMonkeyRY: CAMaxKeyMonkeyRY
        )
        Adjust.addGlobalCallbackParameter(CASayOrangeIndexRY, forKey: "ta_distinct_id")
        if let CASnowingClearSkyRY = ADJConfig(
            appToken: CAReadFishZeroRY.CAPassDirectorForgetRY,
            environment: ADJEnvironmentSandbox
        ) {
            CASnowingClearSkyRY.delegate = self
            CASnowingClearSkyRY.logLevel = .info
            CASnowingClearSkyRY.enableSendingInBackground()
            CASnowingClearSkyRY.enableCostDataInAttribution()
            Adjust.initSdk(CASnowingClearSkyRY)
            Task {
                _ = await APackageBAnalyticsAdapter.CABootHousePotionRY.CAAnyJumpMuchRY()
            }
        }

        UNUserNotificationCenter.current().delegate = self
        // MARK: - CAResBottleMyRY End

        // Register the StoreKit V1 transaction observer at app launch so
        // interrupted consumable purchases can finish on the next launch.
        _ = PurchaseManager.shared
        return true
    }

    // MARK: - CAResBottleMyRY Begin

    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        Adjust.adid { CACopperMoleBigRY in
            Task { @MainActor in
                let CACountZeroSubRY = CACopperMoleBigRY ?? ""
                APackageBAnalyticsAdapter.CABootHousePotionRY.CABlindUpAirRY(
                    CAMuchNightRunsRY: attribution,
                    CACopperMoleBigRY: CACountZeroSubRY
                )
                CAResBottleMyRY.CABootHousePotionRY.CALeaveMomentsFishRY(
                    CAAversionMagicFireRY: APackageBAnalyticsAdapter.CABootHousePotionRY.CAResWinDialectRY,
                    CACopperMoleBigRY: CACountZeroSubRY
                )
            }
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        CASlimeColonialLastRY.CAEveryGardenCeillingRY(
            CAPhoneKnightCoalitionRY: deviceToken
        )
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {}

    func applicationWillTerminate(_ application: UIApplication) {
        StoreKit1PurchaseManager.CABootHousePotionRY.CAFlatSupportAngerRY()
    }

    // MARK: - CAResBottleMyRY End

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

// MARK: - CAResBottleMyRY Notifications

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
