import UIKit

struct BPackageAppearance {
    var bPackageLaunchBackgroundImage: UIImage? = nil
    var bPackageLoginBackgroundImage: UIImage? = nil
    var bPackageWebBackgroundImage: UIImage? = nil
}

@MainActor
final class BPackage {
    static let bPackageShared = BPackage()
    static let bPackageOpenURLNotification = Notification.Name("bPackage.openURL")

    private weak var bPackageNavigationController: UINavigationController?
    private weak var bPackageAPackageViewController: UIViewController?
    private var bPackageCoordinator: BPackageCoordinator?
    private var bPackageAppearance = BPackageAppearance()
    private var bPackageLaunchCover: UIView?
    private var bPackagePendingInstallAttribution: (bPackageResult: String?, bPackageAdID: String)?
    private var bPackageDidStart = false
    private var bPackageCanApplyInitialRoute = true
    private var bPackageInitialRouteState = BPackageInitialRouteState.bPackageIdle

    private enum BPackageInitialRouteState {
        case bPackageIdle
        case bPackageLoading
        case bPackageResolved(BPackageRoute)
        case bPackageFailed(String)
    }

    private init() {}

    func bPackageStart(bPackageNavigationController: UINavigationController,
                       bPackageConfiguration: BPackageConfiguration,
                       bPackageAPackageViewController: UIViewController,
                       bPackageAppearance: BPackageAppearance,
                       bPackageAnalyticsAdapter: BPackageAnalyticsAdapter,
                       bPackageDefersInitialRouteUntilApproval: Bool = false) {
        guard !bPackageDidStart else {
            BPackageLogger.bPackageShared.bPackageLog("流程", "BPackage 已启动，忽略重复调用")
            return
        }
        bPackageDidStart = true
        self.bPackageNavigationController = bPackageNavigationController
        self.bPackageAPackageViewController = bPackageAPackageViewController
        self.bPackageAppearance = bPackageAppearance
        bPackageCanApplyInitialRoute = !bPackageDefersInitialRouteUntilApproval
        bPackageInitialRouteState = .bPackageLoading
        if bPackageCanApplyInitialRoute {
            bPackageShowLaunchCover()
        } else {
            BPackageLogger.bPackageShared.bPackageLog("协议门禁", "已提前请求启动接口；Agree 前仅缓存结果，不执行 A/B 路由")
        }
        Task { @MainActor in
            do {
                let bPackageCoordinator = try BPackageCoordinator(bPackageConfiguration: bPackageConfiguration,
                                                                  bPackageAnalyticsAdapter: bPackageAnalyticsAdapter)
                self.bPackageCoordinator = bPackageCoordinator
                if let bPackagePendingInstallAttribution {
                    bPackageCoordinator.bPackageEventReporter.bPackageReportInstallFromAttribution(
                        bPackageResult: bPackagePendingInstallAttribution.bPackageResult,
                        bPackageAdID: bPackagePendingInstallAttribution.bPackageAdID
                    )
                    self.bPackagePendingInstallAttribution = nil
                }
                let bPackageRoute = try await bPackageCoordinator.bPackageResolveInitialRoute()
                bPackageInitialRouteState = .bPackageResolved(bPackageRoute)
                bPackageProcessInitialRouteState()
            } catch {
                bPackageInitialRouteState = .bPackageFailed(error.localizedDescription)
                bPackageProcessInitialRouteState()
            }
        }
    }

    func bPackageApproveInitialRouteApplication() {
        guard bPackageDidStart, !bPackageCanApplyInitialRoute else { return }
        bPackageCanApplyInitialRoute = true
        BPackageLogger.bPackageShared.bPackageLog("协议门禁", "用户已同意 EULA，开始处理启动接口结果")
        bPackageProcessInitialRouteState()
    }

    func bPackageDidRegisterForRemoteNotifications(bPackageDeviceToken: Data) {
        BPackageStorage.bPackageShared.bPackagePushToken = bPackageDeviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        BPackageLogger.bPackageShared.bPackageLog("推送", "APNs token 已获取并保存")
    }

    /// 必须从 AdjustDelegate.adjustAttributionChanged 回调中调用。
    /// 回调早于 BPackage 初始化时会暂存，初始化完成后再执行 Install 与 ...j。
    func bPackageAdjustAttributionChanged(bPackageResult: String?, bPackageAdID: String) {
        guard let bPackageCoordinator else {
            bPackagePendingInstallAttribution = (bPackageResult, bPackageAdID)
            BPackageLogger.bPackageShared.bPackageLog("Adjust", "归因回调早于 BPackage 初始化，已暂存 Install")
            return
        }
        bPackageCoordinator.bPackageEventReporter.bPackageReportInstallFromAttribution(
            bPackageResult: bPackageResult,
            bPackageAdID: bPackageAdID
        )
    }

