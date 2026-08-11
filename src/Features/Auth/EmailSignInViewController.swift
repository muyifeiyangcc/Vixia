import UIKit
import SnapKit

public final class EmailSignInViewController: AuthScrollViewController, UITextFieldDelegate {
    private let emailField = AuthTextField(placeholder: "Email address")
    private let passwordField = AuthTextField(placeholder: "Password", secure: true)
    public var credentialValidator: ((AuthCredentials) -> String?)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.returnKeyType = .next
        emailField.delegate = self
        passwordField.textContentType = .password
        passwordField.returnKeyType = .go
        passwordField.delegate = self
    }

    private func configureLayout() {
        let back = makeBackButton()
        let title = UILabel()
        title.text = "WELCOME TO\nVIXIA"
        title.numberOfLines = 2
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = AuthPalette.primaryText

        let forgot = underlinedButton("Forgot Password?", action: #selector(forgotTapped))

        let submit = AuthPrimaryButton(title: "SIGN IN")
        submit.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        contentView.addSubview(back)
        contentView.addSubview(title)
        contentView.addSubview(emailField)
        contentView.addSubview(passwordField)
        contentView.addSubview(forgot)
        contentView.addSubview(submit)
        back.snp.makeConstraints { $0.top.equalToSuperview().offset(10); $0.leading.equalToSuperview().offset(24) }
        title.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(40); $0.leading.trailing.equalToSuperview().inset(24) }
        emailField.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(31); $0.leading.trailing.equalToSuperview().inset(24) }
        passwordField.snp.makeConstraints { $0.top.equalTo(emailField.snp.bottom).offset(18); $0.leading.trailing.equalTo(emailField) }
        forgot.snp.makeConstraints { $0.top.equalTo(passwordField.snp.bottom).offset(18); $0.leading.equalToSuperview().offset(28) }
        submit.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(37); $0.top.greaterThanOrEqualTo(forgot.snp.bottom).offset(80); $0.bottom.equalToSuperview().inset(37) }
    }

    private func underlinedButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor(red: 44/255, green: 44/255, blue: 44/255, alpha: 1),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func forgotTapped() { routeHandler(.openPasswordRecovery, self) }

    @objc private func submitTapped() {
        let credentials = AuthCredentials(email: emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", password: passwordField.text ?? "")
        if let message = AuthValidation.credentials(email: credentials.email, password: credentials.password) ?? credentialValidator?(credentials) {
            showMessage("Unable to Sign In", message: message)
            return
        }
        routeHandler(.signedIn(credentials), self)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField { passwordField.becomeFirstResponder() } else { submitTapped() }
        return true
    }
}
