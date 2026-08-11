import UIKit
import SnapKit

public final class SignInRequiredViewController: UIViewController {
    private let routeHandler: AuthRouteHandler

    public init(routeHandler: @escaping AuthRouteHandler) {
        self.routeHandler = routeHandler
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        let panel = UIImageView(image: UIImage(named: "alert_bg")?.resizableImage(withCapInsets: UIEdgeInsets(top: 44, left: 44, bottom: 44, right: 44), resizingMode: .stretch))
        panel.isUserInteractionEnabled = true
        panel.layer.cornerRadius = 32
        panel.layer.borderWidth = 3
        panel.layer.borderColor = AuthPalette.brandDeep.cgColor
        panel.clipsToBounds = true

        let title = UILabel()
        title.text = "Sign In Required"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textAlignment = .center
        let message = UILabel()
        message.text = "To ensure the normal operation of the function, please sign in to your account first."
        message.font = .systemFont(ofSize: 14)
        message.textAlignment = .center
        message.numberOfLines = 0

        let cancel = actionButton(title: "Cancel", filled: false, action: #selector(cancelTapped))
        let signIn = actionButton(title: "Sign In", filled: true, action: #selector(signInTapped))
        let actions = UIStackView(arrangedSubviews: [cancel, signIn])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually

        view.addSubview(panel)
        panel.addSubview(title)
        panel.addSubview(message)
        panel.addSubview(actions)
        panel.snp.makeConstraints { $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16); $0.centerY.equalTo(view.safeAreaLayoutGuide) }
        title.snp.makeConstraints { $0.top.equalToSuperview().offset(33); $0.leading.trailing.equalToSuperview().inset(20) }
        message.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(28) }
        actions.snp.makeConstraints { $0.top.equalTo(message.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview().inset(18); $0.bottom.equalToSuperview().inset(18); $0.height.equalTo(44) }
    }

    private func actionButton(title: String, filled: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AuthPalette.primaryText, for: .normal)
        button.backgroundColor = filled ? AuthPalette.brand : .white
        button.layer.cornerRadius = 11
        if !filled {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red: 217/255, green: 220/255, blue: 210/255, alpha: 1).cgColor
        }
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func signInTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.routeHandler(.openEmailSignIn, self)
        }
    }
}
