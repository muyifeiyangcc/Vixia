import UIKit
import SnapKit

public final class PasswordRecoveryViewController: AuthScrollViewController, UITextFieldDelegate {
    private let emailField = AuthTextField(placeholder: "Email address")
    private let passwordField = AuthTextField(placeholder: "New password", secure: true)
    private let confirmationField = AuthTextField(placeholder: "Confirm new password", secure: true)
    public var accountValidator: ((String) -> String?)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        [emailField, passwordField, confirmationField].forEach { $0.delegate = self }
        emailField.keyboardType = .emailAddress
        emailField.returnKeyType = .next
        passwordField.returnKeyType = .next
        confirmationField.returnKeyType = .go
    }

    private func configureLayout() {
        let back = makeBackButton()
        let title = UILabel()
        title.text = "FORGOT\nPASSWORD"
        title.numberOfLines = 2
        title.font = .systemFont(ofSize: 28, weight: .bold)
        let submit = AuthPrimaryButton(title: "SAVE")
        submit.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        [back, title, emailField, passwordField, confirmationField, submit].forEach(contentView.addSubview)
        back.snp.makeConstraints { $0.top.equalToSuperview().offset(10); $0.leading.equalToSuperview().offset(24) }
        title.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(40); $0.leading.trailing.equalToSuperview().inset(24) }
        emailField.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(31); $0.leading.trailing.equalToSuperview().inset(24) }
        passwordField.snp.makeConstraints { $0.top.equalTo(emailField.snp.bottom).offset(18); $0.leading.trailing.equalTo(emailField) }
        confirmationField.snp.makeConstraints { $0.top.equalTo(passwordField.snp.bottom).offset(18); $0.leading.trailing.equalTo(emailField) }
        submit.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(37); $0.top.greaterThanOrEqualTo(confirmationField.snp.bottom).offset(80); $0.bottom.equalToSuperview().inset(37) }
    }

    @objc private func submitTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        if let message = AuthValidation.credentials(email: email, password: password) ?? AuthValidation.newPassword(password, confirmation: confirmationField.text ?? "") ?? accountValidator?(email) {
            showMessage("Unable to Save", message: message)
            return
        }
        showMessage("Password Updated", message: "Your password was saved locally.") { [weak self] in
            guard let self else { return }
            self.routeHandler(.passwordReset(email: email, newPassword: password), self)
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField { passwordField.becomeFirstResponder() }
        else if textField === passwordField { confirmationField.becomeFirstResponder() }
        else { submitTapped() }
        return true
    }
}
