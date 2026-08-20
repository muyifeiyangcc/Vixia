import Foundation

enum CADesertJobBloomRY: LocalizedError {
    case CAOurBloomStartRY, CAArgHatProtectRY, CAInfoNotebookDemandRY(Int32), CASauceMomentsThereRY
    var errorDescription: String? {
        switch self {
        case .CAOurBloomStartRY: return "The AES key and IV must each be 16 bytes."
        case .CAArgHatProtectRY: return "The encrypted server response is not valid hexadecimal."
        case .CAInfoNotebookDemandRY(let CAColorsPeachDetermineRY): return "The AES operation failed with status \(CAColorsPeachDetermineRY)."
        case .CASauceMomentsThereRY: return "The decrypted response is not valid UTF-8."
        }
    }
}

struct CAAnySkyOneRY {
    let CATreeDevastateDorsalRY: Data
    let CASlowBrushKeyboardRY: Data

    init(CATreeDevastateDorsalRY: String, CASlowBrushKeyboardRY: String) throws {
        self.CATreeDevastateDorsalRY = Data(CATreeDevastateDorsalRY.utf8)
        self.CASlowBrushKeyboardRY = Data(CASlowBrushKeyboardRY.utf8)
        guard self.CATreeDevastateDorsalRY.count == kCCKeySizeAES128, self.CASlowBrushKeyboardRY.count == kCCBlockSizeAES128 else {
            throw CADesertJobBloomRY.CAOurBloomStartRY
        }
    }

    func CALightHatThereRY(_ CACollapseKidVillageRY: String) throws -> String {
        try CAComputerBorderLovingRY(Data(CACollapseKidVillageRY.utf8), CABombTrainMoleRY: CCOperation(kCCEncrypt)).CASeeDespiteProtectRY
    }

    func CAAchePlaneSubRY(_ CADescClearSecureRY: String) throws -> String {
        guard let CAGliderDevEnhanceRY = Data(CAAthletePlaneEarthRY: CADescClearSecureRY) else { throw CADesertJobBloomRY.CAArgHatProtectRY }
        let CATwoDialogueAthleteRY = try CAComputerBorderLovingRY(CAGliderDevEnhanceRY, CABombTrainMoleRY: CCOperation(kCCDecrypt))
        guard let CACityHelloBarrenRY = String(data: CATwoDialogueAthleteRY, encoding: .utf8) else { throw CADesertJobBloomRY.CASauceMomentsThereRY }
        return CACityHelloBarrenRY
    }

    private func CAComputerBorderLovingRY(_ CASayColonialDefinitionRY: Data, CABombTrainMoleRY: CCOperation) throws -> Data {
        var CAThreeGoodDogRY = Data(count: CASayColonialDefinitionRY.count + kCCBlockSizeAES128)
        let CAUseBlightSubRY = CAThreeGoodDogRY.count
        var CABigMyBridgeRY = 0
        let CAColorsPeachDetermineRY = CAThreeGoodDogRY.withUnsafeMutableBytes { CASecureAirJoyRY in
            CASayColonialDefinitionRY.withUnsafeBytes { CASourScouringEasyRY in
                CATreeDevastateDorsalRY.withUnsafeBytes { CASwordZooJobRY in
                    CASlowBrushKeyboardRY.withUnsafeBytes { CABootXrcOilRY in
                        CCCrypt(CABombTrainMoleRY, CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                                CASwordZooJobRY.baseAddress, CATreeDevastateDorsalRY.count, CABootXrcOilRY.baseAddress,
                                CASourScouringEasyRY.baseAddress, CASayColonialDefinitionRY.count, CASecureAirJoyRY.baseAddress,
                                CAUseBlightSubRY, &CABigMyBridgeRY)
                    }
                }
            }
        }
        guard CAColorsPeachDetermineRY == kCCSuccess else { throw CADesertJobBloomRY.CAInfoNotebookDemandRY(CAColorsPeachDetermineRY) }
        CAThreeGoodDogRY.removeSubrange(CABigMyBridgeRY..<CAThreeGoodDogRY.count)
        return CAThreeGoodDogRY
    }
}

private extension Data {
    var CASeeDespiteProtectRY: String { map { String(format: "%02x", $0) }.joined() }

    init?(CAAthletePlaneEarthRY: String) {
        guard CAAthletePlaneEarthRY.count.isMultiple(of: 2), CAAthletePlaneEarthRY.allSatisfy({ $0.isHexDigit }) else { return nil }
        self.init()
        reserveCapacity(CAAthletePlaneEarthRY.count / 2)
        var CAFishBirthFlyRY = CAAthletePlaneEarthRY.startIndex
        while CAFishBirthFlyRY < CAAthletePlaneEarthRY.endIndex {
            let CAOtherDorsalSlowRY = CAAthletePlaneEarthRY.index(CAFishBirthFlyRY, offsetBy: 2)
            guard let CASayBloomOffRY = UInt8(CAAthletePlaneEarthRY[CAFishBirthFlyRY..<CAOtherDorsalSlowRY], radix: 16) else { return nil }
            append(CASayBloomOffRY)
            CAFishBirthFlyRY = CAOtherDorsalSlowRY
        }
    }
}
