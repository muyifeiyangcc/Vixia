import Foundation
import StoreKit

final class StoreKit1PurchaseManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    static let bPackageShared = StoreKit1PurchaseManager()

    enum BPackageState {
        case bPackageLoading(String)
        case bPackageSuccess(String)
        case bPackageFailure(String)
        case bPackageCancelled
    }

    private struct BPackagePaymentContext: Codable {
        let bPackageBatchNo: String
        let bPackageOrderCode: String
        var bPackageAmount: String?
        var bPackageCurrency: String?
    }

    private var bPackageOnStateChange: ((BPackageState) -> Void)?
    private var bPackageAPI: BPackageAPIClient?
    private var bPackageEventReporter: BPackageEventReporter?
    private var bPackageProductRequest: SKProductsRequest?
    private var bPackageReceiptRefreshRequest: SKReceiptRefreshRequest?
    private var bPackageWaitingForReceipt: [SKPaymentTransaction] = []
    private var bPackageProcessingTransactions = Set<String>()
    private let bPackageContextKey = "bPackage.storeKit1.pendingPaymentContext"
    private let bPackageOwnedProductIDsKey = "bPackage.storeKit1.ownedProductIDs"

    private override init() { super.init() }

    func bPackageStartObserving() {
        SKPaymentQueue.default().add(self)
        BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "交易观察者已在 App 启动时注册")
    }

    func bPackageStopObserving() { SKPaymentQueue.default().remove(self) }

    func bPackageConfigure(bPackageAPI: BPackageAPIClient,
                           bPackageEventReporter: BPackageEventReporter,
                           bPackageOnStateChange: @escaping (BPackageState) -> Void) {
        self.bPackageAPI = bPackageAPI
        self.bPackageEventReporter = bPackageEventReporter
        self.bPackageOnStateChange = bPackageOnStateChange
        SKPaymentQueue.default().transactions
            .filter {
                bPackageOwnsProductIdentifier($0.payment.productIdentifier) &&
                ($0.transactionState == .purchased || $0.transactionState == .restored)
            }
            .forEach(bPackageProcessPurchasedTransaction)
    }

    func bPackageDetachUI() { bPackageOnStateChange = nil }

    func bPackagePurchase(bPackageBatchNo: String, bPackageOrderCode: String) {
        guard !bPackageBatchNo.isEmpty else { bPackageNotify(.bPackageFailure("H5 batchNo 为空，无法查询商品")); return }
        guard !bPackageOrderCode.isEmpty else { bPackageNotify(.bPackageFailure("H5 orderCode 为空，无法生成 callbackResult")); return }
        guard SKPaymentQueue.canMakePayments() else { bPackageNotify(.bPackageFailure("当前设备不允许 App 内购买")); return }
        guard SKPaymentQueue.default().transactions.allSatisfy({ $0.transactionState != .purchasing && $0.transactionState != .deferred }) else {
            bPackageNotify(.bPackageFailure("已有一笔支付正在处理中，请勿重复发起")); return
        }
        bPackageRememberOwnedProductID(bPackageBatchNo)
        bPackageSaveContext(BPackagePaymentContext(bPackageBatchNo: bPackageBatchNo,
                                                   bPackageOrderCode: bPackageOrderCode,
                                                   bPackageAmount: nil,
                                                   bPackageCurrency: nil))
        bPackageNotify(.bPackageLoading("正在获取商品信息…"))
        BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "查询 BPackage 商品 Product ID=\(bPackageBatchNo)")
        let bPackageRequest = SKProductsRequest(productIdentifiers: [bPackageBatchNo])
        bPackageProductRequest = bPackageRequest
        bPackageRequest.delegate = self
        bPackageRequest.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        bPackageProductRequest = nil
        guard var bPackageContext = bPackageLoadContext(),
              let bPackageProduct = response.products.first(where: { $0.productIdentifier == bPackageContext.bPackageBatchNo }) else {
            let bPackageInvalid = response.invalidProductIdentifiers.joined(separator: ",")
            bPackageClearContext()
            bPackageNotify(.bPackageFailure("未找到 App Store 商品。无效商品ID：\(bPackageInvalid)"))
            return
        }
        guard let bPackageCurrency = bPackageProduct.priceLocale.currencyCode,
              !bPackageCurrency.isEmpty else {
            bPackageClearContext()
            bPackageNotify(.bPackageFailure("App Store 商品未返回有效币种，无法安全上报 Purchase"))
            return
        }
        bPackageContext.bPackageAmount = bPackageProduct.price.stringValue
        bPackageContext.bPackageCurrency = bPackageCurrency
        bPackageSaveContext(bPackageContext)
        let bPackagePayment = SKMutablePayment(product: bPackageProduct)
        bPackagePayment.quantity = 1
        bPackageNotify(.bPackageLoading("等待用户确认支付…"))
        BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "商品查询成功：\(bPackageProduct.productIdentifier)，价格=\(bPackageProduct.price)，加入支付队列")
        SKPaymentQueue.default().add(bPackagePayment)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request === bPackageReceiptRefreshRequest {
            bPackageReceiptRefreshRequest = nil
            bPackageWaitingForReceipt.removeAll()
            bPackageNotify(.bPackageFailure("刷新 App Store Receipt 失败：\(error.localizedDescription)。交易未 finish"))
        } else {
            bPackageProductRequest = nil
            bPackageClearContext()
            bPackageNotify(.bPackageFailure("查询 App Store 商品失败：\(error.localizedDescription)"))
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        guard request === bPackageReceiptRefreshRequest else { return }
        bPackageReceiptRefreshRequest = nil
        let bPackageTransactions = bPackageWaitingForReceipt
        bPackageWaitingForReceipt.removeAll()
        BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "Receipt 刷新完成，继续验单")
        bPackageTransactions.forEach(bPackageProcessPurchasedTransaction)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for bPackageTransaction in transactions {
            guard bPackageOwnsProductIdentifier(bPackageTransaction.payment.productIdentifier) else {
                continue
            }
            switch bPackageTransaction.transactionState {
            case .purchasing:
                bPackageNotify(.bPackageLoading("正在支付…"))
            case .deferred:
                bPackageNotify(.bPackageLoading("支付等待批准…"))
            case .purchased, .restored:
                bPackageProcessPurchasedTransaction(bPackageTransaction)
            case .failed:
                let bPackageError = bPackageTransaction.error as NSError?
                queue.finishTransaction(bPackageTransaction)
                bPackageClearContext()
                if bPackageError?.domain == SKErrorDomain, bPackageError?.code == SKError.paymentCancelled.rawValue {
                    BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "用户取消支付")
                    bPackageNotify(.bPackageCancelled)
                } else {
                    bPackageNotify(.bPackageFailure("支付失败：\(bPackageTransaction.error?.localizedDescription ?? "未知错误")"))
                }
            @unknown default:
                bPackageNotify(.bPackageFailure("收到未知 StoreKit 交易状态"))
            }
        }
    }

    private func bPackageProcessPurchasedTransaction(_ bPackageTransaction: SKPaymentTransaction) {
        guard let bPackageTransactionID = bPackageTransaction.transactionIdentifier, !bPackageTransactionID.isEmpty else {
            bPackageNotify(.bPackageFailure("StoreKit 未返回 transactionIdentifier，交易暂不 finish")); return
        }
        guard !bPackageProcessingTransactions.contains(bPackageTransactionID) else { return }
        guard let bPackageAPI else {
            BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "验单接口尚未配置，保留交易")
            return
        }
        guard let bPackageContext = bPackageLoadContext() else {
            bPackageNotify(.bPackageFailure("缺少 H5 orderCode，无法验单；交易未 finish")); return
        }
        guard bPackageContext.bPackageBatchNo == bPackageTransaction.payment.productIdentifier else {
            bPackageNotify(.bPackageFailure("交易商品与 batchNo 不一致；交易未 finish")); return
        }
        guard let bPackageReceipt = bPackageReadReceipt() else {
            if !bPackageWaitingForReceipt.contains(where: { $0 === bPackageTransaction }) { bPackageWaitingForReceipt.append(bPackageTransaction) }
            if bPackageReceiptRefreshRequest == nil {
                bPackageNotify(.bPackageLoading("正在刷新 App Store Receipt…"))
                let bPackageRequest = SKReceiptRefreshRequest()
                bPackageReceiptRefreshRequest = bPackageRequest
                bPackageRequest.delegate = self
                bPackageRequest.start()
            }
            return
        }
        let bPackageCallbackResult = bPackageMakeCallbackResult(bPackageOrderCode: bPackageContext.bPackageOrderCode)
        bPackageProcessingTransactions.insert(bPackageTransactionID)
        bPackageNotify(.bPackageLoading("支付成功，正在服务端验单…"))
        BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "调用 3.2.5 验单；收据与订单信息已脱敏")
        Task {
            do {
                try await bPackageAPI.bPackageVerifyPayment(bPackageTransactionID: bPackageTransactionID,
                                                            bPackageReceipt: bPackageReceipt,
                                                            bPackageCallbackResult: bPackageCallbackResult)
                await MainActor.run {
                    self.bPackageProcessingTransactions.remove(bPackageTransactionID)
                    guard let bPackageAmountText = bPackageContext.bPackageAmount,
                          let bPackageAmount = Decimal(string: bPackageAmountText),
                          let bPackageCurrency = bPackageContext.bPackageCurrency,
                          !bPackageCurrency.isEmpty else {
                        self.bPackageNotify(.bPackageFailure("验单成功，但缺少 StoreKit 实际金额或币种；交易暂不 finish"))
                        return
                    }
                    self.bPackageEventReporter?.bPackageReportPurchase(
                        bPackageAmount: bPackageAmount,
                        bPackageCurrency: bPackageCurrency
                    )
                    SKPaymentQueue.default().finishTransaction(bPackageTransaction)
                    self.bPackageClearContext()
                    BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "验单 code=0000；触发 Purchase 后已 finishTransaction")
                    self.bPackageNotify(.bPackageSuccess("支付并验单成功"))
                }
            } catch {
                await MainActor.run {
                    self.bPackageProcessingTransactions.remove(bPackageTransactionID)
                    BPackageLogger.bPackageShared.bPackageLog("StoreKit1", "验单失败：\(error.localizedDescription)。交易未 finish")
                    self.bPackageNotify(.bPackageFailure("支付已完成，但服务端验单失败：\(error.localizedDescription)\n交易已保留，可稍后重试"))
                }
            }
        }
    }

    private func bPackageReadReceipt() -> String? {
        guard let bPackageURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: bPackageURL.path),
              let bPackageData = try? Data(contentsOf: bPackageURL), !bPackageData.isEmpty else { return nil }
        return bPackageData.base64EncodedString()
    }

    private func bPackageMakeCallbackResult(bPackageOrderCode: String) -> String {
        guard let bPackageData = try? JSONSerialization.data(withJSONObject: ["orderCode": bPackageOrderCode], options: [.sortedKeys]) else { return "" }
        return String(decoding: bPackageData, as: UTF8.self)
    }

    private func bPackageSaveContext(_ bPackageValue: BPackagePaymentContext) {
        if let bPackageData = try? JSONEncoder().encode(bPackageValue) {
            UserDefaults.standard.set(bPackageData, forKey: bPackageContextKey)
        }
    }

    private func bPackageLoadContext() -> BPackagePaymentContext? {
        guard let bPackageData = UserDefaults.standard.data(forKey: bPackageContextKey) else { return nil }
        return try? JSONDecoder().decode(BPackagePaymentContext.self, from: bPackageData)
    }

    private func bPackageClearContext() { UserDefaults.standard.removeObject(forKey: bPackageContextKey) }

    func bPackageOwnsProductIdentifier(_ bPackageProductIdentifier: String) -> Bool {
        let bPackageIDs = UserDefaults.standard.stringArray(forKey: bPackageOwnedProductIDsKey) ?? []
        return bPackageIDs.contains(bPackageProductIdentifier)
    }

    private func bPackageRememberOwnedProductID(_ bPackageProductIdentifier: String) {
        var bPackageIDs = UserDefaults.standard.stringArray(forKey: bPackageOwnedProductIDsKey) ?? []
        guard !bPackageIDs.contains(bPackageProductIdentifier) else { return }
        bPackageIDs.append(bPackageProductIdentifier)
        UserDefaults.standard.set(bPackageIDs, forKey: bPackageOwnedProductIDsKey)
    }

    private func bPackageNotify(_ bPackageState: BPackageState) {
        DispatchQueue.main.async { [weak self] in self?.bPackageOnStateChange?(bPackageState) }
    }
}
