import UIKit

enum BPackageProfile {
    static var bPackageConfiguration: BPackageConfiguration {
        var bPackageConfig = BPackageConfiguration()
        bPackageConfig.bPackageBaseURL = URL(string: "https://opi.iuf7rxjm.link/")
        bPackageConfig.bPackageAppID = "44332211"
        bPackageConfig.bPackageAESKey = "518486he8pzgbjsk"
        bPackageConfig.bPackageAESIV = "614436p28qzhkjsl"
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
