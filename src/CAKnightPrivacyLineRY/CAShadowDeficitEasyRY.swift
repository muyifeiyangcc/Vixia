import UIKit

@MainActor
final class CAShadowDeficitEasyRY: UIViewController {
    private let CAResWindowCloudRY: CAChairNotebookDestroyRY
    private let CAPictureFlatCoffeeRY: UIImage?
    private let CASilverKnowBoatRY: UIImage?
    private var CAClimbHeroJumpRY: URL?
    private let CAIronUpDataRY = UIButton(type: .system)
    private let CAShoesDolphinFishRY = UIView()
    private let CAColorsTestQuizzesRY = UIActivityIndicatorView(style: .large)
    private let CADevastateQuePictureRY = UILabel()
    private var CABombAsleepRealRY = false
    private var CAOtherCoffeeIndexRY = false
    private var CABlightWoodKeyboardRY: CAPlanPhotoBookRY?

    init(CAResWindowCloudRY: CAChairNotebookDestroyRY,
         CADetermineThanProtectRY: CAUntilBinRainRY,
         CAPictureFlatCoffeeRY: UIImage? = nil,
         CASilverKnowBoatRY: UIImage? = nil) {
        self.CAResWindowCloudRY = CAResWindowCloudRY
        switch CADetermineThanProtectRY {
        case .CAPigForgetFishRY:
            CAClimbHeroJumpRY = nil
        case .CAAmongZooKeyRY(let CAPantsOptionLiefRY):
            CAClimbHeroJumpRY = CAPantsOptionLiefRY
        }
        self.CAPictureFlatCoffeeRY = CAPictureFlatCoffeeRY
        self.CASilverKnowBoatRY = CASilverKnowBoatRY
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        CACatProtectLineRY()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !CABombAsleepRealRY, let CAClimbHeroJumpRY else { return }
        CABombAsleepRealRY = true
        CAClockHeroBrushRY(CAPantsOptionLiefRY: CAClimbHeroJumpRY)
    }

