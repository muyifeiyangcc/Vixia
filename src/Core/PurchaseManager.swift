import StoreKit

enum PurchaseManagerState {
    case idle
    case loadingProducts
    case productsLoaded([DiamondProduct])
    case purchasing(DiamondProduct)
    case purchased(DiamondProduct)
    case failed(String)
}

/// Central StoreKit V1 manager for consumable diamond products.
/// Add the production identifiers to `catalog` when they are available; the
/// loading, filtering, display and purchase flow supports any catalog size.
final class PurchaseManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = PurchaseManager()

    let catalog: [DiamondProduct] = [
//        DiamondProduct(productID: "scrqnarytzarlywk", diamonds: 400, fallbackPrice: "$0.99"),
//        DiamondProduct(productID: "urclehxkhtyhqakt", diamonds: 800, fallbackPrice: "$1.99"),
//        DiamondProduct(productID: "flqttvwbrdpcxxfi", diamonds: 2_450, fallbackPrice: "$4.99"),
//        DiamondProduct(productID: "oclgiqgezkzccilt", diamonds: 5_150, fallbackPrice: "$9.99"),
//        DiamondProduct(productID: "nzkwetupkxraqnsy", diamonds: 6_400, fallbackPrice: "$12.99"),
//        DiamondProduct(productID: "duygxlwluyifcdam", diamonds: 10_800, fallbackPrice: "$19.99"),
//        DiamondProduct(productID: "wtakfgfoejokwjjj", diamonds: 14_900, fallbackPrice: "$24.99"),
//        DiamondProduct(productID: "ilwiosqjnwdgtqxx", diamonds: 29_400, fallbackPrice: "$49.99"),
//        DiamondProduct(productID: "htdmgufhqefpcrwy", diamonds: 39_500, fallbackPrice: "$79.99"),
//        DiamondProduct(productID: "intvavzdaijxusum", diamonds: 63_700, fallbackPrice: "$99.99")
        
        
        DiamondProduct(productID: "lvbsvhxcgcrvesor", diamonds: 400, fallbackPrice: "$0.99"),
        DiamondProduct(productID: "dxismgcwewhrtezo", diamonds: 800, fallbackPrice: "$1.99"),
        DiamondProduct(productID: "khtxlcejaxmqcsra", diamonds: 2450, fallbackPrice: "$4.99"),
        DiamondProduct(productID: "yadwwvxspgxwlndb", diamonds: 5150, fallbackPrice: "$9.99"),
        DiamondProduct(productID: "qnrcuelbtiuflyky", diamonds: 6400, fallbackPrice: "$12.99"),
        DiamondProduct(productID: "ymohxnvpkqxutvab", diamonds: 10800, fallbackPrice: "$19.99")

    ]

    var onStateChange: ((PurchaseManagerState) -> Void)?
    private var storeProducts: [String: SKProduct] = [:]
    private var activeProductsRequest: SKProductsRequest?

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func loadProducts() {
        activeProductsRequest?.cancel()
        onStateChange?(.loadingProducts)
        let request = SKProductsRequest(productIdentifiers: Set(catalog.map(\.productID)))
        activeProductsRequest = request
        request.delegate = self
        request.start()
    }

    func purchase(_ product: DiamondProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            onStateChange?(.failed("In-app purchases are disabled on this device."))
            return
        }
        guard let storeProduct = storeProducts[product.productID] else {
            onStateChange?(.failed("This diamond pack is currently unavailable."))
            return
        }
        onStateChange?(.purchasing(product))
        SKPaymentQueue.default().add(SKPayment(product: storeProduct))
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        activeProductsRequest = nil
        storeProducts = Dictionary(uniqueKeysWithValues: response.products.map { ($0.productIdentifier, $0) })
        let available = catalog.filter { storeProducts[$0.productID] != nil }
        guard !available.isEmpty else {
            onStateChange?(.failed("No diamond packs are currently available."))
            return
        }
        onStateChange?(.productsLoaded(available))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        activeProductsRequest = nil
        onStateChange?(.failed(error.localizedDescription))
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if StoreKit1PurchaseManager.bPackageShared.bPackageOwnsProductIdentifier(
                transaction.payment.productIdentifier
            ) {
                continue
            }
            guard let product = catalog.first(where: { $0.productID == transaction.payment.productIdentifier }) else {
                // Unknown products may belong to another observer. Never finish them here.
                continue
            }

            switch transaction.transactionState {
            case .purchased:
                // Consumable purchase success is defined by StoreKit's local
                // purchased state; receipt validation is intentionally omitted.
                LocalStore.shared.diamondBalance += product.diamonds
                queue.finishTransaction(transaction)
                onStateChange?(.purchased(product))
            case .failed:
                queue.finishTransaction(transaction)
                let message: String
                if (transaction.error as? SKError)?.code == .paymentCancelled {
                    message = "Purchase cancelled."
                } else {
                    message = transaction.error?.localizedDescription ?? "Purchase failed."
                }
                onStateChange?(.failed(message))
            case .purchasing, .deferred:
                onStateChange?(.purchasing(product))
            case .restored:
                // Consumables are not restored or credited again.
                queue.finishTransaction(transaction)
                onStateChange?(.idle)
            @unknown default:
                break
            }
        }
    }
}
