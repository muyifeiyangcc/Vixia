import UIKit
import SnapKit

enum AuthPalette {
    static let brand = UIColor(red: 200/255, green: 1, blue: 55/255, alpha: 1)
    static let brandDeep = UIColor(red: 174/255, green: 234/255, blue: 25/255, alpha: 1)
    static let field = UIColor(red: 236/255, green: 242/255, blue: 218/255, alpha: 1)
    static let background = UIColor(red: 253/255, green: 252/255, blue: 252/255, alpha: 1)
    static let primaryText = UIColor(red: 5/255, green: 5/255, blue: 5/255, alpha: 1)
    static let secondaryText = UIColor(red: 112/255, green: 119/255, blue: 107/255, alpha: 1)
}

final class AuthPrimaryButton: UIButton {
    init(title: String, height: CGFloat = 58) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backgroundColor = AuthPalette.primaryText
        layer.cornerRadius = height / 2
        snp.makeConstraints { $0.height.equalTo(height) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class AuthTextField: UITextField {
    init(placeholder: String, secure: Bool = false) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        isSecureTextEntry = secure
        textColor = AuthPalette.primaryText
        font = .systemFont(ofSize: 14)
        backgroundColor = AuthPalette.field
        layer.cornerRadius = 9
        autocorrectionType = .no
        clearButtonMode = .whileEditing
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        leftViewMode = .always
        snp.makeConstraints { $0.height.equalTo(44) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

public class AuthScrollViewController: UIViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()
    let routeHandler: AuthRouteHandler

    public init(routeHandler: @escaping AuthRouteHandler) {
        self.routeHandler = routeHandler
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AuthPalette.background
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
            $0.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide).priority(.high)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    func makeBackButton() -> UIButton {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
        button.setImage(UIImage(systemName: "arrow.left", withConfiguration: configuration), for: .normal)
        button.tintColor = UIColor(red: 44/255, green: 44/255, blue: 44/255, alpha: 1)
        button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        button.snp.makeConstraints { $0.size.equalTo(44) }
        return button
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    func showMessage(_ title: String, message: String? = nil, completion: (() -> Void)? = nil) {
        vxAlert(title: title, message: message ?? "", actions: [("OK", .default, completion)])
    }
}

final class AuthLabeledValueRow: UIControl {
    let titleLabel = UILabel()
    let valueLabel = UILabel()

    init(title: String, value: String, height: CGFloat = 44) {
        super.init(frame: .zero)
        backgroundColor = AuthPalette.field
        layer.cornerRadius = height > 44 ? 12 : 9
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = AuthPalette.primaryText
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = AuthPalette.secondaryText
        valueLabel.textAlignment = .right
        addSubview(titleLabel)
        addSubview(valueLabel)
        titleLabel.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        valueLabel.snp.makeConstraints { $0.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12) }
        snp.makeConstraints { $0.height.equalTo(height) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
