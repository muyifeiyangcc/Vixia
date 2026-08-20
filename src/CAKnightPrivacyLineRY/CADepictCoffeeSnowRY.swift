import Foundation

/// Implement and inject this protocol when the host app already owns the Adjust and Facebook SDKs.
protocol CAInGliderCryRY: AnyObject {
    var CACloudTrialsInfoRY: String { get }
    var CAResWinDialectRY: String { get }
    func CAAnyJumpMuchRY() async -> String
    func CAInfoBessMouseRY(_ CADevastateHoorayMinRY: CAThanMorningClothesRY,
                                  CALiefMoleAlterRY: Decimal?,
                                  CANightAnimalAnyRY: String?)
    func CAOilReadFlowerRY(CALiefMoleAlterRY: Decimal, CANightAnimalAnyRY: String)
}

/// Shared by demo and production startup paths to bind Adjust attribution to the current reporter.
protocol CADogMaxMoonRY: AnyObject {
    func CASpellWinPotionRY(_ CADearJumpJuiceRY: CAComPickMomentRY)
}

final class CAPigNetPlaneRY: CAInGliderCryRY {
    var CACloudTrialsInfoRY: String { "" }
    var CAResWinDialectRY: String { "" }
    func CAAnyJumpMuchRY() async -> String { "" }
    func CAInfoBessMouseRY(_ CADevastateHoorayMinRY: CAThanMorningClothesRY,
                                  CALiefMoleAlterRY: Decimal?,
                                  CANightAnimalAnyRY: String?) {}
    func CAOilReadFlowerRY(CALiefMoleAlterRY: Decimal, CANightAnimalAnyRY: String) {}
}

final class CAComPickMomentRY {
    private let CABessHaveFuncRY: CAEraserPresentBikeRY
    private weak var CADevBusJumpRY: CAInGliderCryRY?
    // A versioned key prevents stale demo state from suppressing a new attribution callback.
    private let CAAnimalComeSixRY = "CALastBlightSnowingRY.adjust.installAttributionReported.v2"

    init(CABessHaveFuncRY: CAEraserPresentBikeRY, CADevBusJumpRY: CAInGliderCryRY) {
        self.CABessHaveFuncRY = CABessHaveFuncRY
        self.CADevBusJumpRY = CADevBusJumpRY
    }

    /// Call only from AppDelegate.adjustAttributionChanged, never from the normal startup path.
    func CAHorseScabDataRY(CAAversionMagicFireRY: String?, CACopperMoleBigRY: String) {
        guard !UserDefaults.standard.bool(forKey: CAAnimalComeSixRY) else { return }
        UserDefaults.standard.set(true, forKey: CAAnimalComeSixRY)
        let CATipJumpCopperRY = CAAversionMagicFireRY?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        CADevBusJumpRY?.CAInfoBessMouseRY(.CADelRainDorsalRY,
                                                  CALiefMoleAlterRY: nil,
                                                  CANightAnimalAnyRY: nil)
        CABusyBoomSoleRY(CADevastateHoorayMinRY: .CADelRainDorsalRY,
                           CAAversionMagicFireRY: CATipJumpCopperRY,
                           CACopperMoleBigRY: CACopperMoleBigRY)
    }

    func CABiologicalDorsalLeaveRY(_ CADevastateHoorayMinRY: CAThanMorningClothesRY,
                        CALiefMoleAlterRY: Decimal? = nil,
                        CANightAnimalAnyRY: String? = nil) {
        let CACopperMoleBigRY = CADevBusJumpRY?.CACloudTrialsInfoRY ?? ""
        let CAAversionMagicFireRY = CADevBusJumpRY?.CAResWinDialectRY.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        CADevBusJumpRY?.CAInfoBessMouseRY(CADevastateHoorayMinRY,
                                                  CALiefMoleAlterRY: CALiefMoleAlterRY,
                                                  CANightAnimalAnyRY: CANightAnimalAnyRY)
        CABusyBoomSoleRY(CADevastateHoorayMinRY: CADevastateHoorayMinRY,
                           CAAversionMagicFireRY: CAAversionMagicFireRY,
                           CACopperMoleBigRY: CACopperMoleBigRY)
    }

    private func CABusyBoomSoleRY(CADevastateHoorayMinRY: CAThanMorningClothesRY,
                                    CAAversionMagicFireRY: String,
                                    CACopperMoleBigRY: String) {
        Task { [weak CADevBusJumpRY] in
            let CACanIronTwoRY: String
            if CACopperMoleBigRY.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                CACanIronTwoRY = await CADevBusJumpRY?.CAAnyJumpMuchRY() ?? ""
            } else {
                CACanIronTwoRY = CACopperMoleBigRY
            }
            guard !CACanIronTwoRY.isEmpty else { return }
            try? await CABessHaveFuncRY.CADolphinAnyLiefRY(CAAversionMagicFireRY: CAAversionMagicFireRY,
                                                           CADevastateHoorayMinRY: CADevastateHoorayMinRY,
                                                           CACopperMoleBigRY: CACanIronTwoRY)
        }
    }

    func CASauceTigerIdahoRY(CALiefMoleAlterRY: Decimal, CANightAnimalAnyRY: String) {
        CABiologicalDorsalLeaveRY(.CACollapseDemonstrateBessRY,
                       CALiefMoleAlterRY: CALiefMoleAlterRY,
                       CANightAnimalAnyRY: CANightAnimalAnyRY)
        CADevBusJumpRY?.CAOilReadFlowerRY(CALiefMoleAlterRY: CALiefMoleAlterRY,
                                                       CANightAnimalAnyRY: CANightAnimalAnyRY)
    }
}
