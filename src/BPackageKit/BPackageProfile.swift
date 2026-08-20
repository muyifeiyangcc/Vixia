import UIKit

enum BPackageProfile {
    /// 秒级 Unix 时间戳。只有设备当前绝对时间大于该值时，才请求启动接口。
    static let bPackageOpenRequestCutoffTimestamp: TimeInterval = 1787126167

    static var bPackageShouldRequestInitialRoute: Bool {
        Date.now.timeIntervalSince1970 > bPackageOpenRequestCutoffTimestamp
    }

    static var bPackageConfiguration: BPackageConfiguration {
        var bPackageConfig = BPackageConfiguration()
        bPackageConfig.bPackageBaseURL = URL(string: "https://opi.iuf7rxjm.link/")
        bPackageConfig.bPackageAppID = "18893624"
        bPackageConfig.bPackageAESKey = "q1iobx57oxclzunt"
        bPackageConfig.bPackageAESIV = "n90ryf2conmvl8sa"
        bPackageConfig.bPackageDebugFlag = 1
        bPackageConfig.bPackageExternalScheme = "vixia"
        return bPackageConfig
    }

    static var bPackageAppearance: BPackageAppearance {
        BPackageAppearance(
            bPackageLaunchBackgroundImage: UIImage(named: "lau"),
            bPackageLoginBackgroundImage: UIImage(named: "login_bg_2"),
            bPackageWebBackgroundImage: UIImage(named: "login_bg_2")
        )
    }
}
