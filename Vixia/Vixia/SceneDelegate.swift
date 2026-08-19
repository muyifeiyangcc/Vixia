//
//  SceneDelegate.swift
//  Vixia
//
//  Created by myx mac on 2026/8/5.
//

import UIKit
import FBSDKCoreKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var coordinator: AppCoordinator?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        let coordinator = AppCoordinator(window: window)
        self.coordinator = coordinator
        let bPackageShouldRequestInitialRoute = BPackageProfile.bPackageShouldRequestInitialRoute
        coordinator.start(bPackageDefersEULAUntilRouteDecision: bPackageShouldRequestInitialRoute)

        // MARK: - BPackage Begin
        if bPackageShouldRequestInitialRoute,
           let bPackageContext = coordinator.bPackageNavigationContext() {
            BPackage.bPackageShared.bPackageStart(
                bPackageNavigationController: bPackageContext.bPackageNavigationController,
                bPackageConfiguration: BPackageProfile.bPackageConfiguration,
                bPackageAPackageViewController: bPackageContext.bPackageAPackageViewController,
                bPackageAppearance: BPackageProfile.bPackageAppearance,
                bPackageAnalyticsAdapter: APackageBAnalyticsAdapter.bPackageShared,
                bPackageOnAPackageRoute: { [weak coordinator] in
                    coordinator?.bPackagePresentEULAIfNeeded()
                }
            )
        } else if bPackageShouldRequestInitialRoute {
            BPackageLogger.bPackageShared.bPackageLog("启动门禁", "无法取得 A 包导航上下文，保留 A 包并显示 EULA")
            coordinator.bPackagePresentEULAIfNeeded()
        } else {
            BPackageLogger.bPackageShared.bPackageLog(
                "时间门禁",
                "当前时间未超过 \(Int(BPackageProfile.bPackageOpenRequestCutoffTimestamp))，不请求启动接口，直接进入 A 包"
            )
        }
        // MARK: - BPackage End
    }

    // MARK: - BPackage URL Routing

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let bPackageURL = URLContexts.first?.url else { return }
        if bPackageURL.scheme?.lowercased() == BPackageProfile.bPackageConfiguration.bPackageExternalScheme {
            _ = BPackage.bPackageShared.bPackageHandleOpenURL(bPackageURL)
            return
        }
        _ = ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: bPackageURL,
            options: [:]
        )
    }

    func showLogin() { coordinator?.showLogin() }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
