import UIKit
import SnapKit

public final class AuthEntryViewController: AuthScrollViewController, UITextViewDelegate {
    private let checkbox = UIButton(type: .system)
    private var isAgreementSelected = false { didSet { updateCheckbox() } }

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
    }

    private func configureLayout() {
        view.backgroundColor = AuthPalette.brand
        scrollView.isHidden = true

        let scenicBackground = UIImageView(image: UIImage(named: "login_bg"))
        scenicBackground.contentMode = .scaleAspectFill
        scenicBackground.clipsToBounds = true

        let colorWash = UIImageView(image: UIImage(named: "login_bg_color"))
        colorWash.contentMode = .scaleToFill
        colorWash.clipsToBounds = true

        view.insertSubview(scenicBackground, at: 0)
        view.insertSubview(colorWash, aboveSubview: scenicBackground)
        scenicBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(0.82)
        }
        colorWash.snp.makeConstraints { $0.edges.equalToSuperview() }

        let logoTile = UIImageView(image: UIImage(named: "lau"))
        logoTile.contentMode = .scaleToFill
        logoTile.layer.contentsRect = CGRect(x: 0.35, y: 0.595, width: 0.30, height: 0.15)
        logoTile.layer.cornerRadius = 40
        logoTile.clipsToBounds = true

        let brandTitle = UILabel()
        brandTitle.text = "VIXIA"
        brandTitle.textColor = .black
        brandTitle.font = .systemFont(ofSize: 40, weight: .heavy)

        let tagline = UILabel()
        tagline.text = "Ride your city. Own your style."
        tagline.textColor = .black
        tagline.font = .systemFont(ofSize: 16, weight: .semibold)

        let guestButton = loginCapsuleButton("I'M NEW")
        guestButton.contentHorizontalAlignment = .left
        guestButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 41, bottom: 0, right: 28)
        guestButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        guestButton.addTarget(self, action: #selector(guestTapped), for: .touchUpInside)

        let signInButton = loginCapsuleButton("SIGN IN BY EMAIL")
        signInButton.contentHorizontalAlignment = .right
        signInButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 38)
        signInButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        signInButton.addTarget(self, action: #selector(emailSignInTapped), for: .touchUpInside)

        let signUpLine = makeSignUpLine()
        let agreementLine = makeAgreementLine()
        let usesCompactWidth = UIScreen.main.bounds.width < 350

        [logoTile, brandTitle, tagline, guestButton, signInButton, signUpLine, agreementLine].forEach(view.addSubview)

        logoTile.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.bottom.equalTo(brandTitle.snp.top).offset(-13)
            make.size.equalTo(110)
        }
        brandTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalTo(tagline.snp.top).offset(-5)
        }
        tagline.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(21)
            make.bottom.equalTo(guestButton.snp.top).offset(-17)
        }
        guestButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalTo(signInButton.snp.top).offset(-15)
            make.width.equalTo(172)
            make.height.equalTo(60)
        }
        signInButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(129)
            make.trailing.equalToSuperview()
            make.height.equalTo(60)
            make.bottom.equalTo(signUpLine.snp.top).offset(-31)
        }
        signUpLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(agreementLine.snp.top).offset(-20)
            make.height.equalTo(18)
            make.leading.greaterThanOrEqualToSuperview().offset(18)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
        }
        agreementLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(usesCompactWidth ? 24 : 42)
            make.trailing.equalToSuperview().inset(usesCompactWidth ? 24 : 42)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(28)
        }

        updateCheckbox()
    }

    private func loginCapsuleButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .heavy)
        button.backgroundColor = .black
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        return button
    }

    private func makeSignUpLine() -> UIStackView {
        let prompt = UILabel()
        prompt.text = "Don't have an account?"
        prompt.textColor = .black
        prompt.font = .systemFont(ofSize: 12, weight: .semibold)

        let signUp = underlineButton("Sign up", size: 12, weight: .bold)
        signUp.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [prompt, signUp])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        return row
    }

    private func makeAgreementLine() -> UIView {
        let container = UIView()

        checkbox.tintColor = .black
        checkbox.accessibilityLabel = "Accept Privacy Policy and Terms of Service"
        checkbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)

        let agreementText = UITextView()
        agreementText.backgroundColor = .clear
        agreementText.isEditable = false
        agreementText.isScrollEnabled = false
        agreementText.delegate = self
        agreementText.textContainerInset = .zero
        agreementText.textContainer.lineFragmentPadding = 0
        agreementText.textAlignment = .center
        agreementText.adjustsFontForContentSizeCategory = true
        agreementText.linkTextAttributes = [
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let copy = "By continuing you agree to our Terms of Service\u{00A0}and Privacy Policy"
        let attributed = NSMutableAttributedString(
            string: copy,
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
        )
        attributed.addAttribute(.link, value: "vixia-auth://terms", range: (copy as NSString).range(of: "Terms of Service"))
        attributed.addAttribute(.link, value: "vixia-auth://privacy", range: (copy as NSString).range(of: "Privacy Policy"))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.minimumLineHeight = 14
        paragraph.maximumLineHeight = 14
        attributed.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: attributed.length))
        agreementText.attributedText = attributed

        container.addSubview(checkbox)
        container.addSubview(agreementText)
        checkbox.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.size.equalTo(14)
        }
        agreementText.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(checkbox.snp.trailing).offset(1)
        }
        return container
    }

    private func underlineButton(_ title: String, size: CGFloat, weight: UIFont.Weight) -> UIButton {
        let button = UIButton(type: .system)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    private func updateCheckbox() {
        let symbol = isAgreementSelected ? "record.circle" : "circle"
        checkbox.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)), for: .normal)
    }

    @objc private func checkboxTapped() { isAgreementSelected.toggle() }
    @objc private func guestTapped() { routeHandler(.continueAsGuest, self) }
    @objc private func signUpTapped() { routeHandler(.openRegistration, self) }

    @objc private func emailSignInTapped() {
        guard isAgreementSelected else {
            showMessage("Agreement Required", message: "Please accept the Privacy Policy and Terms of Service before continuing.")
            return
        }
        routeHandler(.openEmailSignIn, self)
    }

    @objc private func privacyTapped() {
        routeHandler(.openAgreement(.privacyPolicy, AuthAgreementKind.privacyPolicy.url), self)
    }

    @objc private func termsTapped() {
        routeHandler(.openAgreement(.termsOfService, AuthAgreementKind.termsOfService.url), self)
    }

    public func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        switch URL.host {
        case "terms": termsTapped()
        case "privacy": privacyTapped()
        default: return false
        }
        return false
    }
}