    @discardableResult
    func bPackageHandleOpenURL(_ bPackageURL: URL) -> Bool {
        BPackageLogger.bPackageShared.bPackageLog("外部唤起", "已处理 Scheme：\(bPackageURL.scheme ?? "")")
        NotificationCenter.default.post(name: Self.bPackageOpenURLNotification, object: nil,
                                        userInfo: ["bPackageURL": bPackageURL.absoluteString])
        return true
    }

    private func bPackageApplyRoute(_ bPackageRoute: BPackageRoute) {
        switch bPackageRoute {
        case .bPackageAPackage:
            BPackageLogger.bPackageShared.bPackageLog("完成", "进入 A 包")
        case .bPackageLogin(let bPackageMode):
            bPackageShowQuickLogin(bPackageMode: bPackageMode)
        }
    }

    private func bPackageProcessInitialRouteState() {
        guard bPackageCanApplyInitialRoute else {
            switch bPackageInitialRouteState {
            case .bPackageResolved:
                BPackageLogger.bPackageShared.bPackageLog("协议门禁", "启动接口结果已缓存，等待用户点击 Agree")
            case .bPackageFailed:
                BPackageLogger.bPackageShared.bPackageLog("协议门禁", "启动接口已结束，等待 Agree 后保留 A 包")
            case .bPackageIdle, .bPackageLoading:
                break
            }
            return
        }

        switch bPackageInitialRouteState {
        case .bPackageIdle:
            break
        case .bPackageLoading:
            bPackageShowLaunchCover()
        case .bPackageResolved(let bPackageRoute):
            bPackageInitialRouteState = .bPackageIdle
            bPackageRemoveLaunchCover()
            bPackageApplyRoute(bPackageRoute)
        case .bPackageFailed(let bPackageMessage):
            bPackageInitialRouteState = .bPackageIdle
            bPackageRemoveLaunchCover()
            BPackageLogger.bPackageShared.bPackageLog("启动失败", "\(bPackageMessage)，保留 A 包页面")
        }
    }

    private func bPackageShowQuickLogin(bPackageMode: BPackageLoginMode) {
        guard let bPackageCoordinator, let bPackageNavigationController else { return }
        guard !(bPackageNavigationController.topViewController is BPackageQuickLoginViewController) else {
            BPackageLogger.bPackageShared.bPackageLog("路由", "快速登录页已显示，忽略重复跳转")
            return
        }
        let bPackageLogin = BPackageQuickLoginViewController(bPackageCoordinator: bPackageCoordinator,
                                                             bPackageMode: bPackageMode,
                                                             bPackageBackgroundImage: bPackageAppearance.bPackageLoginBackgroundImage,
                                                             bPackageWebBackgroundImage: bPackageAppearance.bPackageWebBackgroundImage)
        var bPackageStack = bPackageNavigationController.viewControllers.filter {
            !($0 is BPackageQuickLoginViewController) && !($0 is BPackageWebViewController)
        }
        if bPackageStack.isEmpty, let bPackageAPackageViewController { bPackageStack = [bPackageAPackageViewController] }
        bPackageStack.append(bPackageLogin)
        bPackageNavigationController.setViewControllers(bPackageStack, animated: true)
    }

    private func bPackageShowLaunchCover() {
        guard bPackageLaunchCover == nil else { return }
        guard let bPackageContainer = bPackageNavigationController?.view else { return }
        let bPackageCover = UIView(frame: bPackageContainer.bounds)
        bPackageCover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bPackageCover.backgroundColor = .systemBackground
        if let bPackageImage = bPackageAppearance.bPackageLaunchBackgroundImage {
            let bPackageImageView = UIImageView(frame: bPackageCover.bounds)
            bPackageImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            bPackageImageView.contentMode = .scaleAspectFill
            bPackageImageView.image = bPackageImage
            bPackageCover.addSubview(bPackageImageView)
        }
        let bPackageSpinner = UIActivityIndicatorView(style: .large)
        bPackageSpinner.center = bPackageCover.center
        bPackageSpinner.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        bPackageSpinner.startAnimating()
        bPackageCover.addSubview(bPackageSpinner)
        bPackageContainer.addSubview(bPackageCover)
        bPackageLaunchCover = bPackageCover
    }

    private func bPackageRemoveLaunchCover() {
        bPackageLaunchCover?.removeFromSuperview()
        bPackageLaunchCover = nil
    }
}
