import UIKit
import UserNotifications
import WebKit
#if canImport(ScreenShield)
import ScreenShield
#endif

final class CAPlanPhotoBookRY: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private let CAPantsOptionLiefRY: URL
    private let CABessHaveFuncRY: CAEraserPresentBikeRY
    private let CADepictDirectorChapterRY: CAComPickMomentRY
    private let CAPictureFlatCoffeeRY: UIImage?
    private let CAMirrorFirePeachRY: () -> Void
    private var CABeenCryChairRY = false
    private var CAKeyboardFireCoalitionRY = false
    private var CACharacterPotionTeacherRY = false
    private var CAMomentInterYunRY = false
    private var CAEveryWindListRY = false
    private var CAWriteCastleOffRY: Bool?
    private let CAMakeAthleticCivilianRY = UIView()
    private var CAScabDimensionCryRY: UIView?
    private weak var CAYourDeviceArsenalRY: UIImageView?
    private let CAShoesDolphinFishRY = UIView()
    private let CAColorsTestQuizzesRY = UIActivityIndicatorView(style: .large)
    private let CADevastateQuePictureRY = UILabel()
    private let CAStudentDetectBombRY = UIButton(type: .system)
    private let CAClimbToolDorsalRY = UIView()
    private let CAElephantIronDefinitionRY = UIActivityIndicatorView(style: .large)
    private let CAAppleOceanDestroyRY = UILabel()
    private let CATrialsPrivacyMorningRY = UIView()
    private let CARainDelSnakeRY = UILabel()
    private var CASelectAmongBindRY: DispatchWorkItem?

    private lazy var CADisagreeFishInsectRY: WKWebView = {
        let CAArrivalDearInfoRY = WKUserContentController()
        ["rechargePay", "Close", "openBrowser"].forEach { CAArrivalDearInfoRY.add(self, name: $0) }
        let CAAllowEarthDimensionRY = WKWebViewConfiguration()
        CAAllowEarthDimensionRY.userContentController = CAArrivalDearInfoRY
        CAAllowEarthDimensionRY.allowsInlineMediaPlayback = true
        CAAllowEarthDimensionRY.mediaTypesRequiringUserActionForPlayback = []
        let CAIdahoWhaleKindRY = WKWebView(frame: .zero, configuration: CAAllowEarthDimensionRY)
        CAIdahoWhaleKindRY.navigationDelegate = self
        CAIdahoWhaleKindRY.uiDelegate = self
        CAIdahoWhaleKindRY.isOpaque = false
        CAIdahoWhaleKindRY.backgroundColor = .clear
        CAIdahoWhaleKindRY.scrollView.backgroundColor = .clear
        CAIdahoWhaleKindRY.scrollView.contentInsetAdjustmentBehavior = .never
        CAIdahoWhaleKindRY.scrollView.contentInset = .zero
        CAIdahoWhaleKindRY.scrollView.scrollIndicatorInsets = .zero
        CAIdahoWhaleKindRY.scrollView.bounces = false
        CAIdahoWhaleKindRY.allowsBackForwardNavigationGestures = true
        return CAIdahoWhaleKindRY
    }()

    init(CAPantsOptionLiefRY: URL,
         CABessHaveFuncRY: CAEraserPresentBikeRY,
         CADepictDirectorChapterRY: CAComPickMomentRY,
         CAPictureFlatCoffeeRY: UIImage? = nil,
        CAMirrorFirePeachRY: @escaping () -> Void) {
        self.CAPantsOptionLiefRY = CAPantsOptionLiefRY
        self.CABessHaveFuncRY = CABessHaveFuncRY
        self.CADepictDirectorChapterRY = CADepictDirectorChapterRY
        self.CAPictureFlatCoffeeRY = CAPictureFlatCoffeeRY
        self.CAMirrorFirePeachRY = CAMirrorFirePeachRY
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        CAVineHelloCollapseRY()
        CAGrapeNetArsenalRY()
        CAHelloSelectWhaleRY()
        CABlightGrazeQueenRY()
        CAGrazePlaneBorderRY(CAStreetBudgetTreeRY: "Loading…")
        StoreKit1PurchaseManager.CABootHousePotionRY.CABessYunUseRY(
            CABessHaveFuncRY: CABessHaveFuncRY,
            CADepictDirectorChapterRY: CADepictDirectorChapterRY
        ) { [weak self] CAGliderZooGliderRY in self?.CADevicePhotoMemoryRY(CAGliderZooGliderRY) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let CACitySnowGrapeRY = navigationController else { return }
        if CAWriteCastleOffRY == nil {
            CAWriteCastleOffRY = CACitySnowGrapeRY.isNavigationBarHidden
        }
        CACitySnowGrapeRY.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let CACitySnowGrapeRY = navigationController,
              let CAWriteCastleOffRY else { return }
        CACitySnowGrapeRY.setNavigationBarHidden(CAWriteCastleOffRY, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CACameraCharacterWizardRY()
        if !CAMomentInterYunRY {
            CAMomentInterYunRY = true
            #if canImport(ScreenShield)
            ScreenShield.shared.protectFromScreenRecording()
            #endif
        }
        CADesireHighMusicRY()
    }

    private func CADesireHighMusicRY() {
        guard CABeenCryChairRY, !CACharacterPotionTeacherRY else { return }
        CACharacterPotionTeacherRY = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { CAMirrorThemKeyRY, _ in
            if CAMirrorThemKeyRY { DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() } }
        }
    }

    deinit {
        CADisagreeFishInsectRY.configuration.userContentController.removeAllScriptMessageHandlers()
        StoreKit1PurchaseManager.CABootHousePotionRY.CAPigShoesTracksRY()
    }

    private func CAVineHelloCollapseRY() {
        // The secure container hides its content in screenshots, leaving the root view as the background.
        // Keep it white to avoid a gray or black result from system appearance colors.
        view.backgroundColor = .white
        CASiteMeMountainRY()
        if let CAPictureFlatCoffeeRY {
            let CACeillingTerWindowRY = UIImageView(image: CAPictureFlatCoffeeRY)
            CAYourDeviceArsenalRY = CACeillingTerWindowRY
            CACeillingTerWindowRY.translatesAutoresizingMaskIntoConstraints = false
            CACeillingTerWindowRY.contentMode = .scaleAspectFill
            CAMakeAthleticCivilianRY.addSubview(CACeillingTerWindowRY)
            NSLayoutConstraint.activate([
                CACeillingTerWindowRY.leadingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.leadingAnchor),
                CACeillingTerWindowRY.trailingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.trailingAnchor),
                CACeillingTerWindowRY.topAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.topAnchor),
                CACeillingTerWindowRY.bottomAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.bottomAnchor)
            ])
        }
        CADisagreeFishInsectRY.translatesAutoresizingMaskIntoConstraints = false
        CAMakeAthleticCivilianRY.addSubview(CADisagreeFishInsectRY)
        NSLayoutConstraint.activate([
            CADisagreeFishInsectRY.leadingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.leadingAnchor),
            CADisagreeFishInsectRY.trailingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.trailingAnchor),
            CADisagreeFishInsectRY.topAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.topAnchor),
            CADisagreeFishInsectRY.bottomAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.bottomAnchor)
        ])
    }

    private func CASiteMeMountainRY() {
        #if canImport(ScreenShield)
        let CACeillingUntilSharkRY = ScreenshotProtectingView(contentView: CAMakeAthleticCivilianRY)
        CACeillingUntilSharkRY.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(CACeillingUntilSharkRY)
        NSLayoutConstraint.activate([
            CACeillingUntilSharkRY.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            CACeillingUntilSharkRY.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            CACeillingUntilSharkRY.topAnchor.constraint(equalTo: view.topAnchor),
            CACeillingUntilSharkRY.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if CAMakeAthleticCivilianRY.superview != nil {
            CAScabDimensionCryRY = CACeillingUntilSharkRY
            return
        }

        CACeillingUntilSharkRY.removeFromSuperview()
        #endif

        CAMakeAthleticCivilianRY.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(CAMakeAthleticCivilianRY)
        NSLayoutConstraint.activate([
            CAMakeAthleticCivilianRY.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            CAMakeAthleticCivilianRY.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            CAMakeAthleticCivilianRY.topAnchor.constraint(equalTo: view.topAnchor),
            CAMakeAthleticCivilianRY.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func CAGrapeNetArsenalRY() {
        CAShoesDolphinFishRY.translatesAutoresizingMaskIntoConstraints = false
        CAShoesDolphinFishRY.backgroundColor = .clear
        CAShoesDolphinFishRY.isHidden = true
        CAColorsTestQuizzesRY.translatesAutoresizingMaskIntoConstraints = false
        CAColorsTestQuizzesRY.color = .black
        CADevastateQuePictureRY.text = "Loading…"
        CADevastateQuePictureRY.textColor = .black
        CADevastateQuePictureRY.numberOfLines = 0
        CADevastateQuePictureRY.textAlignment = .center
        CAStudentDetectBombRY.setTitle("Reload", for: .normal)
        CAStudentDetectBombRY.isHidden = true
        CAStudentDetectBombRY.addTarget(self, action: #selector(CADarlingImageZooRY), for: .touchUpInside)
        let CAOnlineComplainRainRY = UIStackView(arrangedSubviews: [CAColorsTestQuizzesRY, CADevastateQuePictureRY, CAStudentDetectBombRY])
        CAOnlineComplainRainRY.axis = .vertical
        CAOnlineComplainRainRY.alignment = .center
        CAOnlineComplainRainRY.spacing = 16
        CAOnlineComplainRainRY.translatesAutoresizingMaskIntoConstraints = false
        CAMakeAthleticCivilianRY.addSubview(CAShoesDolphinFishRY)
        CAShoesDolphinFishRY.addSubview(CAOnlineComplainRainRY)
        NSLayoutConstraint.activate([
            CAShoesDolphinFishRY.leadingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.leadingAnchor),
            CAShoesDolphinFishRY.trailingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.trailingAnchor),
            CAShoesDolphinFishRY.topAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.topAnchor),
            CAShoesDolphinFishRY.bottomAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.bottomAnchor),
            CAOnlineComplainRainRY.centerXAnchor.constraint(equalTo: CAShoesDolphinFishRY.centerXAnchor),
            CAOnlineComplainRainRY.centerYAnchor.constraint(equalTo: CAShoesDolphinFishRY.centerYAnchor),
            CAOnlineComplainRainRY.leadingAnchor.constraint(greaterThanOrEqualTo: CAShoesDolphinFishRY.leadingAnchor, constant: 32),
            CAOnlineComplainRainRY.trailingAnchor.constraint(lessThanOrEqualTo: CAShoesDolphinFishRY.trailingAnchor, constant: -32)
        ])
    }

    private func CACameraCharacterWizardRY() {
        guard !CAKeyboardFireCoalitionRY, view.window != nil else { return }
        CAKeyboardFireCoalitionRY = true
        CADisagreeFishInsectRY.load(URLRequest(url: CAPantsOptionLiefRY))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        CAColorsTestQuizzesRY.stopAnimating()
        CAShoesDolphinFishRY.isHidden = true
        CAStudentDetectBombRY.isHidden = true
        guard !CABeenCryChairRY else { return }
        CAYourDeviceArsenalRY?.removeFromSuperview()
        CABeenCryChairRY = true
        CADesireHighMusicRY()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "Close":
            guard !CAEveryWindListRY else { return }
            CAEveryWindListRY = true
            userContentController.removeScriptMessageHandler(forName: "Close")
            CADisagreeFishInsectRY.stopLoading()
            CAMirrorFirePeachRY()
        case "openBrowser":
            if let CAEarthOnSeedRY = message.body as? [String: Any], let CAAntiDeviceVineRY = CAEarthOnSeedRY["url"] as? String {
                CABeeMountainPencilRY(CAAntiDeviceVineRY)
            } else if let CAAntiDeviceVineRY = message.body as? String {
                CABeeMountainPencilRY(CAAntiDeviceVineRY)
            }
        case "rechargePay":
            guard let CAEarthOnSeedRY = message.body as? [String: Any] else { return }
            let CAHorseIndexPlaneRY = CAEarthOnSeedRY["batchNo"] as? String ?? ""
            let CARoadBorderComesRY = CAEarthOnSeedRY["orderCode"] as? String ?? ""
            guard !CAHorseIndexPlaneRY.isEmpty, !CARoadBorderComesRY.isEmpty else {
                CAWindowDesertArrestRY(CAPresentAppleInfoRY: "Payment Failed", CAStreetBudgetTreeRY: "The payment information is incomplete.")
                return
            }
            // Report InitiateCheckout immediately after receiving a valid rechargePay request.
            CADepictDirectorChapterRY.CABiologicalDorsalLeaveRY(.CAInsectDetectTracksRY)
            StoreKit1PurchaseManager.CABootHousePotionRY.CACollapseDemonstrateBessRY(
                CAHorseIndexPlaneRY: CAHorseIndexPlaneRY,
                CARoadBorderComesRY: CARoadBorderComesRY
            )
        default:
            break
        }
    }

    private func CAHelloSelectWhaleRY() {
        CAClimbToolDorsalRY.translatesAutoresizingMaskIntoConstraints = false
        CAClimbToolDorsalRY.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        CAClimbToolDorsalRY.isHidden = true
        CAAppleOceanDestroyRY.translatesAutoresizingMaskIntoConstraints = false
        CAAppleOceanDestroyRY.textColor = .white
        CAAppleOceanDestroyRY.numberOfLines = 0
        CAAppleOceanDestroyRY.textAlignment = .center
        CAElephantIronDefinitionRY.translatesAutoresizingMaskIntoConstraints = false
        CAElephantIronDefinitionRY.color = .white
        CAMakeAthleticCivilianRY.addSubview(CAClimbToolDorsalRY)
        CAClimbToolDorsalRY.addSubview(CAElephantIronDefinitionRY)
        CAClimbToolDorsalRY.addSubview(CAAppleOceanDestroyRY)
        NSLayoutConstraint.activate([
            CAClimbToolDorsalRY.leadingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.leadingAnchor),
            CAClimbToolDorsalRY.trailingAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.trailingAnchor),
            CAClimbToolDorsalRY.topAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.topAnchor),
            CAClimbToolDorsalRY.bottomAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.bottomAnchor),
            CAElephantIronDefinitionRY.centerXAnchor.constraint(equalTo: CAClimbToolDorsalRY.centerXAnchor),
            CAElephantIronDefinitionRY.centerYAnchor.constraint(equalTo: CAClimbToolDorsalRY.centerYAnchor, constant: -24),
            CAAppleOceanDestroyRY.topAnchor.constraint(equalTo: CAElephantIronDefinitionRY.bottomAnchor, constant: 16),
            CAAppleOceanDestroyRY.leadingAnchor.constraint(equalTo: CAClimbToolDorsalRY.leadingAnchor, constant: 30),
            CAAppleOceanDestroyRY.trailingAnchor.constraint(equalTo: CAClimbToolDorsalRY.trailingAnchor, constant: -30)
        ])
    }

    private func CADevicePhotoMemoryRY(_ CAGliderZooGliderRY: StoreKit1PurchaseManager.CAComesOrXinRY) {
        switch CAGliderZooGliderRY {
        case .CAAngerNetDarlingRY(let CAStreetBudgetTreeRY):
            CAClimbToolDorsalRY.isHidden = false
            CAAppleOceanDestroyRY.text = CAStreetBudgetTreeRY
            CAElephantIronDefinitionRY.startAnimating()
        case .CATerBloomLovingRY:
            CACoatLoadAllyRY()
            CAComplainDialogueMountainRY(CAStreetBudgetTreeRY: "Payment successful")
        case .CAMaxTheCoffeeRY(let CAStreetBudgetTreeRY):
            CACoatLoadAllyRY()
            CAWindowDesertArrestRY(CAPresentAppleInfoRY: "Payment Failed", CAStreetBudgetTreeRY: CAStreetBudgetTreeRY)
        case .CAWindowPictureTreeRY:
            CACoatLoadAllyRY()
            CAComplainDialogueMountainRY(CAStreetBudgetTreeRY: "Payment cancelled")
        }
    }

    private func CACoatLoadAllyRY() {
        CAElephantIronDefinitionRY.stopAnimating()
        CAClimbToolDorsalRY.isHidden = true
    }

    private func CAWindowDesertArrestRY(CAPresentAppleInfoRY: String, CAStreetBudgetTreeRY: String) {
        guard presentedViewController == nil else { return }
        let CADialogueDateDemonstrateRY = UIAlertController(title: CAPresentAppleInfoRY, message: CAStreetBudgetTreeRY, preferredStyle: .alert)
        CADialogueDateDemonstrateRY.addAction(UIAlertAction(title: "OK", style: .default))
        present(CADialogueDateDemonstrateRY, animated: true)
    }

    private func CABlightGrazeQueenRY() {
        CATrialsPrivacyMorningRY.translatesAutoresizingMaskIntoConstraints = false
        CATrialsPrivacyMorningRY.backgroundColor = UIColor.black.withAlphaComponent(0.82)
        CATrialsPrivacyMorningRY.layer.cornerRadius = 12
        CATrialsPrivacyMorningRY.alpha = 0
        CATrialsPrivacyMorningRY.isHidden = true

        CARainDelSnakeRY.translatesAutoresizingMaskIntoConstraints = false
        CARainDelSnakeRY.textColor = .white
        CARainDelSnakeRY.font = .systemFont(ofSize: 15, weight: .semibold)
        CARainDelSnakeRY.numberOfLines = 0
        CARainDelSnakeRY.textAlignment = .center

        CAMakeAthleticCivilianRY.addSubview(CATrialsPrivacyMorningRY)
        CATrialsPrivacyMorningRY.addSubview(CARainDelSnakeRY)
        NSLayoutConstraint.activate([
            CATrialsPrivacyMorningRY.centerXAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.centerXAnchor),
            CATrialsPrivacyMorningRY.bottomAnchor.constraint(equalTo: CAMakeAthleticCivilianRY.safeAreaLayoutGuide.bottomAnchor, constant: -64),
            CATrialsPrivacyMorningRY.leadingAnchor.constraint(greaterThanOrEqualTo: CAMakeAthleticCivilianRY.leadingAnchor, constant: 32),
            CATrialsPrivacyMorningRY.trailingAnchor.constraint(lessThanOrEqualTo: CAMakeAthleticCivilianRY.trailingAnchor, constant: -32),
            CARainDelSnakeRY.leadingAnchor.constraint(equalTo: CATrialsPrivacyMorningRY.leadingAnchor, constant: 20),
            CARainDelSnakeRY.trailingAnchor.constraint(equalTo: CATrialsPrivacyMorningRY.trailingAnchor, constant: -20),
            CARainDelSnakeRY.topAnchor.constraint(equalTo: CATrialsPrivacyMorningRY.topAnchor, constant: 12),
            CARainDelSnakeRY.bottomAnchor.constraint(equalTo: CATrialsPrivacyMorningRY.bottomAnchor, constant: -12)
        ])
    }

    private func CAComplainDialogueMountainRY(CAStreetBudgetTreeRY: String) {
        CASelectAmongBindRY?.cancel()
        CARainDelSnakeRY.text = CAStreetBudgetTreeRY
        CATrialsPrivacyMorningRY.isHidden = false
        CAMakeAthleticCivilianRY.bringSubviewToFront(CATrialsPrivacyMorningRY)
        UIView.animate(withDuration: 0.2) {
            self.CATrialsPrivacyMorningRY.alpha = 1
        }

        let CAGrazeLoadOilRY = DispatchWorkItem { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.2, animations: {
                self.CATrialsPrivacyMorningRY.alpha = 0
            }, completion: { _ in
                self.CATrialsPrivacyMorningRY.isHidden = true
            })
        }
        CASelectAmongBindRY = CAGrazeLoadOilRY
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: CAGrazeLoadOilRY)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        CABirthPlanRainRY(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        CABirthPlanRainRY(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        CAGrazePlaneBorderRY(CAStreetBudgetTreeRY: "Restoring page…")
        webView.reload()
    }

    private func CABirthPlanRainRY(_ CAAirPaintAcheRY: Error) {
        let CAJuiceOptionGrapeRY = CAAirPaintAcheRY as NSError
        guard CAJuiceOptionGrapeRY.domain != NSURLErrorDomain || CAJuiceOptionGrapeRY.code != NSURLErrorCancelled else { return }
        CAColorsTestQuizzesRY.stopAnimating()
        CADevastateQuePictureRY.text = "Page failed to load.\nPlease check your connection and try again."
        CAStudentDetectBombRY.isHidden = false
        CAShoesDolphinFishRY.isHidden = false
    }

    private func CAGrazePlaneBorderRY(CAStreetBudgetTreeRY: String) {
        CADevastateQuePictureRY.text = CAStreetBudgetTreeRY
        CAStudentDetectBombRY.isHidden = true
        CAShoesDolphinFishRY.isHidden = false
        CAColorsTestQuizzesRY.startAnimating()
    }

    @objc private func CADarlingImageZooRY() {
        CAGrazePlaneBorderRY(CAStreetBudgetTreeRY: "Loading page…")
        if CADisagreeFishInsectRY.url != nil {
            CADisagreeFishInsectRY.reload()
        } else {
            CADisagreeFishInsectRY.load(URLRequest(url: CAPantsOptionLiefRY))
        }
    }

    private func CABeeMountainPencilRY(_ CAAntiDeviceVineRY: String) {
        guard let CAPantsOptionLiefRY = URL(string: CAAntiDeviceVineRY) else { return }
        UIApplication.shared.open(CAPantsOptionLiefRY) { [weak self] CATerBloomLovingRY in
            let CAOneCloudBiteRY = try? JSONSerialization.data(withJSONObject: ["state": CATerBloomLovingRY ? "success" : "failed", "url": CAAntiDeviceVineRY])
            let CADirectorOctopusShieldRY = CAOneCloudBiteRY.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            self?.CADisagreeFishInsectRY.evaluateJavaScript("window.dispatchEvent(new CustomEvent('nativeOpenState',{detail:\(CADirectorOctopusShieldRY)}));")
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let CAPantsOptionLiefRY = action.request.url else { decisionHandler(.cancel); return }
        let CABoomBirdAversionRY = CAPantsOptionLiefRY.scheme?.lowercased() ?? ""
        if CAPantsOptionLiefRY.host?.lowercased() == "apps.apple.com" || CABoomBirdAversionRY == "itms-apps" {
            CABeeMountainPencilRY(CAPantsOptionLiefRY.absoluteString)
            decisionHandler(.cancel)
        } else if !["http", "https", "file", "about"].contains(CABoomBirdAversionRY) {
            CABeeMountainPencilRY(CAPantsOptionLiefRY.absoluteString)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let CAPantsOptionLiefRY = action.request.url {
            if CAPantsOptionLiefRY.host?.lowercased() == "apps.apple.com" { CABeeMountainPencilRY(CAPantsOptionLiefRY.absoluteString) }
            else { webView.load(URLRequest(url: CAPantsOptionLiefRY)) }
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}