    private func CACatProtectLineRY() {
        view.backgroundColor = .systemBackground
        if let CAPictureFlatCoffeeRY {
            let CACeillingTerWindowRY = UIImageView(image: CAPictureFlatCoffeeRY)
            CACeillingTerWindowRY.translatesAutoresizingMaskIntoConstraints = false
            CACeillingTerWindowRY.contentMode = .scaleAspectFill
            view.addSubview(CACeillingTerWindowRY)
            NSLayoutConstraint.activate([
                CACeillingTerWindowRY.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                CACeillingTerWindowRY.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                CACeillingTerWindowRY.topAnchor.constraint(equalTo: view.topAnchor),
                CACeillingTerWindowRY.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        CAIronUpDataRY.setTitle("Sign In", for: .normal)
        CAIronUpDataRY.setTitleColor(.white, for: .normal)
        CAIronUpDataRY.titleLabel?.font = .systemFont(ofSize: 18, weight: .heavy)
        CAIronUpDataRY.backgroundColor = .black
        CAIronUpDataRY.layer.cornerRadius = 30
        CAIronUpDataRY.clipsToBounds = true
        CAIronUpDataRY.addTarget(self, action: #selector(CACableClientBikeRY), for: .touchUpInside)
        CAIronUpDataRY.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(CAIronUpDataRY)

        CAShoesDolphinFishRY.translatesAutoresizingMaskIntoConstraints = false
        CAShoesDolphinFishRY.backgroundColor = .clear
        CAShoesDolphinFishRY.isHidden = true
        CAColorsTestQuizzesRY.translatesAutoresizingMaskIntoConstraints = false
        CAColorsTestQuizzesRY.color = .black
        CADevastateQuePictureRY.text = "Loading…"
        CADevastateQuePictureRY.textColor = .black
        CADevastateQuePictureRY.font = .systemFont(ofSize: 16, weight: .semibold)
        CADevastateQuePictureRY.translatesAutoresizingMaskIntoConstraints = false
        let CAOnlineComplainRainRY = UIStackView(arrangedSubviews: [CAColorsTestQuizzesRY, CADevastateQuePictureRY])
        CAOnlineComplainRainRY.axis = .vertical
        CAOnlineComplainRainRY.alignment = .center
        CAOnlineComplainRainRY.spacing = 14
        CAOnlineComplainRainRY.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(CAShoesDolphinFishRY)
        CAShoesDolphinFishRY.addSubview(CAOnlineComplainRainRY)

        NSLayoutConstraint.activate([
            CAIronUpDataRY.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            CAIronUpDataRY.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            CAIronUpDataRY.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
            CAIronUpDataRY.heightAnchor.constraint(equalToConstant: 60),
            CAShoesDolphinFishRY.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            CAShoesDolphinFishRY.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            CAShoesDolphinFishRY.topAnchor.constraint(equalTo: view.topAnchor),
            CAShoesDolphinFishRY.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            CAOnlineComplainRainRY.centerXAnchor.constraint(equalTo: CAShoesDolphinFishRY.centerXAnchor),
            CAOnlineComplainRainRY.centerYAnchor.constraint(equalTo: CAShoesDolphinFishRY.centerYAnchor)
        ])
    }

    @objc private func CACableClientBikeRY() {
        guard !CAOtherCoffeeIndexRY else { return }
        CAGardenMountainVcRY(true)
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let CAPantsOptionLiefRY = try await CAResWindowCloudRY.CAWriteWriteClothesRY()
                CAClockHeroBrushRY(CAPantsOptionLiefRY: CAPantsOptionLiefRY, CAMountainMoonLineRY: true)
            } catch {
                CADialectRiverLaptopRY(error)
            }
        }
    }

    private func CAClockHeroBrushRY(CAPantsOptionLiefRY: URL, CAMountainMoonLineRY: Bool = false) {
        guard CABlightWoodKeyboardRY == nil else { return }
        if !CAMountainMoonLineRY { CAGardenMountainVcRY(true) }

        let CAMonkeyDesireTestRY = CAPlanPhotoBookRY(
            CAPantsOptionLiefRY: CAPantsOptionLiefRY,
            CABessHaveFuncRY: CAResWindowCloudRY.CABessHaveFuncRY,
            CADepictDirectorChapterRY: CAResWindowCloudRY.CADepictDirectorChapterRY,
            CAPictureFlatCoffeeRY: CASilverKnowBoatRY,
            CAMirrorFirePeachRY: { [weak self] in self?.CACharacterHugSnowRY() }
        )
        CAMonkeyDesireTestRY.modalPresentationStyle = .fullScreen
        CABlightWoodKeyboardRY = CAMonkeyDesireTestRY
        present(CAMonkeyDesireTestRY, animated: false) { [weak self, weak CAMonkeyDesireTestRY] in
            guard let self, let CAMonkeyDesireTestRY,
                  CABlightWoodKeyboardRY === CAMonkeyDesireTestRY else { return }
            CAGardenMountainVcRY(false)
        }
    }

    private func CAGardenMountainVcRY(_ CAAngerNetDarlingRY: Bool) {
        CAOtherCoffeeIndexRY = CAAngerNetDarlingRY
        CAShoesDolphinFishRY.isHidden = !CAAngerNetDarlingRY
        CAIronUpDataRY.isHidden = CAAngerNetDarlingRY
        CAIronUpDataRY.isEnabled = !CAAngerNetDarlingRY
        if CAAngerNetDarlingRY { CAColorsTestQuizzesRY.startAnimating() }
        else { CAColorsTestQuizzesRY.stopAnimating() }
    }

    private func CADialectRiverLaptopRY(_ CAAirPaintAcheRY: Error) {
        CAClimbHeroJumpRY = nil
        CAGardenMountainVcRY(false)
        guard presentedViewController == nil else { return }
        let CADialogueDateDemonstrateRY = UIAlertController(title: "Loading Failed",
                                              message: "Please check your connection and try again.",
                                              preferredStyle: .alert)
        CADialogueDateDemonstrateRY.addAction(UIAlertAction(title: "OK", style: .default))
        present(CADialogueDateDemonstrateRY, animated: true)
    }

    private func CACharacterHugSnowRY() {
        CAResWindowCloudRY.CABessMetalGoodRY()
        let CAMonkeyDesireTestRY = CABlightWoodKeyboardRY
        CAMonkeyDesireTestRY?.dismiss(animated: false) { [weak self] in
            guard let self else { return }
            CABlightWoodKeyboardRY = nil
            CAClimbHeroJumpRY = nil
            CABombAsleepRealRY = true
            CAGardenMountainVcRY(false)
        }
    }
}
