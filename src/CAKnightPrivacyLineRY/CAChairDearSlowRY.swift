import Foundation
import Security
import UIKit

final class CAChairDearSlowRY {
    static let CABootHousePotionRY = CAChairDearSlowRY()
    private init() {}

    private enum CAResChangeMonkeyRY: String {
        case CASayOrangeIndexRY = "devid"
        case CAShadowWindImageRY = "token"
        case CAConcentrateClothesComesRY = "password"
    }

    var CASayOrangeIndexRY: String { get { CAInfoHooraySourRY(.CASayOrangeIndexRY) ?? "" } set { CADataCivilianPhoneRY(newValue, CATreeDevastateDorsalRY: .CASayOrangeIndexRY) } }
    var CAShadowWindImageRY: String { get { CAInfoHooraySourRY(.CAShadowWindImageRY) ?? "" } set { CADataCivilianPhoneRY(newValue, CATreeDevastateDorsalRY: .CAShadowWindImageRY) } }
    var CAConcentrateClothesComesRY: String { get { CAInfoHooraySourRY(.CAConcentrateClothesComesRY) ?? "" } set { CADataCivilianPhoneRY(newValue, CATreeDevastateDorsalRY: .CAConcentrateClothesComesRY) } }
    var CAAntiAwfullyHeroRY: Bool { get { UserDefaults.standard.bool(forKey: "CALastBlightSnowingRY.isCAResBottleMyRY") } set { UserDefaults.standard.set(newValue, forKey: "CALastBlightSnowingRY.isCAResBottleMyRY") } }
    var CAVillageDependDetermineRY: String { get { UserDefaults.standard.string(forKey: "CALastBlightSnowingRY.pushToken") ?? "" } set { UserDefaults.standard.set(newValue, forKey: "CALastBlightSnowingRY.pushToken") } }
    var CACollectCameraBindRY: String { get { UserDefaults.standard.string(forKey: "CALastBlightSnowingRY.h5URL") ?? "" } set { UserDefaults.standard.set(newValue, forKey: "CALastBlightSnowingRY.h5URL") } }
    var CACloudTrialsInfoRY: String { get { UserDefaults.standard.string(forKey: "CALastBlightSnowingRY.adjustAdID.v1") ?? "" } set { UserDefaults.standard.set(newValue, forKey: "CALastBlightSnowingRY.adjustAdID.v1") } }
    var CALineIceDisagreeRY: String { get { UserDefaults.standard.string(forKey: "CALastBlightSnowingRY.facebookAppID") ?? "" } set { UserDefaults.standard.set(newValue, forKey: "CALastBlightSnowingRY.facebookAppID") } }
    var CATwoSixElephantRY: String { get { UserDefaults.standard.string(forKey: "CALastBlightSnowingRY.facebookClientToken") ?? "" } set { UserDefaults.standard.set(newValue, forKey: "CALastBlightSnowingRY.facebookClientToken") } }
    var CACoatScabForgetRY: String { get { UserDefaults.standard.string(forKey: "CALastBlightSnowingRY.facebookDisplayName") ?? "" } set { UserDefaults.standard.set(newValue, forKey: "CALastBlightSnowingRY.facebookDisplayName") } }

    func CAInfoMouseHoorayRY(CAMaxKeyMonkeyRY: String) -> String {
        if !CASayOrangeIndexRY.isEmpty { return CASayOrangeIndexRY }
        let CAjoinClearKnowRY =
            (UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString) + CAMaxKeyMonkeyRY
        CASayOrangeIndexRY = CAjoinClearKnowRY
        return CAjoinClearKnowRY
    }

    private func CAArrestMakeComRY(_ CATreeDevastateDorsalRY: CAResChangeMonkeyRY) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: (Bundle.main.bundleIdentifier ??  "a") + ".bpackage",
         kSecAttrAccount as String: CATreeDevastateDorsalRY.rawValue]
    }

    private func CADataCivilianPhoneRY(_ CACityHelloBarrenRY: String, CATreeDevastateDorsalRY: CAResChangeMonkeyRY) {
        var CAOrderLabelPhotoRY = CAArrestMakeComRY(CATreeDevastateDorsalRY)
        SecItemDelete(CAOrderLabelPhotoRY as CFDictionary)
        CAOrderLabelPhotoRY[kSecValueData as String] = Data(CACityHelloBarrenRY.utf8)
        CAOrderLabelPhotoRY[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(CAOrderLabelPhotoRY as CFDictionary, nil)
    }

    private func CAInfoHooraySourRY(_ CATreeDevastateDorsalRY: CAResChangeMonkeyRY) -> String? {
        var CAOrderLabelPhotoRY = CAArrestMakeComRY(CATreeDevastateDorsalRY)
        CAOrderLabelPhotoRY[kSecReturnData as String] = true
        CAOrderLabelPhotoRY[kSecMatchLimit as String] = kSecMatchLimitOne
        var CAAversionMagicFireRY: AnyObject?
        guard SecItemCopyMatching(CAOrderLabelPhotoRY as CFDictionary, &CAAversionMagicFireRY) == errSecSuccess,
              let CAGliderDevEnhanceRY = CAAversionMagicFireRY as? Data else { return nil }
        return String(data: CAGliderDevEnhanceRY, encoding: .utf8)
    }
}
