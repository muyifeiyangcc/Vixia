import UIKit
import SnapKit

public final class EULAViewController: UIViewController {
    private let persistence: AuthEULAPersisting
    private let routeHandler: AuthRouteHandler
    private let panel = UIView()
    private let bodyScrollView = UIScrollView()
    private let bodyLabel = UILabel()
    private let agreeButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    public init(persistence: AuthEULAPersisting, routeHandler: @escaping AuthRouteHandler) {
        self.persistence = persistence
        self.routeHandler = routeHandler
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.56)
        configurePanel()
        configureContent()
    }

    private func configurePanel() {
        panel.backgroundColor = .clear
        panel.layer.cornerRadius = 32
        panel.layer.borderColor = AuthPalette.brandDeep.cgColor
        panel.layer.borderWidth = 3
        panel.clipsToBounds = true
        let background = UIImageView(image: UIImage(named: "alert_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 44, left: 44, bottom: 44, right: 44),
            resizingMode: .stretch
        ))
        background.contentMode = .scaleToFill
        panel.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }
        view.addSubview(panel)
        panel.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.centerY.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(min(CGFloat(732), UIScreen.main.bounds.height - 80))
        }
    }

    private func configureContent() {
        let titleLabel = UILabel()
        titleLabel.text = "EULA"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = AuthPalette.primaryText

        bodyLabel.text = Self.eulaText
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = AuthPalette.primaryText
        bodyLabel.numberOfLines = 0
        bodyScrollView.alwaysBounceVertical = true
        bodyScrollView.addSubview(bodyLabel)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(AuthPalette.primaryText, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 11
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(red: 217/255, green: 220/255, blue: 210/255, alpha: 1).cgColor
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        agreeButton.setTitle("Agree", for: .normal)
        agreeButton.setTitleColor(AuthPalette.primaryText, for: .normal)
        agreeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        agreeButton.backgroundColor = AuthPalette.brand
        agreeButton.layer.cornerRadius = 11
        agreeButton.addTarget(self, action: #selector(agreeTapped), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [cancelButton, agreeButton])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually

        panel.addSubview(titleLabel)
        panel.addSubview(bodyScrollView)
        panel.addSubview(actions)
        titleLabel.snp.makeConstraints { $0.top.equalToSuperview().offset(33); $0.leading.trailing.equalToSuperview().inset(20) }
        actions.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.bottom.equalToSuperview().inset(18)
            $0.height.equalTo(44)
        }
        bodyScrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(28)
            $0.bottom.equalTo(actions.snp.top).offset(-10)
        }
        bodyLabel.snp.makeConstraints {
            $0.edges.equalTo(bodyScrollView.contentLayoutGuide)
            $0.width.equalTo(bodyScrollView.frameLayoutGuide)
        }
    }

    @objc private func cancelTapped() {
        routeHandler(.terminateApplicationRequested, self)
    }

    @objc private func agreeTapped() {
        agreeButton.isEnabled = false
        persistence.persistEULAAcceptance { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.agreeButton.isEnabled = true
                switch result {
                case .success:
                    self.routeHandler(.eulaAccepted, self)
                case .failure:
                    self.vxAlert(title: "Unable to Save", message: "Your agreement could not be saved locally. Please try again.", actions: [("OK", .default, nil)])
                }
            }
        }
    }

    private static let eulaText = """
    Welcome to Vixia! To create a positive, safe and standardized space for scooter and riding community, the following content is strictly prohibited on the app:
    1. Any content involving child harm, pornography and other materials detrimental to minors' physical and mental health, including but not limited to texts, images, videos or comments that insult, defame or improperly use minors' portraits and information.
    2. False and harmful public information, including false content generated by AI or other means that disrupts public order, especially fake riding guides, misleading scooter modification or safety guidance, and false public opinion content.
    3. Violent content, cyber bullying, and any content that promotes pornography, illegal acts or disrupts the network ecological environment. Specifically, it is forbidden to upload pornographic, violent, bloody content, or use scooter sharing, comment and interaction functions to conduct cyber bullying and spread inappropriate information.
    If any of the above violations are detected, your uploaded riding posts, comments and other published content will be deleted, and your account will be restricted or banned. By clicking the confirmation button, you agree to abide by the Terms of Use and Privacy Policy of Vixia.
    """
}
