import UIKit
import SnapKit

enum SocialPalette {
    static let brand = UIColor(red: 200/255, green: 255/255, blue: 55/255, alpha: 1)
    static let deepBrand = UIColor(red: 174/255, green: 234/255, blue: 25/255, alpha: 1)
    static let paleBrand = UIColor(red: 238/255, green: 253/255, blue: 193/255, alpha: 1)
    static let softGreen = UIColor(red: 236/255, green: 242/255, blue: 218/255, alpha: 1)
    static let page = UIColor(red: 253/255, green: 252/255, blue: 252/255, alpha: 1)
    static let text = UIColor(red: 5/255, green: 5/255, blue: 5/255, alpha: 1)
    static let secondary = UIColor(red: 112/255, green: 119/255, blue: 107/255, alpha: 1)
    static let weak = UIColor(red: 147/255, green: 151/255, blue: 136/255, alpha: 1)
}

extension UIViewController {
    func socialConfigureBase() {
        view.backgroundColor = SocialPalette.page
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

final class SocialAvatarView: UIView {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = SocialPalette.softGreen
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = VXColor.textMuted
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func configure(user: SocialUser) {
        let resolved = user.avatar ?? user.avatarName.flatMap(UIImage.init(named:))
        imageView.image = resolved ?? UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = resolved == nil ? VXColor.textMuted : nil
    }

    func setImage(_ image: UIImage?, fallback: String) {
        imageView.image = image ?? UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = image == nil ? VXColor.textMuted : nil
    }
}

final class SocialIconButton: UIButton {
    init(systemName: String, pointSize: CGFloat = 26) {
        super.init(frame: .zero)
        tintColor = UIColor(white: 0.16, alpha: 1)
        setImage(UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)), for: .normal)
        contentHorizontalAlignment = .center
        contentVerticalAlignment = .center
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class SocialStateView: UIView {
    let actionButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 14)
        label.textColor = SocialPalette.secondary
        label.textAlignment = .center
        label.numberOfLines = 0
        actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        actionButton.setTitleColor(SocialPalette.text, for: .normal)
        actionButton.backgroundColor = SocialPalette.brand
        actionButton.layer.cornerRadius = 18
        addSubview(spinner); addSubview(label); addSubview(actionButton)
        spinner.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.bottom.equalTo(label.snp.top).offset(-12) }
        label.snp.makeConstraints { $0.center.equalToSuperview(); $0.leading.greaterThanOrEqualTo(24); $0.trailing.lessThanOrEqualTo(-24) }
        actionButton.snp.makeConstraints { $0.top.equalTo(label.snp.bottom).offset(14); $0.centerX.equalToSuperview(); $0.height.equalTo(36); $0.width.greaterThanOrEqualTo(100) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func showLoading() { spinner.startAnimating(); label.text = "Loading…"; actionButton.isHidden = true }
    func showMessage(_ text: String, retry: Bool) { spinner.stopAnimating(); label.text = text; actionButton.isHidden = !retry; actionButton.setTitle("Retry", for: .normal) }
}

extension UIControl {
    func socialOnTap(_ target: Any?, _ action: Selector) { addTarget(target, action: action, for: .touchUpInside) }
}
