import Foundation
import StoreKit

final class StoreKit1PurchaseManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    static let CABootHousePotionRY = StoreKit1PurchaseManager()

    enum CAComesOrXinRY {
        case CAAngerNetDarlingRY(String)
        case CATerBloomLovingRY(String)
        case CAMaxTheCoffeeRY(String)
        case CAWindowPictureTreeRY
    }

    private struct CASixCallLightRY: Codable {
        let CAHorseIndexPlaneRY: String
        let CARoadBorderComesRY: String
        var CALiefMoleAlterRY: String?
        var CANightAnimalAnyRY: String?
    }

    private var CAMomentsTeacherDesertRY: ((CAComesOrXinRY) -> Void)?
    private var CABessHaveFuncRY: CAEraserPresentBikeRY?
    private var CADepictDirectorChapterRY: CAComPickMomentRY?
    private var CAMagicBlindBorderRY: SKProductsRequest?
    private var CAElephantScabConsRY: SKReceiptRefreshRequest?
    private var CAMoleChapterDisagreeRY: [SKPaymentTransaction] = []
    private var CASwapAwfullyBiologicalRY = Set<String>()
    private let CAMirrorDestroySeedRY = "CALastBlightSnowingRY.storeKit1.pendingPaymentContext"
    private let CABlightTreeComRY = "CALastBlightSnowingRY.storeKit1.ownedProductIDs"

    private override init() { super.init() }

    func CASpellBrushSecureRY() {
        SKPaymentQueue.default().add(self)
    }

    func CAFlatSupportAngerRY() { SKPaymentQueue.default().remove(self) }

    func CABessYunUseRY(CABessHaveFuncRY: CAEraserPresentBikeRY,
                           CADepictDirectorChapterRY: CAComPickMomentRY,
                           CAMomentsTeacherDesertRY: @escaping (CAComesOrXinRY) -> Void) {
        self.CABessHaveFuncRY = CABessHaveFuncRY
        self.CADepictDirectorChapterRY = CADepictDirectorChapterRY
        self.CAMomentsTeacherDesertRY = CAMomentsTeacherDesertRY
        SKPaymentQueue.default().transactions
            .filter {
                CAAntiPhonePlaneRY($0.payment.productIdentifier) &&
                ($0.transactionState == .purchased || $0.transactionState == .restored)
            }
            .forEach(CADialectLovingSalarRY)
    }

    func CAPigShoesTracksRY() { CAMomentsTeacherDesertRY = nil }

    func CACollapseDemonstrateBessRY(CAHorseIndexPlaneRY: String, CARoadBorderComesRY: String) {
        guard !CAHorseIndexPlaneRY.isEmpty else { CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The product ID is missing.")); return }
        guard !CARoadBorderComesRY.isEmpty else { CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The order number is missing.")); return }
        guard SKPaymentQueue.canMakePayments() else { CASwapOrderSalarRY(.CAMaxTheCoffeeRY("In-App Purchases are not allowed on this device.")); return }
        guard SKPaymentQueue.default().transactions.allSatisfy({ $0.transactionState != .purchasing && $0.transactionState != .deferred }) else {
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("Another payment is already in progress.")); return
        }
        CAUpCallAppleRY(CAHorseIndexPlaneRY)
        CACatCanConsRY(CASixCallLightRY(CAHorseIndexPlaneRY: CAHorseIndexPlaneRY,
                                                   CARoadBorderComesRY: CARoadBorderComesRY,
                                                   CALiefMoleAlterRY: nil,
                                                   CANightAnimalAnyRY: nil))
        CASwapOrderSalarRY(.CAAngerNetDarlingRY("Loading product information…"))
        let CADetectScouringThereRY = SKProductsRequest(productIdentifiers: [CAHorseIndexPlaneRY])
        CAMagicBlindBorderRY = CADetectScouringThereRY
        CADetectScouringThereRY.delegate = self
        CADetectScouringThereRY.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        CAMagicBlindBorderRY = nil
        guard var CAHugWithClothesRY = CAOrderBiteBlindRY(),
              let CACharacterCollectZeroRY = response.products.first(where: { $0.productIdentifier == CAHugWithClothesRY.CAHorseIndexPlaneRY }) else {
            let CABloomVillageMomentsRY = response.invalidProductIdentifiers.joined(separator: ",")
            CATerDisShadowRY()
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The App Store product was not found. Invalid product ID: \(CABloomVillageMomentsRY)"))
            return
        }
        guard let CANightAnimalAnyRY = CACharacterCollectZeroRY.priceLocale.currencyCode,
              !CANightAnimalAnyRY.isEmpty else {
            CATerDisShadowRY()
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The App Store did not return a valid currency."))
            return
        }
        CAHugWithClothesRY.CALiefMoleAlterRY = CACharacterCollectZeroRY.price.stringValue
        CAHugWithClothesRY.CANightAnimalAnyRY = CANightAnimalAnyRY
        CACatCanConsRY(CAHugWithClothesRY)
        let CASelectDateDownRY = SKMutablePayment(product: CACharacterCollectZeroRY)
        CASelectDateDownRY.quantity = 1
        CASwapOrderSalarRY(.CAAngerNetDarlingRY("Waiting for payment confirmation…"))
        SKPaymentQueue.default().add(CASelectDateDownRY)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request === CAElephantScabConsRY {
            CAElephantScabConsRY = nil
            CAMoleChapterDisagreeRY.removeAll()
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("Unable to refresh the App Store receipt. Please try again later."))
        } else {
            CAMagicBlindBorderRY = nil
            CATerDisShadowRY()
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("Unable to load the App Store product. Please try again later."))
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        guard request === CAElephantScabConsRY else { return }
        CAElephantScabConsRY = nil
        let CACountBindAsleepRY = CAMoleChapterDisagreeRY
        CAMoleChapterDisagreeRY.removeAll()
        CACountBindAsleepRY.forEach(CADialectLovingSalarRY)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for CAPlaneAthleteMetalRY in transactions {
            guard CAAntiPhonePlaneRY(CAPlaneAthleteMetalRY.payment.productIdentifier) else {
                continue
            }
            switch CAPlaneAthleteMetalRY.transactionState {
            case .purchasing:
                CASwapOrderSalarRY(.CAAngerNetDarlingRY("Processing payment…"))
            case .deferred:
                CASwapOrderSalarRY(.CAAngerNetDarlingRY("Payment is awaiting approval…"))
            case .purchased, .restored:
                CADialectLovingSalarRY(CAPlaneAthleteMetalRY)
            case .failed:
                let CAAirPaintAcheRY = CAPlaneAthleteMetalRY.error as NSError?
                queue.finishTransaction(CAPlaneAthleteMetalRY)
                CATerDisShadowRY()
                if CAAirPaintAcheRY?.domain == SKErrorDomain, CAAirPaintAcheRY?.code == SKError.paymentCancelled.rawValue {
                    CASwapOrderSalarRY(.CAWindowPictureTreeRY)
                } else {
                    CASwapOrderSalarRY(.CAMaxTheCoffeeRY("Payment failed. Please try again later."))
                }
            @unknown default:
                CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The App Store returned an unknown transaction state."))
            }
        }
    }

    private func CADialectLovingSalarRY(_ CAPlaneAthleteMetalRY: SKPaymentTransaction) {
        guard let CADepictDreamsArsenalRY = CAPlaneAthleteMetalRY.transactionIdentifier, !CADepictDreamsArsenalRY.isEmpty else {
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The App Store did not return a transaction identifier. The transaction will be retried later.")); return
        }
        guard !CASwapAwfullyBiologicalRY.contains(CADepictDreamsArsenalRY) else { return }
        guard let CABessHaveFuncRY else { return }
        guard let CAHugWithClothesRY = CAOrderBiteBlindRY() else {
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The order number is missing. Verification will be retried later.")); return
        }
        guard CAHugWithClothesRY.CAHorseIndexPlaneRY == CAPlaneAthleteMetalRY.payment.productIdentifier else {
            CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The purchased product does not match the order. Verification will be retried later.")); return
        }
        guard let CAArrestScreenOrangeRY = CAAmongBudgetVcRY() else {
            if !CAMoleChapterDisagreeRY.contains(where: { $0 === CAPlaneAthleteMetalRY }) { CAMoleChapterDisagreeRY.append(CAPlaneAthleteMetalRY) }
            if CAElephantScabConsRY == nil {
                CASwapOrderSalarRY(.CAAngerNetDarlingRY("Refreshing the App Store receipt…"))
                let CADetectScouringThereRY = SKReceiptRefreshRequest()
                CAElephantScabConsRY = CADetectScouringThereRY
                CADetectScouringThereRY.delegate = self
                CADetectScouringThereRY.start()
            }
            return
        }
        let CADevChapterLaptopRY = CAHaveSchoolBootRY(CARoadBorderComesRY: CAHugWithClothesRY.CARoadBorderComesRY)
        CASwapAwfullyBiologicalRY.insert(CADepictDreamsArsenalRY)
        CASwapOrderSalarRY(.CAAngerNetDarlingRY("Payment completed. Verifying purchase…"))
        Task {
            do {
                try await CABessHaveFuncRY.CAXinToolDeficitRY(CADepictDreamsArsenalRY: CADepictDreamsArsenalRY,
                                                            CAArrestScreenOrangeRY: CAArrestScreenOrangeRY,
                                                            CADevChapterLaptopRY: CADevChapterLaptopRY)
                await MainActor.run {
                    self.CASwapAwfullyBiologicalRY.remove(CADepictDreamsArsenalRY)
                    guard let CABloomTameMsgRY = CAHugWithClothesRY.CALiefMoleAlterRY,
                          let CALiefMoleAlterRY = Decimal(string: CABloomTameMsgRY),
                          let CANightAnimalAnyRY = CAHugWithClothesRY.CANightAnimalAnyRY,
                          !CANightAnimalAnyRY.isEmpty else {
                        self.CASwapOrderSalarRY(.CAMaxTheCoffeeRY("The purchase was verified, but its price or currency is missing. The transaction will be retried later."))
                        return
                    }
                    self.CADepictDirectorChapterRY?.CASauceTigerIdahoRY(
                        CALiefMoleAlterRY: CALiefMoleAlterRY,
                        CANightAnimalAnyRY: CANightAnimalAnyRY
                    )
                    SKPaymentQueue.default().finishTransaction(CAPlaneAthleteMetalRY)
                    self.CATerDisShadowRY()
                    self.CASwapOrderSalarRY(.CATerBloomLovingRY("Payment successful"))
                }
            } catch {
                await MainActor.run {
                    self.CASwapAwfullyBiologicalRY.remove(CADepictDreamsArsenalRY)
                    self.CASwapOrderSalarRY(.CAMaxTheCoffeeRY("Payment completed, but verification failed.\nThe transaction will be retried later."))
                }
            }
        }
    }

    private func CAAmongBudgetVcRY() -> String? {
        guard let CAPantsOptionLiefRY = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: CAPantsOptionLiefRY.path),
              let CAGliderDevEnhanceRY = try? Data(contentsOf: CAPantsOptionLiefRY), !CAGliderDevEnhanceRY.isEmpty else { return nil }
        return CAGliderDevEnhanceRY.base64EncodedString()
    }

    private func CAHaveSchoolBootRY(CARoadBorderComesRY: String) -> String {
        guard let CAGliderDevEnhanceRY = try? JSONSerialization.data(withJSONObject: ["orderCode": CARoadBorderComesRY], options: [.sortedKeys]) else { return "" }
        return String(decoding: CAGliderDevEnhanceRY, as: UTF8.self)
    }

    private func CACatCanConsRY(_ CACityHelloBarrenRY: CASixCallLightRY) {
        if let CAGliderDevEnhanceRY = try? JSONEncoder().encode(CACityHelloBarrenRY) {
            UserDefaults.standard.set(CAGliderDevEnhanceRY, forKey: CAMirrorDestroySeedRY)
        }
    }

    private func CAOrderBiteBlindRY() -> CASixCallLightRY? {
        guard let CAGliderDevEnhanceRY = UserDefaults.standard.data(forKey: CAMirrorDestroySeedRY) else { return nil }
        return try? JSONDecoder().decode(CASixCallLightRY.self, from: CAGliderDevEnhanceRY)
    }

    private func CATerDisShadowRY() { UserDefaults.standard.removeObject(forKey: CAMirrorDestroySeedRY) }

    func CAAntiPhonePlaneRY(_ CAMakeLovingCarRY: String) -> Bool {
        let CAHoorayDemonstrateEasyRY = UserDefaults.standard.stringArray(forKey: CABlightTreeComRY) ?? []
        return CAHoorayDemonstrateEasyRY.contains(CAMakeLovingCarRY)
    }

    private func CAUpCallAppleRY(_ CAMakeLovingCarRY: String) {
        var CAHoorayDemonstrateEasyRY = UserDefaults.standard.stringArray(forKey: CABlightTreeComRY) ?? []
        guard !CAHoorayDemonstrateEasyRY.contains(CAMakeLovingCarRY) else { return }
        CAHoorayDemonstrateEasyRY.append(CAMakeLovingCarRY)
        UserDefaults.standard.set(CAHoorayDemonstrateEasyRY, forKey: CABlightTreeComRY)
    }

    private func CASwapOrderSalarRY(_ CAGliderZooGliderRY: CAComesOrXinRY) {
        DispatchQueue.main.async { [weak self] in self?.CAMomentsTeacherDesertRY?(CAGliderZooGliderRY) }
    }
}
