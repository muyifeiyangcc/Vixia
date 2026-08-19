#if canImport(AdjustSdk)
import AdjustSdk
#endif
import FBSDKCoreKit
import Foundation
import UIKit

final class APackageBAnalyticsAdapter: BPackageAnalyticsAdapter {
    static let bPackageShared = APackageBAnalyticsAdapter()

    private let bPackageLock = NSLock()
    private var bPackageStoredAdjustAdID = ""
    private var bPackageStoredAttributionResult = ""
    private var bPackageDidInitializeFacebook = false

    private init() {}

    var bPackageAdjustAdID: String {
        bPackageLock.lock()
        defer { bPackageLock.unlock() }
        return bPackageStoredAdjustAdID
    }

    var bPackageAttributionResult: String {
        bPackageLock.lock()
        defer { bPackageLock.unlock() }
        return bPackageStoredAttributionResult
    }

    func bPackageUpdateAttribution(bPackageAttribution: ADJAttribution?, bPackageAdID: String) {
        let bPackageResult = bPackageAttributionJSON(bPackageAttribution)
        bPackageLock.lock()
        bPackageStoredAdjustAdID = bPackageAdID
        bPackageStoredAttributionResult = bPackageResult
        bPackageLock.unlock()

        BPackageLogger.bPackageShared.bPackageLog(
            "Adjust",
            "收到归因回调，adid=\(bPackageAdID.isEmpty ? "空" : "非空")，ajResult=\(bPackageResult.isEmpty ? "空字符串" : "非空")"
        )
    }

    func bPackageAttributionJSON(_ bPackageAttribution: ADJAttribution?) -> String {
        guard let bPackageAttribution else { return "" }
        let bPackageObject: [String: Any] = [
            "trackerToken": bPackageAttribution.trackerToken ?? "",
            "trackerName": bPackageAttribution.trackerName ?? "",
            "network": bPackageAttribution.network ?? "",
            "campaign": bPackageAttribution.campaign ?? "",
            "adgroup": bPackageAttribution.adgroup ?? "",
            "creative": bPackageAttribution.creative ?? "",
            "clickLabel": bPackageAttribution.clickLabel ?? "",
            "costType": bPackageAttribution.costType ?? "",
            "costAmount": bPackageAttribution.costAmount ?? 0,
            "costCurrency": bPackageAttribution.costCurrency ?? ""
        ]
        guard JSONSerialization.isValidJSONObject(bPackageObject),
              let bPackageData = try? JSONSerialization.data(withJSONObject: bPackageObject, options: [.sortedKeys]) else {
            return ""
        }
        return String(decoding: bPackageData, as: UTF8.self)
    }

    func bPackageTrackAdjustEvent(_ bPackageType: BPackageEventType,
                                  bPackageAmount: Decimal?,
                                  bPackageCurrency: String?) {
        let bPackageToken: String
        let bPackageEventName: String
        switch bPackageType {
        case .bPackageInstall:
            bPackageToken = BPackageThirdPartyProfile.bPackageInstallEventToken
            bPackageEventName = BPackageThirdPartyProfile.bPackageInstallEventName
        case .bPackageInitiateCheckout:
            BPackageLogger.bPackageShared.bPackageLog(
                "Adjust",
                "InitiateCheckout 按最新规则不发送 Adjust SDK，只调用后端 ...j"
            )
            return
        case .bPackagePurchase:
            bPackageToken = BPackageThirdPartyProfile.bPackagePurchaseEventToken
            bPackageEventName = BPackageThirdPartyProfile.bPackagePurchaseEventName
        }

        guard let bPackageEvent = ADJEvent(eventToken: bPackageToken) else {
            BPackageLogger.bPackageShared.bPackageLog("Adjust", "无法创建 \(bPackageEventName) 事件")
            return
        }
        if bPackageType == .bPackagePurchase {
            guard let bPackageAmount,
                  let bPackageCurrency,
                  !bPackageCurrency.isEmpty else {
                BPackageLogger.bPackageShared.bPackageLog("Adjust", "Purchase 缺少 StoreKit 实际金额或币种，已拒绝发送")
                return
            }
            bPackageEvent.setRevenue(
                NSDecimalNumber(decimal: bPackageAmount).doubleValue,
                currency: bPackageCurrency
            )
        }
        Adjust.trackEvent(bPackageEvent)
        BPackageLogger.bPackageShared.bPackageLog("Adjust", "已发送 SDK 事件 \(bPackageEventName)")
    }

    @MainActor
    func bPackageInitializeFacebook(
        bPackageApplication: UIApplication,
        bPackageLaunchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        guard !bPackageDidInitializeFacebook else { return }
        let bPackageStorage = BPackageStorage.bPackageShared
        if bPackageStorage.bPackageFacebookAppID.isEmpty {
            bPackageStorage.bPackageFacebookAppID = BPackageThirdPartyProfile.bPackageFacebookAppID
        }
        if bPackageStorage.bPackageFacebookClientToken.isEmpty {
            bPackageStorage.bPackageFacebookClientToken = BPackageThirdPartyProfile.bPackageFacebookClientToken
        }
        if bPackageStorage.bPackageFacebookDisplayName.isEmpty {
            bPackageStorage.bPackageFacebookDisplayName = BPackageThirdPartyProfile.bPackageFacebookDisplayName
        }

        let bPackageSettings = Settings.shared
        bPackageSettings.appID = bPackageStorage.bPackageFacebookAppID
        bPackageSettings.clientToken = bPackageStorage.bPackageFacebookClientToken
        bPackageSettings.displayName = bPackageStorage.bPackageFacebookDisplayName
        bPackageSettings.isAutoLogAppEventsEnabled = true
        ApplicationDelegate.shared.application(
            bPackageApplication,
            didFinishLaunchingWithOptions: bPackageLaunchOptions
        )
        bPackageDidInitializeFacebook = true
        BPackageLogger.bPackageShared.bPackageLog(
            "Facebook",
            "已使用持久化配置初始化 SDK"
        )
    }

    func bPackageTrackFacebookPurchase(bPackageAmount: Decimal, bPackageCurrency: String) {
        guard bPackageDidInitializeFacebook else {
            BPackageLogger.bPackageShared.bPackageLog("Facebook", "SDK 尚未初始化，Purchase 未发送")
            return
        }
        AppEvents.shared.logPurchase(
            amount: NSDecimalNumber(decimal: bPackageAmount).doubleValue,
            currency: bPackageCurrency,
            parameters: [AppEvents.ParameterName("fb_mobile_purchase"): "true"]
        )
        BPackageLogger.bPackageShared.bPackageLog(
            "Facebook",
            "已发送 Purchase，金额=\(bPackageAmount)，币种=\(bPackageCurrency)"
        )
    }
}
